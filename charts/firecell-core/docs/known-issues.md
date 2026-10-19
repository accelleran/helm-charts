# firecell-core — Known Issues & Lab Runbooks

## KI-1: Multus UPF — SMF advertises the UPF pod IP as the N3 F-TEID (UL/DL dropped)

**Applies to:** OAI UPF with `upf.hostNetwork=false` + `upf.multus.enabled=true`
(Multus macvlan N3/N6), NRF registration on (`coreConfig.registerNf: "yes"`).

### Symptom

- PDU session establishes and the UE gets its PAA IPv4, but **uplink/downlink
  user traffic is dropped** — ping from the UE to the N6 gateway / Internet
  fails (100% loss) even though NGAP, PFCP association and the session all
  look healthy.
- SMF logs the tell-tale line:

  ```
  [smf_app] [warning] The UPF <POD_IP> does not support F-TEID creation, but
  you did not configure the N3 host IP. We will try with the UPF hostname
  [smf_app] [info]     UL F-TEID 0x.. allocated for N3 IPv4 Addr : <POD_IP>
  ```

  i.e. the N3 GTP-U F-TEID is bound to the UPF **Cilium pod IP**
  (`10.42.x.y`) instead of the Multus N3 macvlan IP (e.g. `10.3.0.101`), so
  the gNB's GTP-U never reaches the UPF datapath.

### Root cause

Two UPF-selection paths coexist and disagree:

1. **Static entry** — `smf.upfs[].host: oai-upf` carries
   `config.n3_local_ipv4: <N3 IP>` (templated from `upf.n3IP`). SMF resolves
   `oai-upf` by DNS once at association time.
2. **NRF discovery** — because `register_nf: general: yes` (global, required
   by the rest of the core), the OAI UPF also registers in NRF **under its
   ephemeral pod IP**, and the UPF-status subscription creates a *second*
   PFCP association keyed on that pod IP.

`pfcp_associations::get_upf_config()` matches the static `upfs[]` entry to an
association by **exact node_id equality**. When the session is served by the
NRF-discovered (pod-IP) node, the static hostname entry does not match, SMF
falls back to an **empty UPF profile with no `n3_local_ipv4`**, and allocates
the N3 F-TEID at the pod IP. The mismatch also resurfaces after any UPF
restart (pod IP changes; the once-resolved static node_id goes stale).

The OAI UPF additionally does **not** advertise FTUP (UP Function Features),
so the SMF must allocate the N3 F-TEID itself — which is precisely why a
correct `n3_local_ipv4` is mandatory.

### Durable fix (upstream)

This is a `cn5g-smf` code fix, **not** a chart/values change: in
`get_upf_config()`, when a static `upfs[]` entry exists, match the
NRF-discovered node to it by re-resolving the hostname (and/or inherit
`n3_local_ipv4` onto the discovered UPF profile) so the N3 IP is applied
regardless of whether the association is hostname- or pod-IP-keyed.

Do **not** commit the ephemeral pod IP into chart values — it breaks on the
next UPF pod recreate.

### Lab workaround (runtime, re-apply after every UPF restart)

Add a second `upfs[]` entry keyed on the UPF's **current** pod IP, carrying
the correct N3 IP, then restart the SMF:

```bash
NS=firecell-core
UPF_IP=$(kubectl -n $NS get pod -l app=oai-upf \
  -o jsonpath='{.items[0].status.podIP}')
N3_IP=10.3.0.101   # = upf.n3IP / Multus N3 macvlan address

# Patch the embedded OAI config (both config keys) with a pod-IP-keyed entry:
#   - host: <UPF_IP>
#     port: 8805
#     config:
#       enable_upf_wo_nf_discovery: yes
#       enable_usage_reporting: no
#       enable_dl_pdr_in_pfcp_session_establishment: yes
#       n3_local_ipv4: <N3_IP>
# (insert after the existing "n3_local_ipv4: <N3_IP>" line under smf.upfs)

kubectl -n $NS get cm firecell-common-config -o yaml > /tmp/cm.yaml
# ...edit /tmp/cm.yaml as above (strip managedFields/resourceVersion/uid)...
kubectl -n $NS apply -f /tmp/cm.yaml
kubectl -n $NS delete pod -l app=oai-smf          # reload config
kubectl -n $NS rollout status deploy/oai-smf
```

Verify the fix took: SMF should log the N3 F-TEID at the **N3 IP**, not the
pod IP:

```
[smf_app] [info]     UL F-TEID 0x.. allocated for N3 IPv4 Addr : 10.3.0.101
```

Then re-attach the UE (power off/on) and ping the N6 gateway.

> **Reminder:** the pod IP is ephemeral. This workaround must be re-applied
> after any UPF pod recreate until the upstream SMF fix lands.

---

## KI-2: Colocated UERANSIM on the UPF host — downlink user-plane not delivered (macvlan same-parent isolation)

**Applies to:** running a UERANSIM gNB+UE **on the same node as the Multus UPF**
(`192.168.30.11`), against `upf.hostNetwork=false` + `upf.multus.enabled=true`
(macvlan N3 on `enp1s0f0np0`, N6 on `enp1s0f1np1`), eBPF datapath
(`enable_bpf_datapath: yes`, `enable_snat: yes`).

### Symptom

- NG Setup, Registration and PDU session all succeed; `uesimtun0` gets its
  PAA IPv4 (e.g. `12.1.1.5`).
