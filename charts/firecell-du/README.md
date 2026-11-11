# firecell-du

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Firecell RAN on Ocudu - one O-RAN 7.2 O-DU per release, with DPDK fronthaul, O-RU M-plane and O1 NETCONF

## 1. Architectural Role
Deploys one Ocudu O-DU driving one radio unit, with an optional O1 NETCONF server for the NMS.
Install one release per DU; each attaches over F1 to the CU-CP of a [`firecell-cu`](../firecell-cu) release.

| `ru.split` / `ru.vendor` | Radio | DU | Fronthaul |
|-----------|-------|----|-----------|
| `"7.2"` / `benetel`, `comba`, `eridan` (default) | O-RAN 7.2x O-RU, optional M-plane (NETCONF call-home) | `odu_split_7_2` | `ofh.mode: dpdk`: SR-IOV VF on vfio-pci + hugepages |
| `"7.2"`, lab | Amarisoft UE simulator acting as the O-RU on the same node | `odu_split_7_2` | `ofh.mode: socket`: kernel raw socket on a host netdev (e.g. a veth) that Multus `host-device` moves into the pod |
| `"8"` / `aw2s` | AW2S Swallow RRH over CPRI, Swallow PCIe card | dynamic `odu` (split 8, `ru_sdr`) | `liboai_device.so` from the image, `libswallow.so` and `libratcm.so` from the host, and the host Radio Management Unit; the pod runs in the host network. The DU can write the Swallow file itself (`ru.sdr.aw2s.generate`) |
| `"8"` / `b210` | Ettus B210 over USB 3 through UHD | dynamic `odu` (split 8, `ru_sdr`) | `ru.sdr.b210.usb` mounts `/dev/bus/usb`; 20 and 40 MHz |
| `"8"` / `zmq` | no hardware | dynamic `odu` (split 8, `ru_sdr`) | ZMQ ports in `ru.sdr.zmq.args` |

**Timing and compression per O-RU type.** The DU holds the Open Fronthaul timing windows and IQ compression of benetel, comba, eridan, liteon, vvdn and mti (a generic set for any other type). With `ofh.vendorProfile: true` the chart names `ru.vendor` in the cell and stops rendering the generic set, so the DU applies the vendor's profile to every key not set in `ofh.ruOfh`; a key set there wins. The default (`false`) keeps the generic set every OFH DU got before, so upgrading the chart does not change a running DU. liteon, vvdn and mti have a timing profile only: no M-plane profile, so `mplane.enabled` must stay false for them.

Everything under `ru` and `txPower` is the **boot default**: a value the NMS sets over O1 (ru-type, radio-unit/sdr, tx-power) is persisted by the DU and overrides it at the next start. A radio the NMS selects that needs another attachment than the one this DU was installed with is refused and raised as the alarm `ru-attachment-mismatch`.

### 1.1 Components
| Component | Objects | Notes |
|-----------|---------|-------|
| DU | Deployment `<name>`, ConfigMaps `<name>-config` and `<name>-launcher`, Service `<name>` (O1 :830) | DPDK VF + hugepages, OFH netdev, or AW2S card; pinned CPUs |
| OFH netdev | NAD `<name>-ofh` (`host-device`) | `ofh.mode: socket` only |
| F1-U | NAD `<name>-f1u` (macvlan or bridge) | `f1u.network.enabled`; not with `aw2s` (use `f1u.bindAddress`) |
| M-plane | NAD `<name>-mplane`, Secret `<name>-mplane`, optional `mplane-dhcp` sidecar | dnsmasq leases the O-RU and sends option 43/129 (call-home) |
| Pre-flight | hook Job `<name>-preflight` on the DU node | checks VF on vfio-pci and hugepages, the OFH netdev, or the AW2S library, Swallow XML and RMU socket; F1-U bridge, M-plane parent NIC |

`<name>` is `name`, or the release name when `name` is empty.

## 2. Install
```bash
# CU once, then one release per DU in the same namespace
helm install --repo https://accelleran.github.io/helm-charts ran-cu firecell-cu -n oran -f common.yaml -f cu.yaml
helm install --repo https://accelleran.github.io/helm-charts du     firecell-du -n oran -f common.yaml -f du.yaml
helm install --repo https://accelleran.github.io/helm-charts du-2   firecell-du -n oran -f common.yaml -f du-2.yaml
```

