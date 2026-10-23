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
- **UL GTP reaches the UPF N3 counter** (`net1` rx increments) but is **not
  forwarded**: `net2` (N6) tx stays 0, `net2` rx stays 0, `net1` tx (DL GTP)
  stays 0, so the UE sees 100% ping loss in both directions.
- The UPF N3 XDP program is **never invoked** for these frames (its bpftool
  `run_cnt` does not advance), so no SNAT/redirect happens — see root cause.
- An **external** gNB on a different host (e.g. Amarisoft at `10.3.0.5`) over
  the same core/UPF works end to end (N6 rx increments, DL GTP emitted).

### Root cause

This is **not** a UERANSIM/gNB bug, a subscriber-data bug, or an SMF/UPF rule
bug — all control-plane state is correct (N3 F-TEID at `10.3.0.101`, DL FAR
`GTPU_UDP_IPV4:<gnb>`, reverse-SNAT map maps `10.10.0.2 → <ue-ip>`).
**Reproduced with the real Accelleran CU-UP** (not just UERANSIM): moving
`cu-up` onto the UPF node with its N3 macvlan on the same parent
(`enp1s0f0np0`) shows the identical signature below, so the gNB
implementation is irrelevant.

The blocker is in the **ingress path for host-local macvlan traffic under
generic XDP**. Decisive evidence (bpftool prog `run_cnt`, kernel xdp
tracepoints, interface counters):

- `net1` (N3) **rx counter increments** when a colocated gNB sends UL GTP, but
  the N3 XDP program `xdp_handle_uplink` **`run_cnt` does not change** — i.e.
  the XDP hook is **never invoked** for those frames. The N6 TC program
  `tc_redirect_traffic` `run_cnt` likewise does not change, and **all** xdp
  tracepoints (`xdp_redirect`, `xdp_redirect_err`, `xdp_devmap_xmit`,
  `xdp_exception`) stay at **0**.
- Consequently the UPF never SNATs/redirects the packet: `net2` (N6) tx stays
  **0**, nothing egresses to the DN, the DN never replies, and the downlink
  never happens.
- An **external** gNB on a separate host works end to end: its GTP arrives via
  the **physical NIC**, so `xdp_handle_uplink` runs, SNAT/redirect happen, and
  both UL and the DL reply are seen on the N6 wire.

Mechanism: **generic XDP** (`xdpgeneric`, the only mode macvlan/ipvlan virtual
interfaces support) runs at `netif_receive_skb`. When a frame is delivered
**host-locally between two sibling macvlans on the same parent NIC**
(colocated gNB macvlan → UPF N3 macvlan), the macvlan RX forwarding path takes
a shortcut that **bypasses the generic-XDP hook**. The frame bumps the rx
counter but the XDP program never sees it. Externally-received frames go
through the normal path and are processed.

Observed secondary effect: repeated UE off/on churn left **stale BPF session
rows** (`m_session_mappi` / `m_rules_match_p`) with two sessions' DL FAR gNB
addresses **crossed**; a UPF restart flushes this but does not change the
ingress-bypass behavior.

### What does NOT fix it (all tested)

- Moving UERANSIM off `network_mode: host` into a **dedicated netns**
  (`setup-uersim-netns.sh`) — still same parent NIC, same bypass.
- Correcting the N3 neighbor to the UPF `net1` **macvlan MAC** and adding a
  static UPF→gNB neigh on `net1`.
- Priming a static UPF neigh for the N6 gateway (`10.10.0.2`).
- Restarting UPF/SMF to clear stale BPF session state.
- Switching the **N6** NAD from `macvlan` to `ipvlan` L2 and restarting the
  UPF — N6 came up as ipvlan with generic XDP, UL still did not egress.
- Running the **real Accelleran CU-UP** colocated on the UPF node (N3 macvlan
  on the same parent) instead of UERANSIM — identical N3 rx↑ / XDP run_cnt
  flat / N6 tx=0 signature.

