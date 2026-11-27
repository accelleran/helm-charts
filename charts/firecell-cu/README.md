# firecell-cu

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Firecell RAN on Ocudu - O-CU-CP and O-CU-UP with the F1/E1 Service DUs (firecell-du) attach to

## 1. Architectural Role
Deploys the central unit of the Ocudu split gNB: O-CU-CP (`ocucp`) and O-CU-UP (`ocuup`).
DUs are separate [`firecell-du`](../firecell-du) releases, one per DU, that attach to the
CU-CP over F1 through the headless Service `cuCpService.name`.

### 1.1 Components
| Component | Objects | Notes |
|-----------|---------|-------|
| CU-CP | Deployment/ConfigMap `cu-cp`, headless Service `cu-cp` (SCTP F1-C 38472, E1 38462) | N2 towards `amf.addr` |
| CU-UP | Deployment/ConfigMap `cu-up`, NAD `cu-up-n3` | N3 on a macvlan when `cuUp.n3.enabled` |

## 2. Install
```bash
helm install --repo https://accelleran.github.io/helm-charts ran-cu firecell-cu -n oran -f common.yaml -f cu.yaml
helm install --repo https://accelleran.github.io/helm-charts du     firecell-du -n oran -f common.yaml -f du.yaml
helm install --repo https://accelleran.github.io/helm-charts du-2   firecell-du -n oran -f common.yaml -f du-2.yaml
```

From a checkout of this repository, use the chart paths instead: `helm install ran-cu ./charts/firecell-cu ...`.

`common.yaml` holds what the CU and every DU must agree on: `global.image` and `gnb.*`
(gNB-ID, PLMN, TAC, slices). DUs in the same namespace find the CU-CP at
`cu-cp.<namespace>.svc.cluster.local` without further configuration.
Any Ocudu YAML key can be added through `cuCp.extraConfig` and `cuUp.extraConfig`.

### 2.1 NMS Access
With `nms.rbac` (the default), the release grants ServiceAccount `nms` of the [`firecell-nms`](../firecell-nms) release in `nms.namespace` what the NMS needs here:

- RoleBinding `<release>-nms` to the firecell-nms chart's ClusterRole `nms-ran-<nms namespace>`: reads of pods and their logs, ConfigMaps, events, and Deployments, ReplicaSets, StatefulSets and DaemonSets.
- Role and RoleBinding `<release>-nms-lifecycle`: get, patch and update on `deployments` and `deployments/scale` for `cu-cp` and `cu-up`, so the NMS can restart, stop and start them.

The NMS and the CU can be installed in either order: the bindings grant nothing until the NMS's ServiceAccount and ClusterRole exist.

Every install and upgrade also writes ConfigMap `<release>-release-info` (label `firecell.io/release-info: "true"`) in the release namespace, for the NMS support bundles and drift checks, since the NMS reads no Helm release Secret. `release.json` holds the release, namespace, chart (`<name>-<version>`), appVersion, revision, render time (`renderedAt`, UTC), a SHA-256 digest of the values (`valuesDigest`) and the image of every container the chart renders (`images`, keyed `<workload>/<container>`, taken from the rendered pods themselves). `history.json` keeps up to 20 earlier `release.json` records, newest first, read back from the live ConfigMap with `lookup`; it starts empty after `helm template` or a client-side dry run. Neither holds any values content or anything from a Secret. `helm rollback` reapplies the stored manifest of the target revision, so the record and its history roll back with it.

### 2.2 O1 NETCONF Login
With `cuCp.o1.enabled` and `cuUp.o1.enabled`, each of the CU-CP and the CU-UP takes its NETCONF login from a Secret mounted read-only at `/etc/ocudu/o1-netconf` (an RC3 or later image; an older image ignores it). The values below are the CU-CP's; the CU-UP has the same under `cuUp.o1.netconf`, with Secret `cu-up-o1-netconf`.

| Setup | Values | Login |
|-------|--------|-------|
| None (default) | nothing | Lab login `netconf`/`netconf` in group `operator`, with a start-up WARNING |
| One Secret per RAN namespace (recommended) | `cuCp.o1.netconf.existingSecret: <secret>` | User and password from the Secret (keys `username`, `password`); the lab login is removed |
| Chart-made Secret | `cuCp.o1.netconf.password` and/or `cuCp.o1.netconf.authorizedKeys`, optional `cuCp.o1.netconf.username` | As above, from Secret `cu-cp-o1-netconf` |