From a checkout of this repository, use the chart paths instead: `helm install du ./charts/firecell-du ...`.

`common.yaml` holds what the CU and every DU must agree on: `global.image` and `gnb.*`.
A DU's own file lists only what is specific to it: `duId`, `cell`, `cpus`, `ofh` (VF and MACs),
and optionally `mplane` and `o1`. The DU reaches the CU-CP at `cuCpAddress` (default
`cu-cp.<namespace>.svc.cluster.local`). Any Ocudu YAML key can be added through `extraConfig`.

Adding a DU to a running gNB is a new release; the CU and the other DUs are not touched.

### 2.1 Clash checks
Each DU Deployment records its gNB-DU ID, node, CPUs, VF and DHCP-served M-plane NIC in
`firecell.io/*` annotations. On install and upgrade the chart reads the other `firecell-du`
Deployments in the namespace and refuses a DU that reuses a gNB-DU ID, or that shares a VF,
a CPU or a DHCP-served M-plane NIC with another DU on the same node. `helm template` cannot
see the cluster and skips these checks.

"Same node" means both DUs pin `kubernetes.io/hostname` to the same value in their
`nodeSelector` (or `global.nodeSelector`). Any other selector can match several nodes, so
those DUs are not compared for VF, CPU or NIC clashes. A DPDK DU with pinned CPUs should be
pinned to a host anyway.

### 2.2 NMS Access
With `nms.rbac` (the default), each release grants ServiceAccount `nms` of the [`firecell-nms`](../firecell-nms) release in `nms.namespace` what the NMS needs for its DU:

- RoleBinding `<release>-nms` to the firecell-nms chart's ClusterRole `nms-ran-<nms namespace>`: pod reads.
- Role and RoleBinding `<release>-nms-lifecycle`: get, patch and update on `deployments` and `deployments/scale` for Deployment `<name>` only, so the NMS can restart, stop and start this DU.

Every DU release adds its own pair, so the NMS can manage all the DUs in the namespace. The NMS and the DUs can be installed in either order: the bindings grant nothing until the NMS's ServiceAccount and ClusterRole exist.

## 3. Node prerequisites
- `ofh.mode: dpdk`: VFs created and bound to `vfio-pci` before kubelet starts; one VF per DU (`ofh.vfPciAddr`).
- `ofh.mode: dpdk`: 2 MiB hugepages, at least `hugepages2Mi` per DU on the node (`vm.nr_hugepages`); restart kubelet after changing them.
- `ofh.mode: socket`: the netdev `ofh.interface` exists on the node before the DU starts (MTU and offloads set on the host), and Multus has the `host-device` plugin.
- `ru.vendor: aw2s`: Swallow PCIe card with its kernel module, and `libswallow.so` and `libratcm.so` in `ru.sdr.aw2s.hostLibDir` (the device library `liboai_device.so` is taken from the image first), the Swallow XML in `ru.sdr.aw2s.configDir` (writable with `generate`), and the host Radio Management Unit running with that XML (its socket is in `/tmp`). The DU uses the host network, so only one AW2S DU per node can keep the default O2 (9090) and O1 (830) ports.
- Isolated CPUs for `cpus.timing`, `cpus.txrx` (OFH) or `cpus.ru` (split 8), and `cpus.pool`.
- `f1u.network.cniType: bridge`: the Linux bridge `f1u.network.master` exists on the node.
- Multus with the macvlan and static IPAM plugins when `mplane.enabled`.
- One O-RU per M-plane parent NIC when `mplane.dhcp.enabled` (one DHCP server per segment).
- An image that ships `/usr/local/bin/entrypoint-o1.sh` when `o1.enabled`.