- **Uplink works**: UE → gNB → UPF N3 (`net1` rx increments) → UPF SNATs to
  the N6 macvlan IP (`10.10.0.101`) → N6 (`net2`) tx increments. Verified on
  the wire: `10.10.0.101 > 10.10.0.2 ICMP echo request`.
- **Downlink fails**: the external N6 gateway's reply never gets delivered
  back through the UPF — `net2` rx stays 0 and `net1` tx (DL GTP) stays 0, so
  `uesimtun0` rx = 0 (100% ping loss).
- An **external** gNB on a different host (e.g. Amarisoft at `10.3.0.5`) over
  the same core/UPF works end to end (N6 rx increments, DL GTP emitted).

### Root cause

This is **not** a UERANSIM config bug, a subscriber-data bug, or SMF/UPF rule
bug — all control-plane state is correct (N3 F-TEID at `10.3.0.101`, DL FAR
`GTPU_UDP_IPV4:10.3.0.12`, reverse-SNAT map maps `10.10.0.2 → 12.1.1.5`). The
blocker is in the **UPF generic-XDP datapath** for a UL frame that ingressed
from a **same-host interface**:

- Captured on the physical N6 parent (`enp1s0f1np1`), an **external** gNB
  (Amarisoft) produces both directions:
  `10.10.0.101 > 10.10.0.2 echo request` **and** `10.10.0.2 > 10.10.0.101
  echo reply` — works end to end.
- A **colocated** UERANSIM session produces **nothing on the wire**: the UPF
  `net2` tx *counter* increments (the BPF `XDP_REDIRECT` is counted) but the
  SNAT'd UL frame **never physically egresses** the NIC, so the gateway never
  sees it and never replies (host-side capture of `src 10.10.0.2` is empty).
  There are no `tx_dropped` / `tx_errors` on `net2` — the redirect is
  silently not transmitted.

The distinguishing factor is the **ingress** of the uplink: Amarisoft's UL
arrives on N3 from an external source; UERANSIM's UL arrives on N3 from a
**same-host macvlan sibling** on the shared parent. Generic XDP
(`xdpgeneric`, the only mode these macvlan/ipvlan virtual interfaces support)
does not reliably transmit a redirected frame whose path is entirely
host-local across the shared parent NIC.

Observed secondary effect: repeated UE off/on churn left **stale BPF session
rows** in the UPF datapath (`m_session_mappi` / `m_rules_match_p`), and two
sessions' DL FAR gNB addresses appeared **crossed** (UERANSIM's DL pointing at
the other gNB's IP/TEID). A UPF pod restart flushes this; the underlying
transmit problem remains.

### What does NOT fix it (all tested)

- Moving UERANSIM off `network_mode: host` into a **dedicated netns**
  (`setup-uersim-netns.sh`) — still same parent NIC, same datapath behavior.
- Correcting the N3 neighbor to the UPF `net1` **macvlan MAC** (fixes uplink
  ingress to the UPF only) and adding a static UPF→gNB neigh on `net1`.
- Priming a static UPF neigh for the N6 gateway (`10.10.0.2`).
- Restarting UPF/SMF to clear stale BPF session state.
- **Switching the N6 NAD from `macvlan` to `ipvlan` L2** and restarting the
  UPF — N6 came up as ipvlan (generic XDP still attached) but the UL frame
  still did not egress the wire (N6 rx stayed 0). ipvlan does not change the
  generic-XDP same-host transmit behavior.

### What DOES work (and current status)

Run the UERANSIM gNB on a **separate machine** (external RAN host), exactly as
`scripts/ueransim-docker/README.md` prescribes (external host → core
`192.168.30.11`). Its N3/N6 traffic then enters the UPF over the lab switch
via a distinct physical host, so the uplink is not a host-local XDP redirect —
this matches the working Amarisoft topology.

**True host colocation on `.11` is still UNSOLVED.** macvlan→ipvlan did not
help; the remaining candidate is **native XDP** (proper redirect semantics)
instead of generic, but macvlan/ipvlan virtual interfaces generally do not
support native XDP, which is why the UPF runs generic here. A real fix likely
requires either a dedicated physical NIC for N3/N6 (so UL ingress and N6
egress are not host-local on the same parent) or a UPF-datapath change in how
the UL frame is transmitted after redirect. Left open.

### Useful diagnostics (per-leg counters settle it fast)

```bash
NS=firecell-core
UPF=$(kubectl -n $NS get pod -l app=oai-upf -o jsonpath='{.items[0].metadata.name}')
for i in net1 net2; do
  echo "$i rx=$(kubectl -n $NS exec $UPF -c upf -- cat /sys/class/net/$i/statistics/rx_packets)" \
       "tx=$(kubectl -n $NS exec $UPF -c upf -- cat /sys/class/net/$i/statistics/tx_packets)"
done
# UL ok  => net1 rx↑ then net2 tx↑ ; DL ok => net2 rx↑ then net1 tx↑
# Colocated-UERANSIM failure signature: net1 rx↑, net2 tx↑, net2 rx=0, net1 tx=0.
```

> Note: the UPF eBPF datapath (`tc_redirect_traffic` + generic XDP) bypasses
> the kernel stack, so `tcpdump` inside the UPF netns sees little/nothing on
> the redirected RX path — rely on the interface counters above, not captures.