- The Secret is mounted with `optional: true`: a deleted Secret does not stop the pod, only NETCONF. The chart sets `O1_REQUIRE_SECRET=true` whenever it mounts a Secret, so a lost Secret keeps NETCONF off instead of bringing the lab login back.
- The element reads the Secret at start only. A chart-made Secret rolls the pod when its values change; after changing an `existingSecret`, restart the pod in a maintenance window.
- An element that has used a Secret keeps NETCONF off when the Secret is dropped from the values. That mark lives in the element's node folder only: a lost folder, or a pod moved to another node, loses it. To drop a Secret, always set `cuCp.o1.netconf.requireSecret: false` and remove the Secret values.
- The NMS needs the same user and password (firecell-nms `backend.extraEnv`); restart its backend pods after a change.
- The O1 state (NETCONF host key, O1 overlay, the mark that a Secret was used) lives in a host directory (`o1.statePath`) on the node the pod runs on. The CU-CP and CU-UP are not tied to a node by hardware: pin each to one node (`nodeSelector` with `kubernetes.io/hostname`), or give it storage that moves with it (`o1.stateClaim`, an existing PersistentVolumeClaim). Otherwise a move to another node gives it a new host key (the NMS refuses it until re-pinned) and loses its O1 overlay and that mark. The install notes warn when neither is set.
- `cuCp.o1.netconf.group` (`O1_NETCONF_GROUP`) and `cuCp.o1.netconf.nacm` (`O1_NACM_ENABLED`) are passed only when set.
- NETCONF listens on the pod IP (`NETCONF_LISTEN_ADDRESS`), not on every address, so it is not reachable on the Multus interfaces, which a NetworkPolicy does not filter. The NMS reaches it through the Service as before. `cuCp.o1.netconf.listenAddress` overrides it (`0.0.0.0`: all addresses, the image default). `kubectl port-forward` to port 830 no longer works, since it connects to the pod's localhost.

## 3. Node prerequisites
- Multus with the macvlan and static IPAM plugins when `cuUp.n3.enabled`.
- SCTP enabled in the cluster (F1-C, E1, N2).