## 4. Configuration Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| binary | string | `""` | Binary started by the launcher. Empty: odu_split_7_2 (ru.split "7.2") or the dynamic odu (ru.split "8"). |
| cell.antennasDl | int | `4` |  |
| cell.antennasUl | int | `4` |  |
| cell.band | int | `77` |  |
| cell.bandwidthMHz | int | `100` |  |
| cell.commonScs | int | `30` |  |
| cell.dlArfcn | int | `663680` |  |
| cell.pci | int | `1` |  |
| cell.sectorId | int | `1` |  |
| cpus.ealLcores | string | `""` |  |
| cpus.nofThreads | int | `3` | Main pool worker threads. Ocudu starts min(nofThreads, len(pool) - 3). |
| cpus.pool | string | `""` | Main pool CPUs (comma list, ranges allowed). Required. The build reserves 3 CPUs in the mask. |
| cpus.ru | string | `""` | Radio (lower PHY) thread CPUs, comma list (cell_affinities ru_cpus). Required with ru.split "8". |
| cpus.timing | string | `""` | OFH timing thread CPU. Required with ru.split "7.2". |
| cpus.txrx | string | `""` | OFH TX/RX thread CPU(s), comma list. Required with ru.split "7.2". |
| cuCpAddress | string | `""` | F1-C target. Empty resolves to cu-cp.<namespace>.svc.cluster.local (the firecell-cu Service). |
| duId | string | `""` | gNB-DU ID (gnb_du_id). Required; unique among the DUs of one CU. |
| extraConfig | object | `{"cell_cfg":{"pdsch":{"dc_offset":"center","max_alloc_attempts":8,"max_pdschs_per_slot":6,"mcs_table":"qam256","olla_cqi_inc_step":0.05,"olla_max_cqi_offset":20,"olla_target_bler":0.1},"prach":{"power_ramping_step_db":2,"prach_config_index":159,"prach_frequency_start":11,"preamble_trans_max":200},"pucch":{"min_k1":3,"p0_nominal":-96,"sr_period_ms":40},"pusch":{"mcs_table":"qam64","min_k2":3,"olla_max_snr_offset":20,"olla_snr_inc_step":0.05,"olla_target_bler":0.1,"p0_nominal_with_grant":-76},"scheduler":{"policy":{"qos_sched":{"gbr_enabled":true,"pdb_enabled":true}}},"srs":{"period_ms":40},"ssb":{"pss_to_sss_epre_db":0,"ssb_block_power_dbm":-11,"ssb_period":10},"tdd_ul_dl_cfg":{"dl_ul_tx_period":10,"nof_dl_slots":7,"nof_dl_symbols":6,"nof_ul_slots":2,"nof_ul_symbols":4},"ul_common":{"p_max":23}},"expert_execution":{"threads":{"ofh":{"enable_busy_waiting":true},"upper_phy":{"pdsch_processor_type":"flexible"}}},"expert_phy":{"max_proc_delay":5,"max_request_headroom_slots":3,"pusch_dec_max_iterations":4},"log":{"all_level":"warning","du_level":"info","f1ap_level":"info","f1u_level":"info","filename":"/tmp/logs/ocudu_du.log","gtpu_level":"warning","hex_max_size":0,"high_latency_diagnostics_enabled":false,"mac_level":"info","rlc_level":"warning"},"metrics":{"autostart_stdout_metrics":true,"enable_log":false,"layers":{"enable_mac":true,"enable_rlc":false},"periodicity":{"du_report_period":1000}},"o2":{"bind_addr":"0.0.0.0","enabled":true,"port":9090},"pcap":{"f1ap_enable":false,"f1u_enable":false,"mac_enable":false}}` | Raw Ocudu DU YAML merged over the generated config. |
| f1u.bindAddress | string | `""` | F1-U bind address when f1u.network is off. Empty: the pod IP (the node IP with ru.vendor aw2s, which runs in the host network). With aw2s next to a CU-UP on the same node, use a host address on br-f1u. |
| f1u.network.cidr | string | `""` | DU F1-U address with prefix. The IP part is the F1-U bind address. |
| f1u.network.cniType | string | `"macvlan"` | macvlan (F1-U over a host NIC toward a CU-UP on another node) or bridge (veth on a Linux bridge, for a CU-UP on the same node: all-in-one). RPS works only on the bridge veth. |
| f1u.network.enabled | bool | `false` | Put F1-U (GTP-U toward the CU-UP) on a macvlan of a host NIC instead of the pod network. Use when the CU-UP runs on another node and the pod network between the nodes is slower than the user plane. |
| f1u.network.master | string | `""` | Host interface the F1-U macvlan sits on (link toward the CU-UP node), or the Linux bridge (cniType bridge, e.g. br-f1u). |
| f1u.network.rpsCpus | string | `""` | RPS CPU mask, quoted hex (e.g. "c00000" = CPUs 22,23), set on the f1u0 veth rx queues at start. Moves the receive softirq for DL GTP-U off the sending CU-UP worker. Needs cniType bridge. Empty leaves RPS off. |
| global.image | string | `"docker.io/accelleran/ran:0.1.0"` | Ocudu runtime image built with -DENABLE_MPLANE=ON and the O1 entrypoint (/usr/local/bin/entrypoint-o1.sh). |
| global.imagePullPolicy | string | `"IfNotPresent"` | Pull policy for the Ocudu image. Use Never for images imported into containerd. |
| global.imagePullSecrets | list | `[]` | Image pull secrets for every pod. |
| global.namespace | string | `""` | Namespace for every object. Empty uses the release namespace. |
| global.nodeSelector | object | `{}` | Default nodeSelector. `nodeSelector` overrides it. |
| global.tolerations | list | `[]` | Default tolerations. `tolerations` overrides them. |
| gnb.gnbId | int | `1` | gNB-ID. |
| gnb.gnbIdBitLength | int | `22` | gNB-ID length in bits. |
| gnb.plmn | string | `"00101"` | Serving PLMN (MCC+MNC). |
| gnb.slices | list | `[{"schedCfg":{"max_prb_policy_ratio":100,"min_prb_policy_ratio":15,"priority":10},"sd":1,"sst":1}]` | Slices. sst/sd go to the DU slicing list; schedCfg, when set, becomes the per-slice sched_cfg. |
| gnb.tac | int | `1` | Tracking area code. |
| hugepages2Mi | string | `"2Gi"` | 2 MiB hugepages for this DU (requests = limits). Only used with ofh.mode dpdk. |
| image | string | `""` | Image override (defaults to global.image). |
| memory | string | `"1Gi"` | Memory request. |
| mplane.callHomePort | int | `4334` |  |
| mplane.dhcp.controllerFqdn | string | `""` | O-RAN option 43 sub-option 130 (controller FQDN). Empty omits it. |
| mplane.dhcp.enabled | bool | `false` | Serve the O-RU its M-plane lease from a dnsmasq sidecar on the macvlan. Off by default: a Benetel RU went silent after taking this lease, so serve DHCP from the node unless the sidecar is proven with your RU. |
| mplane.dhcp.image | string | `"docker.io/4km3/dnsmasq:2.90-r3"` |  |
| mplane.dhcp.leaseTime | string | `"12h"` |  |
| mplane.dhcp.router | string | `""` | Router option. Empty omits it. |
| mplane.dhcp.ruIp | string | `""` | Fixed address handed to ofh.ruMac. |
| mplane.duCidr | string | `""` | DU M-plane address with prefix (call-home target the RU learns via DHCP). |
| mplane.enabled | bool | `false` | Run the M-plane NETCONF client toward the O-RU (needs an M-plane build). |
| mplane.existingSecret | string | `""` | Existing Secret holding the password under key ssh-password. The DU reads it at start, so restart the DU after changing that Secret. |
| mplane.extra | object | `{"cache_path":"/tmp/logs/mplane_cache","copy_to_startup_after_provision":false,"log_xml":false,"mplane_log_filename":"/tmp/logs/mplane.log","ptp_lock_timeout_ms":60000,"radiate_gate_bypass_on_timeout":false,"require_oper_state_enabled":false,"supervision_enabled":true,"supervision_watchdog_period_s":23}` | Raw mplane keys merged over the generated mplane section. |
| mplane.parentInterface | string | `""` | Host interface the M-plane macvlan sits on. One O-RU per interface. |
| mplane.sshPassword | string | `""` | SSH password rendered into a chart Secret. Ignored when existingSecret is set. |
| mplane.sshUser | string | `"oranbenetel"` |  |
| mplane.txArrayGainDb | float | `27` |  |
| name | string | `""` | DU name: Deployment, Service (O1), ConfigMaps, DPDK file prefix. Empty uses the release name. |
| nms.namespace | string | `"firecell-nms"` | Namespace of the firecell-nms release. |
| nms.rbac | bool | `true` | Let the NMS read pods here, and restart, stop and start this DU's Deployment. |
| nodeSelector | object | `{}` | nodeSelector override (defaults to global.nodeSelector). |
| o1.enabled | bool | `false` | Run netopeer2/sysrepo (O1 NETCONF server for the NMS) in the DU container. |
| o1.netconfVerbosity | string | `"warning"` | netopeer2 log level: error, warning, info (a few [INF] lines per NMS request) or debug; 0-3 also accepted. Images built before the entrypoint read NETCONF_VERBOSITY always log at info. |
| o1.port | int | `830` |  |
| o1.restartOnColdCommit | bool | `false` |  |
| o1.statePath | string | `""` | Host directory kept across restarts (O1 overlay and NETCONF host key). Empty uses /var/lib/firecell/ocudu/<name>. |
| o1.ueMetrics.enabled | bool | `true` | Publish per-UE PM (/ocudu-performance gnb-du-id and ue-metrics) for the NMS UE dashboard. Needs o1.enabled. Turns on scheduler metrics (metrics.layers.enable_sched). |
| o1.ueMetrics.historyWindows | int | `40` | Report windows kept per cell. Must cover the NMS poll interval plus timeout, in du_report_period units (1-60). |
| o1.ueMetrics.maxUes | int | `256` | Maximum UE rows per cell and window. |
| o1.yangSearchPath | string | `"/usr/local/yang"` |  |
| ofh.dlPorts[0] | int | `0` |  |
| ofh.dlPorts[1] | int | `1` |  |
| ofh.dlPorts[2] | int | `2` |  |
| ofh.dlPorts[3] | int | `3` |  |
| ofh.duMac | string | `""` |  |
| ofh.genericTiming | object | `{"compr_bitwidth_dl":9,"compr_bitwidth_prach":9,"compr_bitwidth_ul":9,"compr_method_dl":"bfp","compr_method_prach":"bfp","compr_method_ul":"bfp","t1a_max_cp_dl":336,"t1a_max_cp_ul":336,"t1a_max_up":300,"t1a_min_cp_dl":285,"t1a_min_cp_ul":285,"t1a_min_up":80,"ta4_max":500,"ta4_min":50}` | The generic timing windows and compression every OFH DU got before the per-vendor profiles. Rendered unless vendorProfile is true. Keys set in ofh.ruOfh win. |
| ofh.interface | string | `""` | Host netdev for mode socket (e.g. veth-du1). It keeps its name inside the pod and goes back to the host when the pod stops. Set its MTU and offloads on the host. Required with mode socket. |
| ofh.mode | string | `"dpdk"` | How the DU sends fronthaul: dpdk (SR-IOV VF on vfio-pci, hugepages) or socket (kernel raw socket on a host netdev that Multus host-device moves into the pod, e.g. a veth toward an emulated RU on the same node). |
| ofh.prachPorts[0] | int | `4` |  |
| ofh.prachPorts[1] | int | `5` |  |
| ofh.promiscuous | bool | `false` |  |
| ofh.ruMac | string | `""` |  |
| ofh.ruOfh | object | `{"enable_dl_static_compr_hdr":true,"enable_ul_static_compr_hdr":true,"iq_scaling":1,"is_prach_cp_enabled":true,"ru_bandwidth_MHz":100}` | Raw ru_ofh keys merged into ru_ofh. A timing or compression key set here wins over both the generic set and the vendor profile. |
| ofh.ruType | string | `""` | Deprecated: use ru.vendor. When set (benetel | comba | eridan) it wins over ru.vendor for the M-plane profile. |
| ofh.ulPorts[0] | int | `0` |  |
| ofh.ulPorts[1] | int | `1` |  |
| ofh.vendorProfile | bool | `false` | true: the DU applies the Open Fronthaul timing windows and IQ compression of the O-RU type (ru.vendor: benetel, comba, eridan, liteon, vvdn or mti; the DU's table) to every key that is not set in ofh.ruOfh. The chart then renders the vendor in the cell and none of ofh.genericTiming. false (default): the generic set below, as before. |
| ofh.vfPciAddr | string | `""` | PCI address of the SR-IOV VF bound to vfio-pci. Required with mode dpdk. |
| ofh.vlanCp | int | `0` | C-plane VLAN tag. 0 sends untagged. |
| ofh.vlanUp | int | `0` | U-plane VLAN tag. 0 sends untagged. |
| preflight.enabled | bool | `true` | Pre-install/pre-upgrade Job on the DU node: VF on vfio-pci and hugepages (dpdk), the OFH netdev (socket), or the Swallow host libraries (the image device library must resolve against them), the Swallow XML and the RMU socket (aw2s); F1-U bridge, M-plane parent NIC. |
| preflight.image | string | `""` | Image for the check (needs bash and, for aw2s, ldd and the DU's /usr/local/lib/aw2s). Empty uses the DU image. |
| preflight.timeoutSeconds | int | `120` |  |
| resources | object | `{}` |  |
| ru.sdr.aw2s.antennas | list | `[]` | Antennas for generate: {id, masterPort, antennaPort} per antenna of the cell. Master ports 0 to 3 are the CPRI ports of the Swallow card; antenna ports restart at 0 on each RRH. |
| ru.sdr.aw2s.clock | string | `""` | Clock and sync sources (ru_sdr clock/sync), e.g. internal, external, gpsdo. Empty: DU default. |
| ru.sdr.aw2s.configDir | string | `""` | Host directory with the Swallow RU XML. The host RMU must use the same file. With generate it is mounted read-write and the DU overwrites the file. |
| ru.sdr.aw2s.extraArgs | string | `""` | Extra comma-separated device_args, appended in static-file mode and with generate. |
| ru.sdr.aw2s.generate | bool | `false` | true: the DU writes the Swallow file (rf_config) at every start from the cell and these values, and the chart renders no srate, bw=, nrb_dl= or oversampling. false: static-file mode, the file in configDir is yours and the chart renders srate, bw= and nrb_dl= from the values below. |
| ru.sdr.aw2s.hostLibDir | string | `"/usr/local/lib"` | Host directory with the Swallow libraries the image does not carry (libswallow.so, libratcm.so), mounted read-only. The device library (lib) is taken from the image first; a copy here is only a fallback. |
| ru.sdr.aw2s.iqCompression | string | `"none"` | IQ compression for generate: none or large. |
| ru.sdr.aw2s.iqTxShift | int | `4` | IQ TX shift (device_args iq_txshift): IQ amplitude divided by 2^n. |
| ru.sdr.aw2s.lib | string | `"liboai_device.so"` | Device library loaded by the aw2s driver (device_args lib=). |
| ru.sdr.aw2s.lowerPhyProfile | string | `"triple"` | Lower PHY execution profile (expert_execution.threads.lower_phy.execution_profile). |
| ru.sdr.aw2s.nrbDl | string | `""` | DL PRBs (device_args nrb_dl), static-file mode only. Empty: max for cell.bandwidthMHz at 30 kHz SCS (273 for 100 MHz). |
| ru.sdr.aw2s.rfConfigFile | string | `""` | Swallow RU XML in configDir (device_args rf_config=). |
| ru.sdr.aw2s.rxGain | int | `75` |  |
| ru.sdr.aw2s.sku | string | `"panther"` | RRH model for generate: panther (33 dBm), jaguar (40 dBm) or neo (37 dBm). Sets the sample rate and the power limit. |
| ru.sdr.aw2s.srateMHz | float | `122.88` | Sample rate in MHz (ru_sdr srate), static-file mode only. 122.88 for 100 MHz, 61.44 for 40-50 MHz, 30.72 for 20 MHz. |
| ru.sdr.aw2s.sync | string | `""` |  |
| ru.sdr.aw2s.timeOffsetUs | int | `0` | Swallow time offset in microseconds (generate). |
| ru.sdr.aw2s.txGain | int | `0` |  |
| ru.sdr.b210.extraArgs | string | `""` | Extra comma-separated device_args. |
| ru.sdr.b210.lowerPhyProfile | string | `"dual"` |  |
| ru.sdr.b210.rxGain | int | `60` |  |
| ru.sdr.b210.serial | string | `""` | Serial of the B210 (device_args serial=). Empty: the first device UHD finds. |
| ru.sdr.b210.srateMHz | float | `23.04` | Sample rate in MHz: 23.04 for 20 MHz, 46.08 for 40 MHz. |
| ru.sdr.b210.txGain | int | `50` |  |
| ru.sdr.b210.usb | bool | `true` | Mount /dev/bus/usb from the node into the pod. |
| ru.sdr.zmq.args | string | `"tx_port=tcp://*:2000,rx_port=tcp://localhost:2001"` | device_args, e.g. tx_port=tcp://*:2000,rx_port=tcp://localhost:2001. |
| ru.sdr.zmq.lowerPhyProfile | string | `"blocking"` |  |
| ru.sdr.zmq.rxGain | int | `60` |  |
| ru.sdr.zmq.srateMHz | float | `23.04` | Sample rate in MHz. |
| ru.sdr.zmq.txGain | int | `50` |  |
| ru.split | string | `"7.2"` | Pod shape. "7.2": O-RAN 7.2 O-RU over the `ofh` block (production: DPDK VF; lab: kernel socket to the Amarisoft emulator). "8": split 8 radio through ru_sdr (AW2S Swallow RRH, USB B210 or ZMQ). |
| ru.vendor | string | `"benetel"` | Radio of the cell, checked against `split`. 7.2: benetel, comba or eridan (M-plane profile and timing profile), liteon, vvdn or mti (timing profile only), simulator (an O-RU simulator such as the Amarisoft one: no M-plane, no identity, the generic timing and compression; the DU is told its type). 8: aw2s (Swallow card, host network namespace), b210 (USB 3 through UHD) or zmq (no hardware). |
| terminationGracePeriodSeconds | int | `150` | Seconds Kubernetes waits after SIGTERM before SIGKILL. An M-plane DU switches the O-RU carriers off at stop and needs up to the carrier ready timeout + 10 s for that (Benetel and Eridan default 90 s -> 100 s, Comba 30 s -> 40 s); 150 adds margin. A DU that is killed first leaves the O-RU radiating. With CBRS the stop takes longer: max(gate_close_timeout_ms, carrier ready timeout + 5 s) + 25 s + 1 s per cell, about 120 s + 1 s per cell with the Eridan default; raise this then. The chart checks only the M-plane bound, without CBRS. |
| tolerations | list | `[]` | Tolerations override (defaults to global.tolerations). |
| txPower.dbm | string | `nil` | Boot default of the NMS leaf tx-power/tx-power-dbm, per antenna port, in dBm. Only with ru.sdr.aw2s.generate (the DU writes it into the Swallow file and refuses a value above the RRH model's maximum). Unset: the DU's default. |

## 5. Maintenance & Troubleshooting
- OFH: the DU launcher waits for the `ru_timing` thread, then re-pins every non-`ru_*` thread onto `cpus.pool`. AW2S: no taskset wrapper; the DU pins its radio (`cpus.ru`) and pool threads itself and leaves the rest on the housekeeping CPUs.
- AW2S: `Radio Management Unit is not running` in the DU log means the host RMU is down or its socket is not in `/tmp`; `Tx underflow` means the radio or pool CPUs are overloaded or not isolated.
- With `mplane.dhcp.enabled`, `kubectl logs <name> -c mplane-dhcp` shows the O-RU DHCP exchange; the O-RU then calls home to `<duCidr IP>:4334`. With it off, the node must serve that lease (option 43, sub-options 129/130).
- An O-RU that calls home after the DU has activated its cell over F1 keeps its carriers INACTIVE. Restart the DU once the O-RU is up.
- A DU that was killed (not stopped) leaves `/dev/hugepages/<name>map_*` behind. DPDK only reclaims files with its own prefix, so remove stale files of a DU that no longer exists while no DU on the node is running.
- O1 state (host key, overlay) persists under `o1.statePath` on the node (default `/var/lib/firecell/ocudu/<name>`).
- Set `preflight.enabled=false` on clusters where hook Jobs cannot use `hostNetwork`.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