### What DOES work — Option C (Linux bridge) fixes the sibling bypass

**Confirmed fix for the macvlan-sibling problem: put the UPF N3 (and N6) on a
Linux bridge instead of macvlan.** A bridge delivers frames to each port via
the normal `netif_receive_skb` path, so the generic-XDP hook on the UPF's
`net1` **does fire** for colocated-gNB uplink — the exact thing macvlan
bypassed.

Lab topology that worked on `.11`:

- `br-n3` (standalone host bridge): UPF `net1` (`10.3.0.101`) and the
  **colocated cu-up** `net1` (`10.3.0.15`) both attached as **veth** ports via
  the `bridge` CNI (NADs `upf-n3-bridge`, `gnb-n3-bridge`).
- `br-n6` (host bridge **enslaving the physical N6 uplink `enp1s0f1np1`** so
  the real DN gateway `10.10.0.2` is reachable): UPF `net2` (`10.10.0.101`)
  attached as a veth (NAD `upf-n6-bridge`); host DN IP `10.10.0.3/24` +
  `192.168.1.203/24` and the UE return routes (`12.1.1.0/24`, `15.1.1.0/24 via
  10.10.0.2`) moved onto `br-n6`.

Evidence the bypass is gone:

- UPF `net1` is now driver `veth` (not macvlan); `xdp_handle_uplink`
  `run_cnt` **advances** on colocated-gNB uplink (observed 0→13, 0→7) — under
  macvlan it stayed flat.
- End-to-end downlink **works** from the colocated Accelleran cu-up: UE
  (`12.1.1.2`) ping to the DN gateway `10.10.0.2` returned replies (e.g. 6/6
  and 9/10) — impossible under macvlan.

Migration gotchas (all hit and solved in the lab):

- A PF cannot be enslaved into a Linux bridge while it still has **macvlan
  children** or **active SR-IOV VFs** (`RTNETLINK ... Device or resource
  busy`). Order: move the UPF `net2` onto the bridge NAD first (removes the
  macvlan child) and set `sriov_numvfs=0` on that PF, *then* enslave the
  physical uplink.
- Do the physical-NIC→bridge migration step-ordered (bridge up + `stp_state
  0`, enslave the live port, then flush/move the L3 addresses and the UE
  return routes) — a naive `set -e` one-shot leaves the bridge `NO-CARRIER`
  and strands the DN uplink.

### Remaining blocker — type-independent "UL forwarding stops ~15 s after setup"

**Correction / important finding:** after clean, *timed* testing the remaining
failure is **NOT** specific to the bridge/veth path or to colocation. It
reproduces **identically on macvlan with an external CU** (standard Amarisoft
topology). Earlier "it works" results were all captured in a brief window
right after session setup; they time out.

Measured behavior (same on macvlan-external and veth-colocated): for the first
~12–15 s after a fresh PDU session the UL works (`net1` rx↑ **and** `net2`
tx↑, ping OK); then the UPF **silently stops forwarding UL N3→N6**:

- `net1` (N3) rx **keeps incrementing** (+3 per 3-ping burst) — the gNB is
  still sending UL GTP and the UPF still receives it.
- `net2` (N6) tx **freezes** — the decapsulated/SNAT'd UL is no longer emitted.
- `net1` clsact `tc_redirect_traffic` `dropped` counter climbs 1:1 with the UL
  packets; `xdp_handle_uplink` returns XDP_PASS (0 redirect events) and the TC
  program returns `TC_ACT_SHOT`.
- No SMF/AMF idle/release/modify events at the cutoff; `m_session_pdrs` still
  holds the UL PDR; interface/ARP maps are correct.

So ~12–15 s into an otherwise-healthy session the UPF datapath stops
redirecting UL even though the session, PDRs and gNB traffic are all still
live. This is a **UPF eBPF datapath bug in the `af-qos-upf:bugbot-master-…`
build** (image `af-qos-upf:bugbot-master-udsf-20261001-nrfbind`), independent
of N3 interface type (macvlan or veth) and of CU colocation. A UPF restart +
fresh session restores it for another ~12–15 s. Needs a fix in the UPF BPF
source (the N3→N6 TC redirect path / whatever time-or-state expiry gates it);
tracked separately from the networking work.