## 4. Configuration Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| amf.addr | string | `"oai-amf-n2.firecell-core.svc.cluster.local"` | AMF N2 address. With firecell-core this is the headless oai-amf-n2 Service. |
| amf.port | int | `38412` | AMF NGAP SCTP port. |
| amf.procedureTimeoutMs | int | `15000` | NGAP procedure timeout (ms). |
| cuCp.cpus | string | `""` | CPU list for taskset. Empty runs unpinned. |
| cuCp.enabled | bool | `true` | Deploy CU-CP and its headless F1/E1 Service. |
| cuCp.extraConfig | object | `{"log":{"all_level":"warning","cu_level":"info","e1ap_level":"warning","f1ap_level":"info","filename":"stdout","hex_max_size":0,"ngap_level":"info","pdcp_level":"warning","rrc_level":"info"},"metrics":{"enable_log":false},"o2":{"bind_addr":"0.0.0.0","enabled":true,"port":9093},"pcap":{"e1ap_enable":false,"e1ap_filename":"/tmp/logs/cu_cp_e1ap.pcap","f1ap_enable":false,"f1ap_filename":"/tmp/logs/cu_cp_f1ap.pcap","ngap_enable":false,"ngap_filename":"/tmp/logs/cu_cp_ngap.pcap"}}` | Raw Ocudu cu_cp YAML merged over the generated config (wins on conflict). |
| cuCp.image | string | `""` | Image override (defaults to global.image). |
| cuCp.nodeSelector | object | `{}` | nodeSelector override (defaults to global.nodeSelector). |
| cuCp.o1 | object | `{"enabled":false,"netconf":{"authorizedKeys":"","existingSecret":"","group":"","listenAddress":"","nacm":null,"password":"","requireSecret":null,"username":""},"netconfVerbosity":"warning","restartOnColdCommit":false,"stateClaim":"","statePath":"","ueContext":{"enabled":true,"maxUes":256,"measReport":{"intervalMs":1024,"sectorIds":[]}},"yangSearchPath":"/usr/local/yang"}` | NETCONF (netopeer2) so the NMS can read /ocudu-performance ue-context. |
| cuCp.o1.netconf.authorizedKeys | string | `""` | NMS public keys (OpenSSH, ed25519 or ECDSA) of a chart-made Secret cu-cp-o1-netconf: one string with one key per line, or a list. With a password too, only the keys are used. |
| cuCp.o1.netconf.existingSecret | string | `""` | Existing Secret mounted at /etc/ocudu/o1-netconf (keys username, password and/or authorized_keys). Recommended: one Secret per RAN namespace, named by every element. The CU-CP reads it at start only: restart it after changing the Secret. |
| cuCp.o1.netconf.group | string | `""` | NACM group of the Secret's user (O1_NETCONF_GROUP): admin, operator or read-only. Empty: the image default, operator. |
| cuCp.o1.netconf.listenAddress | string | `""` | Address NETCONF listens on (NETCONF_LISTEN_ADDRESS, an IPv4 or IPv6 literal). Empty: the pod IP, so NETCONF is not open on the Multus interfaces (CU-UP N3 and F1-U), which a NetworkPolicy does not filter; the NMS reaches it through the Service. 0.0.0.0 restores the image default (all addresses). |
| cuCp.o1.netconf.nacm | bool | `nil` | Access control (O1_NACM_ENABLED). Unset: the image default, true. false turns NACM off, as in RC2. |
| cuCp.o1.netconf.password | string | `""` | Password of a chart-made Secret cu-cp-o1-netconf (clear text on one line, at most 256 characters, or a $6$/$5$ crypt hash). The pod rolls when it changes. |
| cuCp.o1.netconf.requireSecret | bool | `nil` | O1_REQUIRE_SECRET. The chart sets true whenever it mounts a Secret, so a lost Secret keeps NETCONF off. Without a Secret: unset leaves it out (an element that used a Secret before still keeps NETCONF off); true keeps NETCONF off; false is the deliberate way back to the lab login: set it when dropping a Secret, since the element's mark that a Secret was used lives in its node folder only. false is refused while a Secret is mounted. |
| cuCp.o1.netconf.username | string | `""` | User (letters, digits, . _ -, at most 64 characters, not root) of a chart-made Secret cu-cp-o1-netconf. Empty: netconf. |
| cuCp.o1.netconfVerbosity | string | `"warning"` | netopeer2 log level: error, warning, info (a few [INF] lines per NMS request) or debug; 0-3 also accepted. Images built before the entrypoint read NETCONF_VERBOSITY always log at info. |
| cuCp.o1.stateClaim | string | `""` | Existing PersistentVolumeClaim for the O1 state (O1 overlay, NETCONF host key, mode file) instead of the statePath host directory, so the state moves with the pod when it is rescheduled to another node. Empty: the host directory; then pin the CU-CP to one node (nodeSelector kubernetes.io/hostname), or a move to another node gives it a new host key and loses its O1 overlay. |
| cuCp.o1.statePath | string | `""` | Host directory kept across restarts (O1 overlay and NETCONF host key). Give each CU-CP on a node its own. Empty uses /var/lib/firecell/ocudu/cu-cp. |
| cuCp.o1.ueContext.enabled | bool | `true` | Publish per-UE identity (/ocudu-performance ue-context) for the NMS UE dashboard. Needs cuCp.o1.enabled. Turns on CU-CP RRC metrics (metrics.layers.enable_rrc), without which the list stays empty. |
| cuCp.o1.ueContext.maxUes | int | `256` | Maximum published UE entries. |
| cuCp.o1.ueContext.measReport.intervalMs | int | `1024` | Report interval in ms (120, 240, 480, 640, 1024 or 2048). Must stay below ocudu's ue_meas_max_age_ms (3000), or every report is dropped as stale. |
| cuCp.o1.ueContext.measReport.sectorIds | list | `[]` | cell.sectorId of every DU cell on this CU-CP. Each gets a periodic serving-cell measurement report so ue-context carries RSRP/RSRQ/SINR. Empty sends no reports (the three panels stay empty). NCI = gnb.gnbId << (36 - gnb.gnbIdBitLength) | sectorId. |
| cuCp.requestPduSessionTimeout | int | `15` | Seconds the CU-CP waits for PDU session setup before releasing the UE. |
| cuCp.resources | object | `{}` |  |
| cuCp.tolerations | list | `[]` | Tolerations override (defaults to global.tolerations). |
| cuCpService.name | string | `"cu-cp"` | Service name. firecell-du defaults its cuCpAddress to cu-cp.<namespace>. |
| cuUp.cpus | string | `""` | CPU list for taskset. Empty runs unpinned. |
| cuUp.cuCpAddress | string | `""` | E1 target. Empty resolves to <cuCpService.name>.<namespace>.svc.cluster.local. |
| cuUp.enabled | bool | `true` | Deploy CU-UP. |
| cuUp.extraConfig | object | `{"cu_up":{"ngu":{"gtpu":{"ignore_ue_ambr":true}},"warn_on_drop":true},"log":{"all_level":"warning","filename":"stdout","hex_max_size":0},"metrics":{"enable_log":false},"o2":{"bind_addr":"0.0.0.0","enabled":true,"port":9094},"pcap":{"e1ap_enable":false,"f1u_enable":false,"n3_enable":false}}` | Raw Ocudu cu_up YAML merged over the generated config. |
| cuUp.f1u.network.cidr | string | `""` | CU-UP F1-U address with prefix. The IP part is the F1-U bind address. |
| cuUp.f1u.network.enabled | bool | `false` | Put F1-U (GTP-U toward the DUs) on a macvlan of a host NIC instead of the pod network. Use when the DUs run on another node and the pod network between the nodes is slower than the user plane. |
| cuUp.f1u.network.master | string | `""` | Host interface the F1-U macvlan sits on (link toward the DU node). |
| cuUp.image | string | `""` |  |
| cuUp.n3.cidr | string | `"10.3.0.4/24"` | Static N3 address with prefix. The IP part is the NG-U bind address. |
| cuUp.n3.cniType | string | `"macvlan"` | macvlan (CU-UP on a different node than the UPF) or bridge (CU-UP on the UPF node with the UPF on a Linux bridge and generic XDP; macvlan siblings bypass generic XDP). |
| cuUp.n3.enabled | bool | `true` | Attach a secondary interface for N3. When false, N3 binds the pod IP. |
| cuUp.n3.mac | string | `""` | Fixed MAC for the N3 interface (keeps the UPF neighbour entry valid). Empty lets CNI pick. |
| cuUp.n3.master | string | `"eth1"` | Host parent interface (macvlan) or Linux bridge name (bridge, e.g. br-n3). |
| cuUp.nodeSelector | object | `{}` |  |
| cuUp.nofThreads | int | `3` | CU-UP main pool worker threads (expert_execution.threads.main_pool.nof_threads). |
| cuUp.o1.enabled | bool | `false` | NETCONF (netopeer2) on the CU-UP, so the NMS registers and manages it over O1. Needs an image whose ocuup carries the O1 service; renders Service cu-up:830. |
| cuUp.o1.netconf.authorizedKeys | string | `""` | NMS public keys (OpenSSH, ed25519 or ECDSA) of a chart-made Secret cu-up-o1-netconf: one string with one key per line, or a list. With a password too, only the keys are used. |
| cuUp.o1.netconf.existingSecret | string | `""` | Existing Secret mounted at /etc/ocudu/o1-netconf (keys username, password and/or authorized_keys). Recommended: one Secret per RAN namespace, named by every element. The CU-UP reads it at start only: restart it after changing the Secret. |
| cuUp.o1.netconf.group | string | `""` | NACM group of the Secret's user (O1_NETCONF_GROUP): admin, operator or read-only. Empty: the image default, operator. |
| cuUp.o1.netconf.listenAddress | string | `""` | Address NETCONF listens on (NETCONF_LISTEN_ADDRESS, an IPv4 or IPv6 literal). Empty: the pod IP, so NETCONF is not open on the Multus interfaces (CU-UP N3 and F1-U), which a NetworkPolicy does not filter; the NMS reaches it through the Service. 0.0.0.0 restores the image default (all addresses). |
| cuUp.o1.netconf.nacm | bool | `nil` | Access control (O1_NACM_ENABLED). Unset: the image default, true. false turns NACM off, as in RC2. |
| cuUp.o1.netconf.password | string | `""` | Password of a chart-made Secret cu-up-o1-netconf (clear text on one line, at most 256 characters, or a $6$/$5$ crypt hash). The pod rolls when it changes. |
| cuUp.o1.netconf.requireSecret | bool | `nil` | O1_REQUIRE_SECRET. The chart sets true whenever it mounts a Secret, so a lost Secret keeps NETCONF off. Without a Secret: unset leaves it out (an element that used a Secret before still keeps NETCONF off); true keeps NETCONF off; false is the deliberate way back to the lab login: set it when dropping a Secret, since the element's mark that a Secret was used lives in its node folder only. false is refused while a Secret is mounted. |
| cuUp.o1.netconf.username | string | `""` | User (letters, digits, . _ -, at most 64 characters, not root) of a chart-made Secret cu-up-o1-netconf. Empty: netconf. |
| cuUp.o1.netconfVerbosity | string | `"warning"` | netopeer2 log level: error, warning, info (a few [INF] lines per NMS request) or debug; 0-3 also accepted. Images built before the entrypoint read NETCONF_VERBOSITY always log at info. |
| cuUp.o1.restartOnColdCommit | bool | `false` |  |
| cuUp.o1.stateClaim | string | `""` | Existing PersistentVolumeClaim for the O1 state (O1 overlay, NETCONF host key, mode file) instead of the statePath host directory, so the state moves with the pod when it is rescheduled to another node. Empty: the host directory; then pin the CU-UP to one node (nodeSelector kubernetes.io/hostname), or a move to another node gives it a new host key and loses its O1 overlay. |
| cuUp.o1.statePath | string | `""` | Host directory kept across restarts (O1 overlay and NETCONF host key). Give each CU-UP on a node its own. Empty uses /var/lib/firecell/ocudu/cu-up. |
| cuUp.o1.yangSearchPath | string | `"/usr/local/yang"` |  |
| cuUp.resources | object | `{}` |  |
| cuUp.rpsCpus | string | `""` | RPS CPU mask, quoted hex as in /sys/class/net/*/queues/rx-*/rps_cpus (e.g. "3c003c" = CPUs 2-5,18-21), set on the N3 veth at start. Needs n3.cniType bridge (CU-UP next to a generic-XDP UPF); RPS has no effect on macvlan (F1-U, macvlan N3), whose receive runs in the parent NIC's softirq: pin that NIC's IRQs on the host. Use the host's NIC IRQ cores. Empty leaves RPS off. |
| cuUp.tolerations | list | `[]` |  |
| global.image | string | `"docker.io/accelleran/ran:0.1.0"` | Ocudu runtime image. Components may override it. |
| global.imagePullPolicy | string | `"IfNotPresent"` | Pull policy for the Ocudu image. Use Never for images imported into containerd. |
| global.imagePullSecrets | list | `[]` | Image pull secrets for every pod. |
| global.namespace | string | `""` | Namespace for every object. Empty uses the release namespace. |
| global.nodeSelector | object | `{}` | Default nodeSelector for every pod. Components may override it. |
| global.tolerations | list | `[]` | Default tolerations for every pod. Components may override them. |
| gnb.gnbId | int | `1` | gNB-ID. |
| gnb.gnbIdBitLength | int | `22` | gNB-ID length in bits. |
| gnb.plmn | string | `"00101"` | Serving PLMN (MCC+MNC). |
| gnb.slices | list | `[{"schedCfg":{"max_prb_policy_ratio":100,"min_prb_policy_ratio":15,"priority":10},"sd":1,"sst":1}]` | Slices. sst/sd go to the CU-CP TAI slice list (schedCfg is only read by firecell-du). |
| gnb.tac | int | `1` | Tracking area code. |
| nms.namespace | string | `"firecell-nms"` | Namespace of the firecell-nms release. |
| nms.rbac | bool | `true` | Let the NMS read pods here, and restart, stop and start the cu-cp and cu-up Deployments. |

## 5. Maintenance & Troubleshooting
- CU-CP and CU-UP log to stdout (`log.filename: stdout` in `cuCp.extraConfig` and `cuUp.extraConfig`): read them with `kubectl logs deploy/cu-cp -c ocucp` and `kubectl logs deploy/cu-up -c ocuup`, and the node's log store (the [`logs` stage of the Firecell platform](https://github.com/accelleran/galaxy/tree/fcdevelop/firecell-6-flux/recipe/logs)) keeps them across restarts. Set `filename` to a path under `/tmp/logs` to log to a file again; that directory is an emptyDir, emptied with the pod, and still holds the pcaps.
- If CU-CP and CU-UP restart together, CU-UP can time out on its first E1 connect and restart once. That restart is expected.
- CU-UP starts `min(cuUp.nofThreads, len(cuUp.cpus) - 3)` pool workers, so a 4-CPU `cuUp.cpus` gives one worker. Give it at least `nofThreads + 3` CPUs.
- Restarting CU-CP drops every DU's F1 association; the DUs reconnect on their own.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
