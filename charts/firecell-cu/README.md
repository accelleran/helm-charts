# firecell-cu

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

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

- RoleBinding `<release>-nms` to the firecell-nms chart's ClusterRole `nms-ran-<nms namespace>`: pod reads.
- Role and RoleBinding `<release>-nms-lifecycle`: get, patch and update on `deployments` and `deployments/scale` for `cu-cp` and `cu-up`, so the NMS can restart, stop and start them.

The NMS and the CU can be installed in either order: the bindings grant nothing until the NMS's ServiceAccount and ClusterRole exist.

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
| cuCp.extraConfig | object | `{"log":{"all_level":"warning","cu_level":"info","e1ap_level":"warning","f1ap_level":"info","filename":"/tmp/logs/ocudu_cu_cp.log","hex_max_size":0,"ngap_level":"info","pdcp_level":"warning","rrc_level":"info"},"metrics":{"enable_log":false},"o2":{"bind_addr":"0.0.0.0","enabled":true,"port":9093},"pcap":{"e1ap_enable":false,"e1ap_filename":"/tmp/logs/cu_cp_e1ap.pcap","f1ap_enable":false,"f1ap_filename":"/tmp/logs/cu_cp_f1ap.pcap","ngap_enable":false,"ngap_filename":"/tmp/logs/cu_cp_ngap.pcap"}}` | Raw Ocudu cu_cp YAML merged over the generated config (wins on conflict). |
| cuCp.image | string | `""` | Image override (defaults to global.image). |
| cuCp.nodeSelector | object | `{}` | nodeSelector override (defaults to global.nodeSelector). |
| cuCp.o1.enabled | bool | `false` | NETCONF (netopeer2) so the NMS can read /ocudu-performance ue-context. |
| cuCp.o1.restartOnColdCommit | bool | `false` |  |
| cuCp.o1.statePath | string | `""` | Host directory kept across restarts (O1 overlay and NETCONF host key). Give each CU-CP on a node its own. Empty uses /var/lib/firecell/ocudu/cu-cp. |
| cuCp.o1.ueContext.enabled | bool | `true` | Publish per-UE identity (/ocudu-performance ue-context) for the NMS UE dashboard. Needs cuCp.o1.enabled. Turns on CU-CP RRC metrics (metrics.layers.enable_rrc), without which the list stays empty. |
| cuCp.o1.ueContext.maxUes | int | `256` | Maximum published UE entries. |
| cuCp.o1.ueContext.measReport.intervalMs | int | `1024` | Report interval in ms (120, 240, 480, 640, 1024 or 2048). Must stay below ocudu's ue_meas_max_age_ms (3000), or every report is dropped as stale. |
| cuCp.o1.ueContext.measReport.sectorIds | list | `[]` | cell.sectorId of every DU cell on this CU-CP. Each gets a periodic serving-cell measurement report so ue-context carries RSRP/RSRQ/SINR. Empty sends no reports (the three panels stay empty). NCI = gnb.gnbId << (36 - gnb.gnbIdBitLength) \| sectorId. |
| cuCp.o1.yangSearchPath | string | `"/usr/local/yang"` |  |
| cuCp.requestPduSessionTimeout | int | `15` | Seconds the CU-CP waits for PDU session setup before releasing the UE. |
| cuCp.resources | object | `{}` |  |
| cuCp.tolerations | list | `[]` | Tolerations override (defaults to global.tolerations). |
| cuCpService.name | string | `"cu-cp"` | Service name. firecell-du defaults its cuCpAddress to cu-cp.<namespace>. |
| cuUp.cpus | string | `""` | CPU list for taskset. Empty runs unpinned. |
| cuUp.cuCpAddress | string | `""` | E1 target. Empty resolves to <cuCpService.name>.<namespace>.svc.cluster.local. |
| cuUp.enabled | bool | `true` | Deploy CU-UP. |
| cuUp.extraConfig | object | `{"cu_up":{"ngu":{"gtpu":{"ignore_ue_ambr":true}},"warn_on_drop":true},"log":{"all_level":"warning","filename":"/tmp/logs/ocudu_cu_up.log","hex_max_size":0},"metrics":{"enable_log":false},"o2":{"bind_addr":"0.0.0.0","enabled":true,"port":9094},"pcap":{"e1ap_enable":false,"f1u_enable":false,"n3_enable":false}}` | Raw Ocudu cu_up YAML merged over the generated config. |
| cuUp.f1u.network.cidr | string | `""` | CU-UP F1-U address with prefix. The IP part is the F1-U bind address. |
| cuUp.f1u.network.enabled | bool | `false` | Put F1-U (GTP-U toward the DUs) on a macvlan of a host NIC instead of the pod network. Use when the DUs run on another node and the pod network between the nodes is slower than the user plane. |
| cuUp.f1u.network.master | string | `""` | Host interface the F1-U macvlan sits on (link toward the DU node). |
| cuUp.image | string | `""` |  |
| cuUp.n3.cidr | string | `"10.3.0.4/24"` | Static N3 address with prefix. The IP part is the NG-U bind address. |
| cuUp.n3.cniType | string | `"macvlan"` | macvlan (CU-UP on a different node than the UPF) or bridge (CU-UP on the UPF node with the UPF on a Linux bridge and generic XDP; macvlan siblings bypass generic XDP). |
| cuUp.n3.enabled | bool | `true` | Attach a macvlan for N3. When false, N3 binds the pod IP. |
| cuUp.n3.mac | string | `""` | Fixed MAC for the N3 macvlan (keeps the UPF neighbour entry valid). Empty lets CNI pick. |
| cuUp.n3.master | string | `"eth1"` | Host parent interface (macvlan) or Linux bridge name (bridge, e.g. br-n3). |
| cuUp.nodeSelector | object | `{}` |  |
| cuUp.nofThreads | int | `3` | CU-UP main pool worker threads (expert_execution.threads.main_pool.nof_threads). |
| cuUp.rpsCpus | string | `""` | RPS CPU mask, quoted hex as in /sys/class/net/*/queues/rx-*/rps_cpus (e.g. "3c003c" = CPUs 2-5,18-21), set on the N3 veth at start. Needs n3.cniType bridge (CU-UP next to a generic-XDP UPF); RPS has no effect on macvlan (F1-U, macvlan N3), whose receive runs in the parent NIC's softirq: pin that NIC's IRQs on the host. Use the host's NIC IRQ cores. Empty leaves RPS off. |
| cuUp.resources | object | `{}` |  |
| cuUp.tolerations | list | `[]` |  |
| global.image | string | `"ghcr.io/accelleran/ocudu:edge"` | Ocudu runtime image. Components may override it. Defaults to the firecell-dev CI build (acc_ocudu release-image.yml); GHCR is private, so set imagePullSecrets. edge moves on every merge: pin edge-<sha> for a fixed build. |
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
- If CU-CP and CU-UP restart together, CU-UP can time out on its first E1 connect and restart once. That restart is expected.
- CU-UP starts `min(cuUp.nofThreads, len(cuUp.cpus) - 3)` pool workers, so a 4-CPU `cuUp.cpus` gives one worker. Give it at least `nofThreads + 3` CPUs.
- Restarting CU-CP drops every DU's F1 association; the DUs reconnect on their own.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