Note: this is distinct from, and sits *on top of*, the macvlan-sibling bypass
fixed by Option C. The bridge fix is still correct and necessary for
colocation; this timeout bug then blocks sustained traffic in **all**
topologies on this build.

### Option A (SR-IOV VF + native XDP) — viable mechanism, blocked here

SR-IOV was also tried. The decisive mechanism check **passed**: two VFs on the
same PF (`enp1s0f0v0`↔`enp1s0f0v1`) ping with 0% loss, i.e. the `ice` embedded
switch (VEB) delivers **same-node VF→VF** frames up the VF driver RX ring —
where XDP runs — so there is no macvlan-style bypass. **But** on this
kernel/driver the VF driver `iavf` **does not support native XDP**
(`libbpf: Underlying driver does not support XDP in native mode`; native XDP
exists on the `ice` PF, not the VF), and VF + generic XDP broke the N3 L2 path
even for the external gNB. So Option A needs native-XDP-capable VFs (or PF
passthrough) plus VF MAC/ARP steering work; left as a future option.

### Also works: external RAN host (unchanged baseline)

Run the gNB on a **separate machine** (external RAN host): its N3/N6 traffic
enters the UPF over the lab switch via a distinct physical host, so the uplink
is not a host-local macvlan sibling — this matches the working Amarisoft
topology and needs no bridge/SR-IOV changes.

**The macvlan-sibling networking problem is SOLVED** (Option C, Linux bridge —
see above). What remains for a *stable* colocated deployment is the separate
UPF BPF session-mapping bug under UE churn. The cleanest production options,
in order: (1) **bridge N3/N6** as above; (2) **native-XDP-capable VFs / PF
passthrough** (Option A mechanism is sound once the driver supports native
XDP); (3) keep the **external RAN host** topology.

#### Quick confirmation that the XDP hook is the culprit

```bash
NS=firecell-core
PID=$(sudo crictl inspect $(sudo crictl ps --name upf -q | head -1) \
      | python3 -c 'import json,sys;print(json.load(sys.stdin)["info"]["pid"])')
UP_ID=$(sudo nsenter -t "$PID" -n ip link show net1 | grep -oE 'prog/xdp id [0-9]+' | grep -oE '[0-9]+')
sudo sh -c 'echo 1 > /proc/sys/kernel/bpf_stats_enabled'
sudo nsenter -t "$PID" -n bpftool prog show id "$UP_ID" | grep run_cnt   # before ping
# ... send UL from the colocated gNB ...
sudo nsenter -t "$PID" -n bpftool prog show id "$UP_ID" | grep run_cnt   # after: unchanged == hook bypassed
```

### Useful diagnostics (per-leg counters settle it fast)

```bash
NS=firecell-core
UPF=$(kubectl -n $NS get pod -l app=oai-upf -o jsonpath='{.items[0].metadata.name}')
for i in net1 net2; do
  echo "$i rx=$(kubectl -n $NS exec $UPF -c upf -- cat /sys/class/net/$i/statistics/rx_packets)" \
       "tx=$(kubectl -n $NS exec $UPF -c upf -- cat /sys/class/net/$i/statistics/tx_packets)"
done
# UL ok  => net1 rx↑ then net2 tx↑ ; DL ok => net2 rx↑ then net1 tx↑
# Colocated-gNB failure signature: net1 rx↑ but XDP run_cnt flat, net2 tx=0, net2 rx=0, net1 tx=0.
```

> Note: the UPF eBPF datapath (`tc_redirect_traffic` + generic XDP) bypasses
> the kernel stack, so `tcpdump` inside the UPF netns sees little/nothing on
> the redirected RX path — rely on the interface counters above, not captures.
