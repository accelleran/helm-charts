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
