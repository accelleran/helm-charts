# firecell-core

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Firecell 5G Core Network (AMF, SMF, UPF, NRF, UDR, UDM, AUSF, PCF, MySQL)

## 1. Architectural Role
The **Firecell Core** Helm chart deploys the 3GPP Release 16 5G Core Network stack. It operates in fully standalone mode with zero mandatory external runtime dependencies on RAN or NMS.

### 1.1 Stack Components
- **Control Plane (CP):**
  - **AMF** (`oai-amf`): Access and Mobility Management Function handling NGAP (SCTP 38412) and NAS signaling.
  - **SMF** (`oai-smf`): Session Management Function managing PDU sessions, IP allocation, and UPF interaction.
  - **NRF** (`oai-nrf`): Network Function Repository Function providing service registration and discovery.
  - **UDR** (`oai-udr`): Unified Data Repository storing subscriber data and policies.
  - **UDM** (`oai-udm`): Unified Data Management handling subscriber credentials and profile generation.
  - **AUSF** (`oai-ausf`): Authentication Server Function executing 5G-AKA authentication.
  - **PCF** (`oai-pcf`): Policy Control Function managing QoS rules and policy decisions.
- **User Plane (UP):**
  - **UPF** (`oai-upf` / `open5gs-upf`): User Plane Function handling GTP-U packet forwarding (UDP 2152) and DNN routing.
  - **Ext-DN** (`ext-dn`): External Data Network simulation container providing uplink routing and Internet connectivity.
- **Persistence & Storage:**
  - **MySQL Database** (`mysql`): StatefulSet storing 3GPP subscriber credentials, PCF policies, and provisioning records. Initialized automatically via SQL scripts in `sql/`.
- **Support & Agents:**
  - **CN-Agent** (`cn-agent`): Core network local agent for metric collection and status reporting.
  - **FC-ACS-Agent** (`fc-acs-agent`): Auto-Configuration Server agent for TR-069 management.
  - **UDSF** (`udsf`): Unstructured Data Storage Function with Redis backend.
  - **IMS**: Kamailio P/I/S-CSCF + Cx-on-UDR by default (`ims.engine=kamailio`, `ims.cxGateway.cxSot=udr`). Asterisk-only opt-in: `examples/values-ims-asterisk.yaml`.

## 2. Standalone Atomic Lifecycle
The chart incorporates built-in Kubernetes job hooks to guarantee atomic lifecycle management (installation, upgrade, rollback, uninstallation):

- **Pre-Flight Check (`pre-install`, `pre-upgrade`):**
  - Verifies host kernel modules (specifically `sctp`).
  - Verifies network interfaces, IP availability, and cluster storage classes.
  - Aborts immediately if prerequisites are not satisfied, preventing partial or broken installs.
- **Post-Flight Verification (`post-install`, `post-upgrade`):**
  - Verifies MySQL connectivity, table schemas (`AuthenticationSubscription`), and database version seeding.
  - Confirms all Core NFs reach `Ready` status within timeouts.
  - Verifies SCTP NGAP listening state (port 38412) and GTP-U listening state (port 2152).
  - Validates end-to-end control-plane and data-path viability.
  - If any verification step fails, exits non-zero to trigger Helm's `--atomic` automatic rollback.
- **Post-Delete Cleanup (`post-delete`):**
  - Reaps dangling ephemeral resources while respecting PVC retention policies.

## 3. Quick Start & Installation

### 3.1 Prerequisites
1. Ensure the `sctp` kernel module is loaded on Kubernetes nodes:
   ```bash
   sudo modprobe sctp
   ```
2. Pre-create the container registry secret in the target namespace (e.g. `firecell-core`):
   ```bash
   kubectl create namespace firecell-core
   kubectl create secret docker-registry gitlab-regcred \
     --docker-server=registry.gitlab.com \
     --docker-username=<USERNAME> \
     --docker-password=<TOKEN> \
     --namespace firecell-core
   ```

### 3.2 Atomic Installation
Deploy the chart with `--atomic` and an appropriate timeout:
```bash
helm install firecell-core ./charts/firecell-core \
  --namespace firecell-core \
  --atomic \
  --timeout 15m
```

### 3.3 Atomic Upgrade
Upgrades will automatically roll back to the previous release if post-flight verification detects any regression:
```bash
helm upgrade firecell-core ./charts/firecell-core \
  --namespace firecell-core \
  --atomic \
  --timeout 15m
```

### 3.4 IMS (Kamailio default) / Asterisk option
Default IMS is **Kamailio** P/I/S-CSCF + Cx (`CX_SOT=udr`). MySQL init applies `sql/ims_subscribers.sql` and `sql/cx_scscf_binding.sql`.

1. Ensure hostNetwork IPs `.205–.208` exist on the node.
2. Build/import `kamailio-ims` and `ims-cx-gateway` images.
3. Set `ims.mysqlHost` to a node/external MySQL IP (hostNetwork cannot use ClusterIP).

**Asterisk-only** — layer last:
```bash
helm upgrade --install firecell-core ./charts/firecell-core \
  --namespace firecell-core \
  -f examples/values-ims-asterisk.yaml \
  --atomic --timeout 15m
```

### 3.5 Uninstallation
```bash
helm uninstall firecell-core --namespace firecell-core
```

## 4. Configuration Parameters
The following table lists the configurable parameters of the Firecell Core chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| amf.command[0] | string | `"/openair-amf/bin/oai_amf"` |  |
| amf.command[1] | string | `"-c"` |  |
| amf.command[2] | string | `"/openair-amf/etc/config.yaml"` |  |
| amf.command[3] | string | `"-o"` |  |
| amf.configMountPath | string | `"/openair-amf/etc/config.yaml"` |  |
| amf.enabled | bool | `true` |  |
| amf.fcaps.datastore.file | string | `"cm.json"` |  |
| amf.fcaps.datastore.mountPath | string | `"/openair-amf/state"` |  |
| amf.fcaps.datastore.size | string | `"128Mi"` |  |
| amf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| amf.fcaps.enabled | bool | `false` |  |
| amf.fcaps.intentConfigMap.name | string | `"oai-amf-cm-intent"` |  |
| amf.fcaps.intentConfigMap.optional | bool | `true` |  |
| amf.fcaps.intentMode | string | `"pvc"` |  |
| amf.fcaps.mnsPort | int | `9091` |  |
| amf.fcaps.seedConfigPath | string | `"/openair-amf/etc/config.yaml"` |  |
| amf.headlessN2.enabled | bool | `false` |  |
| amf.headlessN2.publishNotReadyAddresses | bool | `true` |  |
| amf.headlessN2.serviceName | string | `"oai-amf-n2"` |  |
| amf.image | string | `"oai-amf"` |  |
| amf.imageOverride | string | `""` |  |
| amf.ports[0].containerPort | int | `80` |  |
| amf.ports[0].name | string | `"sbi"` |  |
| amf.ports[0].protocol | string | `"TCP"` |  |
| amf.ports[1].containerPort | int | `8080` |  |
| amf.ports[1].name | string | `"http"` |  |
| amf.ports[1].protocol | string | `"TCP"` |  |
| amf.ports[2].containerPort | int | `38412` |  |
| amf.ports[2].name | string | `"ngap"` |  |
| amf.ports[2].protocol | string | `"SCTP"` |  |
| amf.priorityClassName | string | `"firecell-prio-crit"` |  |
| amf.resources.limits.cpu | string | `"4000m"` |  |
| amf.resources.limits.memory | string | `"4Gi"` |  |
| amf.resources.requests.cpu | string | `"1000m"` |  |
| amf.resources.requests.memory | string | `"1Gi"` |  |
| amf.serviceType | string | `""` |  |
| ausf.command[0] | string | `"/openair-ausf/bin/oai_ausf"` |  |
| ausf.command[1] | string | `"-c"` |  |
| ausf.command[2] | string | `"/openair-ausf/etc/config.yaml"` |  |
| ausf.command[3] | string | `"-o"` |  |
| ausf.configMountPath | string | `"/openair-ausf/etc/config.yaml"` |  |
| ausf.enabled | bool | `true` |  |
| ausf.fcaps.datastore.file | string | `"cm.json"` |  |
| ausf.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| ausf.fcaps.datastore.size | string | `"128Mi"` |  |
| ausf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| ausf.fcaps.enabled | bool | `false` |  |
| ausf.fcaps.intentConfigMap.name | string | `"oai-ausf-cm-intent"` |  |
| ausf.fcaps.intentConfigMap.optional | bool | `true` |  |
| ausf.fcaps.intentMode | string | `"configmap"` |  |
| ausf.fcaps.mnsPort | int | `9091` |  |
| ausf.fcaps.seedConfigPath | string | `"/openair-ausf/etc/config.yaml"` |  |
| ausf.image | string | `"oai-ausf"` |  |
| ausf.imageOverride | string | `""` |  |
| ausf.ports[0].containerPort | int | `80` |  |
| ausf.ports[0].name | string | `"sbi"` |  |
| ausf.ports[0].protocol | string | `"TCP"` |  |
| ausf.ports[1].containerPort | int | `8080` |  |
| ausf.ports[1].name | string | `"http"` |  |
| ausf.ports[1].protocol | string | `"TCP"` |  |
| ausf.priorityClassName | string | `"firecell-prio-normal"` |  |
| ausf.resources.limits.cpu | string | `"2000m"` |  |
| ausf.resources.limits.memory | string | `"2Gi"` |  |
| ausf.resources.requests.cpu | string | `"500m"` |  |
| ausf.resources.requests.memory | string | `"512Mi"` |  |
| cnAgent.apiVictoriaMetricsUrl | string | `"http://nms-api-victoria-metrics-dev.firecell-nms.svc.cluster.local:8430"` |  |
| cnAgent.backendIp | string | `"nms-api.firecell-nms.svc.cluster.local"` |  |
| cnAgent.config.deployment | string | `"kubernetes"` |  |
| cnAgent.config.healthCheck.sbiCheck | bool | `true` |  |
| cnAgent.config.healthCheck.sbiProbeTimeoutS | int | `3` |  |
| cnAgent.config.kubernetes.components | object | `{}` |  |
| cnAgent.config.kubernetes.coreNfLabelSelector | string | `"firecell.io/role=core-nf"` |  |
| cnAgent.config.kubernetes.execContainer | string | `nil` |  |
| cnAgent.config.kubernetes.namespace | string | `""` |  |
| cnAgent.config.kubernetes.podSelection | string | `"any"` |  |
| cnAgent.config.logLevel | string | `"debug"` |  |
| cnAgent.config.n3InterfaceName | string | `"eno8303"` |  |
| cnAgent.config.packetCapture.connectTimeoutS | float | `1` |  |
| cnAgent.config.packetCapture.k8sServiceName | string | `"upf-packet-capture"` |  |
| cnAgent.config.packetCapture.readTimeoutS | float | `2` |  |
| cnAgent.config.packetCapture.retryBackoffS | float | `0.2` |  |
| cnAgent.config.packetCapture.retryCount | int | `1` |  |
| cnAgent.config.packetCapture.servicePort | int | `8095` |  |
| cnAgent.config.qosEnabled | bool | `true` |  |
| cnAgent.dbVersion | string | `"5.0.1"` |  |
| cnAgent.enabled | bool | `true` |  |
| cnAgent.image | string | `"cn-agent"` |  |
| cnAgent.imageOverride | string | `""` |  |
| cnAgent.imageTag | string | `"5.0.1.0"` |  |
| cnAgent.packetCaptureAddress | string | `"upf-packet-capture:8095"` |  |
| cnAgent.priorityClassName | string | `"firecell-prio-normal"` |  |
| cnAgent.redisCacheDb | int | `0` |  |
| cnAgent.redisCacheHost | string | `"redis-cache.firecell-nms.svc.cluster.local"` |  |
| cnAgent.redisCachePort | int | `6799` |  |
| cnAgent.resources.limits.cpu | string | `"2000m"` |  |
| cnAgent.resources.limits.memory | string | `"2Gi"` |  |
| cnAgent.resources.requests.cpu | string | `"500m"` |  |
| cnAgent.resources.requests.memory | string | `"1Gi"` |  |
| coreConfig.amf.amfPointer | string | `"01"` |  |
| coreConfig.amf.amfRegionId | string | `"01"` |  |
| coreConfig.amf.amfSetId | string | `"001"` |  |
| coreConfig.amf.emergencySupport | bool | `false` |  |
| coreConfig.amf.enableIms | string | `"yes"` |  |
| coreConfig.amf.enableNssf | string | `"no"` |  |
| coreConfig.amf.enableSimpleScenario | string | `"no"` |  |
| coreConfig.amf.enableSmfSelection | string | `"no"` |  |
| coreConfig.amf.enableUdsf | string | `"no"` |  |
| coreConfig.amf.name | string | `"OAI-AMF"` |  |
| coreConfig.amf.relativeCapacity | int | `30` |  |
| coreConfig.amf.releaseAllPduSessions | string | `"no"` |  |
| coreConfig.amf.statisticsTimerInterval | int | `20` |  |
| coreConfig.amf.supportedEncryptionAlgorithms[0] | string | `"NEA0"` |  |
| coreConfig.amf.supportedEncryptionAlgorithms[1] | string | `"NEA1"` |  |
| coreConfig.amf.supportedEncryptionAlgorithms[2] | string | `"NEA2"` |  |
| coreConfig.amf.supportedIntegrityAlgorithms[0] | string | `"NIA2"` |  |
| coreConfig.database.connectionTimeout | int | `10` |  |
| coreConfig.database.generateRandom | bool | `true` |  |
| coreConfig.database.host | string | `"mysql"` |  |
| coreConfig.database.name | string | `"oai_db"` |  |
| coreConfig.database.password | string | `""` |  |
| coreConfig.database.type | string | `"mysql"` |  |
| coreConfig.database.user | string | `"root"` |  |
| coreConfig.dnns[0].dnn | string | `"oai"` |  |
| coreConfig.dnns[0].ipv4Subnet | string | `"12.1.1.0/25"` |  |
| coreConfig.dnns[0].pduSessionType | string | `"IPV4"` |  |
| coreConfig.dnns[1].dnn | string | `"ims"` |  |
| coreConfig.dnns[1].ipv4Subnet | string | `"14.1.1.0/25"` |  |
| coreConfig.dnns[1].pduSessionType | string | `"IPV4V6"` |  |
| coreConfig.dns.primaryIpv4 | string | `"8.8.8.8"` |  |
| coreConfig.dns.secondaryIpv4 | string | `"8.8.8.8"` |  |
| coreConfig.httpRequestTimeoutMs | int | `10000` |  |
| coreConfig.httpVersion | int | `1` |  |
| coreConfig.ims.pcscfIpv4 | string | `"192.168.31.205"` |  |
| coreConfig.ims.pcscfIpv6 | string | `"fe80::7915:f408:1787:db8b"` |  |
| coreConfig.logLevel | string | `"debug"` |  |
| coreConfig.mcc | string | `"001"` |  |
| coreConfig.mnc | string | `"01"` |  |
| coreConfig.nrf.heartbeat | int | `50` |  |
| coreConfig.nrf.suspendedNfInterval | int | `120` |  |
| coreConfig.nssai[0].sd | string | `"000001"` |  |
| coreConfig.nssai[0].sst | int | `1` |  |
| coreConfig.pcf.enablePolicyProvisioningApi | string | `"yes"` |  |
| coreConfig.registerNf | string | `"yes"` |  |
| coreConfig.smf.enableDlPdrInPfcpSessionEstablishment | string | `"yes"` |  |
| coreConfig.smf.enableQer | string | `"yes"` |  |
| coreConfig.smf.enableUdsf | string | `"no"` |  |
| coreConfig.smf.enableUpfWoNfDiscovery | string | `"yes"` |  |
| coreConfig.smf.enableUsageReporting | string | `"no"` |  |
| coreConfig.smf.ueMtu | int | `1452` |  |
| coreConfig.smf.useLocalPccRules | string | `"no"` |  |
| coreConfig.smf.useLocalSubscriptionInfo | string | `"no"` |  |
| coreConfig.tac | string | `"0x0001"` |  |
| coreConfig.udm.suciKeyFile | string | `"/openair-udm/etc/a.key"` |  |
| coreConfig.udm.suciProfileId | int | `1` |  |
| coreConfig.udm.suciScheme | int | `1` |  |
| coreConfig.upfSessions[0].gateway | string | `"12.1.1.1"` |  |
| coreConfig.upfSessions[0].subnet | string | `"12.1.1.0/24"` |  |
| coreConfig.upfSessions[1].gateway | string | `"14.1.1.1"` |  |
| coreConfig.upfSessions[1].subnet | string | `"14.1.1.0/24"` |  |
| extDn.enabled | bool | `true` |  |
| extDn.image | string | `"trf-gen-cn5g"` |  |
| extDn.imageOverride | string | `""` |  |
| extDn.imageTag | string | `"latest"` |  |
| extDn.priorityClassName | string | `"firecell-prio-support"` |  |
| extDn.resources.limits.cpu | string | `"200m"` |  |
| extDn.resources.limits.memory | string | `"128Mi"` |  |
| extDn.resources.requests.cpu | string | `"50m"` |  |
| extDn.resources.requests.memory | string | `"64Mi"` |  |
| extDn.sidecar.enabled | bool | `false` |  |
| extDn.sidecar.image | string | `"nms-extdn-probe-sidecar"` |  |
| extDn.sidecar.imageOverride | string | `""` |  |
| extDn.sidecar.imageTag | string | `"latest"` |  |
| extDn.sidecar.resources.limits.cpu | string | `"200m"` |  |
| extDn.sidecar.resources.limits.memory | string | `"128Mi"` |  |
| extDn.sidecar.resources.requests.cpu | string | `"50m"` |  |
| extDn.sidecar.resources.requests.memory | string | `"64Mi"` |  |
| fcAcsAgent.config | string | `"auth:\n  enabled: true\n  realm: \"TR-069 ACS\"\n  algorithm: MD5\n  qop: auth\n  nonce_timeout: 3600\n\ncredentials:\n  username: cpe\n  password: cpe\n\ninitial_attach:\n  vendors:\n    cloudran:\n      management:\n        Device.ManagementServer.PeriodicInformEnable: true\n        Device.ManagementServer.PeriodicInformInterval: 20\n      perf_mgmt:\n        Device.FAP.PerfMgmt.Config.1.Enable: true\n        Device.FAP.PerfMgmt.Config.1.URL: \"http://{{ .Values.network.acsExternalIP }}:7547/smallcell/FileUploadService\"\n        Device.FAP.PerfMgmt.Config.1.PeriodicUploadInterval: 300\n        Device.FAP.PerfMgmt.Config.1.PeriodicUploadTime: \"2026-02-17T14:25:00Z\"\n        Device.FAP.PerfMgmt.Config.1.Username: \"cpe\"\n        Device.FAP.PerfMgmt.Config.1.Password: \"cpe\"\n    askey:\n      management:\n        Device.ManagementServer.PeriodicInformEnable: true\n        Device.ManagementServer.PeriodicInformInterval: 20\n      perf_mgmt:\n        Device.FAP.PerfMgmt.Config.1.Enable: true\n        Device.FAP.PerfMgmt.Config.1.URL: \"http://{{ .Values.network.acsExternalIP }}:7547/smallcell/FileUploadService\"\n        Device.FAP.PerfMgmt.Config.1.PeriodicUploadInterval: 300\n        Device.FAP.PerfMgmt.Config.1.PeriodicUploadTime: \"2026-02-17T14:25:00Z\"\n        Device.FAP.PerfMgmt.Config.1.Username: \"cpe\"\n        Device.FAP.PerfMgmt.Config.1.Password: \"cpe\"\n\nmonitoring:\n  ue_count_poll_interval_s: 10\n\nnms_address: \"http://nms-api.firecell-nms.svc.cluster.local:5001\"\n"` |  |
| fcAcsAgent.database.host | string | `"mysql"` |  |
| fcAcsAgent.database.name | string | `"firecell_ran_tr069"` |  |
| fcAcsAgent.database.port | int | `3306` |  |
| fcAcsAgent.database.user | string | `"root"` |  |
| fcAcsAgent.enabled | bool | `true` |  |
| fcAcsAgent.image | string | `"fc-acs-agent"` |  |
| fcAcsAgent.imageOverride | string | `""` |  |
| fcAcsAgent.imageTag | string | `"5.0.1.0"` |  |
| fcAcsAgent.logLevel | string | `"info"` |  |
| fcAcsAgent.pmUploadDir | string | `"/tmp/pm_uploads"` |  |
| fcAcsAgent.priorityClassName | string | `"firecell-prio-normal"` |  |
| fcAcsAgent.resources.limits.cpu | string | `"1000m"` |  |
| fcAcsAgent.resources.limits.memory | string | `"512Mi"` |  |
| fcAcsAgent.resources.requests.cpu | string | `"200m"` |  |
| fcAcsAgent.resources.requests.memory | string | `"256Mi"` |  |
| fcAcsAgent.serviceType | string | `"LoadBalancer"` |  |
| global.busyboxImage | string | `""` |  |
| global.imagePullPolicy | string | `"IfNotPresent"` |  |
| global.imagePullSecrets[0].name | string | `"gitlab-regcred"` |  |
| global.imageRegistry | string | `"registry.gitlab.com/firecell/r-d/firecellrd"` |  |
| global.namespace | string | `"firecell-core"` |  |
| global.pkgVersion | string | `"1.0.0"` |  |
| global.timezone | string | `"Europe/Paris"` |  |
| hooks.enabled | bool | `true` |  |
| hooks.postDelete.enabled | bool | `true` |  |
| hooks.postDelete.image | string | `""` |  |
| hooks.postDelete.timeoutSeconds | int | `90` |  |
| hooks.postFlight.backoffLimit | int | `1` |  |
| hooks.postFlight.enabled | bool | `true` |  |
| hooks.postFlight.image | string | `""` |  |
| hooks.postFlight.intervalSeconds | int | `4` |  |
| hooks.postFlight.retries | int | `30` |  |
| hooks.postFlight.timeoutSeconds | int | `300` |  |
| hooks.postFlight.verifyNrfRegistrations | bool | `true` |  |
| hooks.postFlight.verifyPfcpAssociation | bool | `true` |  |
| hooks.preFlight.backoffLimit | int | `1` |  |
| hooks.preFlight.enabled | bool | `true` |  |
| hooks.preFlight.image | string | `""` |  |
| hooks.preFlight.requireSctp | bool | `true` |  |
| hooks.preFlight.timeoutSeconds | int | `120` |  |
| hooks.preFlight.verifyGateway | bool | `true` |  |
| ims.enabled | bool | `true` |  |
| ims.image | string | `"asterisk-ims"` |  |
| ims.imageOverride | string | `""` |  |
| ims.imageTag | string | `"latest"` |  |
| ims.priorityClassName | string | `"firecell-prio-support"` |  |
| ims.resources.limits.cpu | string | `"500m"` |  |
| ims.resources.limits.memory | string | `"256Mi"` |  |
| ims.resources.requests.cpu | string | `"100m"` |  |
| ims.resources.requests.memory | string | `"128Mi"` |  |
| ims.sidecar.enabled | bool | `false` |  |
| ims.sidecar.image | string | `"nms-ims-sidecar"` |  |
| ims.sidecar.imageOverride | string | `""` |  |
| ims.sidecar.imageTag | string | `"latest"` |  |
| ims.sidecar.resources.limits.cpu | string | `"200m"` |  |
| ims.sidecar.resources.limits.memory | string | `"128Mi"` |  |
| ims.sidecar.resources.requests.cpu | string | `"50m"` |  |
| ims.sidecar.resources.requests.memory | string | `"64Mi"` |  |
| ims.sipConf | string | `"[general]\nlanguage=en\ntcpenable=yes\ntcpbindaddr=0.0.0.0\ntcpbindport=5060\nsrvlookup=yes\n"` |  |
| ims.usersConf | string | `""` |  |
| mysql.database | string | `"oai_db"` |  |
| mysql.enabled | bool | `true` |  |
| mysql.image | string | `"mysql:8.0"` |  |
| mysql.imageOverride | string | `""` |  |
| mysql.keepSecretOnUninstall | bool | `false` |  |
| mysql.password | string | `""` |  |
| mysql.resources.limits.cpu | string | `"1000m"` |  |
| mysql.resources.limits.memory | string | `"2Gi"` |  |
| mysql.resources.requests.cpu | string | `"600m"` |  |
| mysql.resources.requests.memory | string | `"1Gi"` |  |
| mysql.rootPassword | string | `""` |  |
| mysql.storage.size | string | `"6Gi"` |  |
| mysql.storage.storageClass | string | `""` |  |
| mysql.user | string | `""` |  |
| namespace.create | bool | `false` |  |
| namespace.keepOnUninstall | bool | `true` |  |
| network.acsExternalIP | string | `"192.0.2.102"` |  |
| network.amfExternalIP | string | `"192.0.2.101"` |  |
| network.amfServiceType | string | `"LoadBalancer"` |  |
| network.metallb.cp.l2Interface | string | `"eth0"` |  |
| network.metallb.cp.poolRange | string | `"192.0.2.101-192.0.2.110"` |  |
| network.metallb.enabled | bool | `true` |  |
| network.metallb.ingress.l2Interface | string | `"eth0"` |  |
| network.metallb.ingress.poolRange | string | `"192.0.2.100/32"` |  |
| network.metallb.up.enabled | bool | `true` |  |
| network.metallb.up.l2Interface | string | `"eth1"` |  |
| network.metallb.up.poolRange | string | `"198.51.100.101-198.51.100.110"` |  |
| network.upfExternalIP | string | `"198.51.100.101"` |  |
| networkPolicies.allowNmsNamespace | bool | `true` |  |
| networkPolicies.allowedExternalCIDRs | list | `[]` |  |
| networkPolicies.allowedNamespaces | list | `[]` |  |
| networkPolicies.enabled | bool | `true` |  |
| networkPolicies.nmsNamespace | string | `"firecell-nms"` |  |
| nrf.command[0] | string | `"/openair-nrf/bin/oai_nrf"` |  |
| nrf.command[1] | string | `"-c"` |  |
| nrf.command[2] | string | `"/openair-nrf/etc/config.yaml"` |  |
| nrf.command[3] | string | `"-o"` |  |
| nrf.configMountPath | string | `"/openair-nrf/etc/config.yaml"` |  |
| nrf.enabled | bool | `true` |  |
| nrf.fcaps.datastore.file | string | `"cm.json"` |  |
| nrf.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| nrf.fcaps.datastore.size | string | `"128Mi"` |  |
| nrf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| nrf.fcaps.enabled | bool | `false` |  |
| nrf.fcaps.intentConfigMap.name | string | `"oai-nrf-cm-intent"` |  |
| nrf.fcaps.intentConfigMap.optional | bool | `true` |  |
| nrf.fcaps.intentMode | string | `"configmap"` |  |
| nrf.fcaps.mnsPort | int | `9091` |  |
| nrf.fcaps.seedConfigPath | string | `"/openair-nrf/etc/config.yaml"` |  |
| nrf.image | string | `"oai-nrf"` |  |
| nrf.imageOverride | string | `""` |  |
| nrf.ports[0].containerPort | int | `80` |  |
| nrf.ports[0].name | string | `"sbi"` |  |
| nrf.ports[0].protocol | string | `"TCP"` |  |
| nrf.ports[1].containerPort | int | `8080` |  |
| nrf.ports[1].name | string | `"http"` |  |
| nrf.ports[1].protocol | string | `"TCP"` |  |
| nrf.priorityClassName | string | `"firecell-prio-crit"` |  |
| nrf.resources.limits.cpu | string | `"2000m"` |  |
| nrf.resources.limits.memory | string | `"2Gi"` |  |
| nrf.resources.requests.cpu | string | `"500m"` |  |
| nrf.resources.requests.memory | string | `"512Mi"` |  |
| pcf.command[0] | string | `"/openair-pcf/bin/oai_pcf"` |  |
| pcf.command[1] | string | `"-c"` |  |
| pcf.command[2] | string | `"/openair-pcf/etc/config.yaml"` |  |
| pcf.command[3] | string | `"-o"` |  |
| pcf.configMountPath | string | `"/openair-pcf/etc/config.yaml"` |  |
| pcf.enabled | bool | `true` |  |
| pcf.fcaps.datastore.file | string | `"cm.json"` |  |
| pcf.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| pcf.fcaps.datastore.size | string | `"128Mi"` |  |
| pcf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| pcf.fcaps.enabled | bool | `false` |  |
| pcf.fcaps.intentConfigMap.name | string | `"oai-pcf-cm-intent"` |  |
| pcf.fcaps.intentConfigMap.optional | bool | `true` |  |
| pcf.fcaps.intentMode | string | `"configmap"` |  |
| pcf.fcaps.mnsPort | int | `9091` |  |
| pcf.fcaps.seedConfigPath | string | `"/openair-pcf/etc/config.yaml"` |  |
| pcf.image | string | `"oai-pcf"` |  |
| pcf.imageOverride | string | `""` |  |
| pcf.ports[0].containerPort | int | `80` |  |
| pcf.ports[0].name | string | `"sbi"` |  |
| pcf.ports[0].protocol | string | `"TCP"` |  |
| pcf.ports[1].containerPort | int | `8080` |  |
| pcf.ports[1].name | string | `"http"` |  |
| pcf.ports[1].protocol | string | `"TCP"` |  |
| pcf.priorityClassName | string | `"firecell-prio-normal"` |  |
| pcf.resources.limits.cpu | string | `"2000m"` |  |
| pcf.resources.limits.memory | string | `"2Gi"` |  |
| pcf.resources.requests.cpu | string | `"500m"` |  |
| pcf.resources.requests.memory | string | `"512Mi"` |  |
| pcf.waitForMysql | bool | `true` |  |
| smf.command[0] | string | `"/openair-smf/bin/oai_smf"` |  |
| smf.command[1] | string | `"-c"` |  |
| smf.command[2] | string | `"/openair-smf/etc/config.yaml"` |  |
| smf.command[3] | string | `"-o"` |  |
| smf.configMountPath | string | `"/openair-smf/etc/config.yaml"` |  |
| smf.enabled | bool | `true` |  |
| smf.fcaps.datastore.file | string | `"cm.json"` |  |
| smf.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| smf.fcaps.datastore.size | string | `"128Mi"` |  |
| smf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| smf.fcaps.enabled | bool | `false` |  |
| smf.fcaps.intentConfigMap.name | string | `"oai-smf-cm-intent"` |  |
| smf.fcaps.intentConfigMap.optional | bool | `true` |  |
| smf.fcaps.intentMode | string | `"configmap"` |  |
| smf.fcaps.mnsPort | int | `9091` |  |
| smf.fcaps.seedConfigPath | string | `"/openair-smf/etc/config.yaml"` |  |
| smf.hostNetwork | bool | `false` |  |
| smf.hostPfcpIP | string | `""` |  |
| smf.hostPfcpMacvlan | string | `"smf-n4-mac"` |  |
| smf.image | string | `"oai-smf"` |  |
| smf.imageOverride | string | `""` |  |
| smf.mnsInterface | string | `""` |  |
| smf.multus.cniType | string | `"ipvlan"` |  |
| smf.multus.enabled | bool | `false` |  |
| smf.multus.masterInterface | string | `"eth0"` |  |
| smf.multus.mode | string | `"l3s"` |  |
| smf.multus.nadName | string | `"smf-n4-net"` |  |
| smf.multus.subnetPrefix | int | `24` |  |
| smf.n4IP | string | `""` |  |
| smf.n4Interface | string | `"eth0"` |  |
| smf.pfcpParentInterface | string | `""` |  |
| smf.ports[0].containerPort | int | `80` |  |
| smf.ports[0].name | string | `"sbi"` |  |
| smf.ports[0].protocol | string | `"TCP"` |  |
| smf.ports[1].containerPort | int | `8080` |  |
| smf.ports[1].name | string | `"http"` |  |
| smf.ports[1].protocol | string | `"TCP"` |  |
| smf.ports[2].containerPort | int | `8805` |  |
| smf.ports[2].name | string | `"n4"` |  |
| smf.ports[2].protocol | string | `"UDP"` |  |
| smf.priorityClassName | string | `"firecell-prio-high"` |  |
| smf.progressDeadlineSeconds | int | `1200` |  |
| smf.resources.limits.cpu | string | `"4000m"` |  |
| smf.resources.limits.memory | string | `"4Gi"` |  |
| smf.resources.requests.cpu | string | `"1000m"` |  |
| smf.resources.requests.memory | string | `"1Gi"` |  |
| smf.sbiClusterIP | string | `"10.42.0.1"` |  |
| smf.sbiInterface | string | `"cni0"` |  |
| udm.command[0] | string | `"/openair-udm/bin/oai_udm"` |  |
| udm.command[1] | string | `"-c"` |  |
| udm.command[2] | string | `"/openair-udm/etc/config.yaml"` |  |
| udm.command[3] | string | `"-o"` |  |
| udm.configMountPath | string | `"/openair-udm/etc/config.yaml"` |  |
| udm.enabled | bool | `true` |  |
| udm.fcaps.datastore.file | string | `"cm.json"` |  |
| udm.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| udm.fcaps.datastore.size | string | `"128Mi"` |  |
| udm.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| udm.fcaps.enabled | bool | `false` |  |
| udm.fcaps.intentConfigMap.name | string | `"oai-udm-cm-intent"` |  |
| udm.fcaps.intentConfigMap.optional | bool | `true` |  |
| udm.fcaps.intentMode | string | `"configmap"` |  |
| udm.fcaps.mnsPort | int | `9091` |  |
| udm.fcaps.seedConfigPath | string | `"/openair-udm/etc/config.yaml"` |  |
| udm.image | string | `"oai-udm"` |  |
| udm.imageOverride | string | `""` |  |
| udm.ports[0].containerPort | int | `80` |  |
| udm.ports[0].name | string | `"sbi"` |  |
| udm.ports[0].protocol | string | `"TCP"` |  |
| udm.ports[1].containerPort | int | `8080` |  |
| udm.ports[1].name | string | `"http"` |  |
| udm.ports[1].protocol | string | `"TCP"` |  |
| udm.priorityClassName | string | `"firecell-prio-normal"` |  |
| udm.resources.limits.cpu | string | `"2000m"` |  |
| udm.resources.limits.memory | string | `"2Gi"` |  |
| udm.resources.requests.cpu | string | `"500m"` |  |
| udm.resources.requests.memory | string | `"512Mi"` |  |
| udm.suciKey | string | `""` |  |
| udr.command[0] | string | `"/openair-udr/bin/oai_udr"` |  |
| udr.command[1] | string | `"-c"` |  |
| udr.command[2] | string | `"/openair-udr/etc/config.yaml"` |  |
| udr.command[3] | string | `"-o"` |  |
| udr.configMountPath | string | `"/openair-udr/etc/config.yaml"` |  |
| udr.enabled | bool | `true` |  |
| udr.fcaps.datastore.file | string | `"cm.json"` |  |
| udr.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| udr.fcaps.datastore.size | string | `"128Mi"` |  |
| udr.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| udr.fcaps.enabled | bool | `false` |  |
| udr.fcaps.intentConfigMap.name | string | `"oai-udr-cm-intent"` |  |
| udr.fcaps.intentConfigMap.optional | bool | `true` |  |
| udr.fcaps.intentMode | string | `"configmap"` |  |
| udr.fcaps.mnsPort | int | `9091` |  |
| udr.fcaps.seedConfigPath | string | `"/openair-udr/etc/config.yaml"` |  |
| udr.image | string | `"oai-udr"` |  |
| udr.imageOverride | string | `""` |  |
| udr.ports[0].containerPort | int | `8080` |  |
| udr.ports[0].name | string | `"http"` |  |
| udr.ports[0].protocol | string | `"TCP"` |  |
| udr.priorityClassName | string | `"firecell-prio-crit"` |  |
| udr.resources.limits.cpu | string | `"2000m"` |  |
| udr.resources.limits.memory | string | `"2Gi"` |  |
| udr.resources.requests.cpu | string | `"500m"` |  |
| udr.resources.requests.memory | string | `"512Mi"` |  |
| udr.waitForMysql | bool | `true` |  |
| udsf.enabled | bool | `false` |  |
| udsf.fcaps.datastore.file | string | `"cm.json"` |  |
| udsf.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| udsf.fcaps.datastore.size | string | `"128Mi"` |  |
| udsf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| udsf.fcaps.enabled | bool | `false` |  |
| udsf.fcaps.intentConfigMap.name | string | `"oai-udsf-cm-intent"` |  |
| udsf.fcaps.intentConfigMap.optional | bool | `true` |  |
| udsf.fcaps.intentMode | string | `"configmap"` |  |
| udsf.fcaps.mnsPort | int | `9091` |  |
| udsf.healthPath | string | `"/nudsf-data-mgmt/v1/healthz"` |  |
| udsf.host | string | `"oai-udsf"` |  |
| udsf.image | string | `"firecell-udsf"` |  |
| udsf.imageOverride | string | `""` |  |
| udsf.redis.image | string | `"redis:7-alpine"` |  |
| udsf.redis.imageOverride | string | `""` |  |
| udsf.redis.port | int | `6379` |  |
| udsf.redis.resources.limits.cpu | string | `"500m"` |  |
| udsf.redis.resources.limits.memory | string | `"256Mi"` |  |
| udsf.redis.resources.requests.cpu | string | `"50m"` |  |
| udsf.redis.resources.requests.memory | string | `"64Mi"` |  |
| udsf.resources.limits.cpu | string | `"1000m"` |  |
| udsf.resources.limits.memory | string | `"512Mi"` |  |
| udsf.resources.requests.cpu | string | `"100m"` |  |
| udsf.resources.requests.memory | string | `"128Mi"` |  |
| udsf.sbiPort | int | `8080` |  |
| udsf.serviceName | string | `"oai-udsf"` |  |
| upf.autoCreateN3Macvlan | bool | `false` |  |
| upf.blockSshAccess | string | `"FALSE"` |  |
| upf.configSchema | string | `"mr97"` |  |
| upf.datapathInit.n6GatewayArpIntervalSec | int | `5` |  |
| upf.datapathInit.n6GatewayArpRetries | int | `60` |  |
| upf.disableNat | string | `"FALSE"` |  |
| upf.dnnDataplane.basePort | int | `8196` |  |
| upf.dnnDataplane.enabled | bool | `false` |  |
| upf.dnnDataplane.image | string | `"fc-dnn-dataplane"` |  |
| upf.dnnDataplane.imageOverride | string | `""` |  |
| upf.dnnDataplane.imageTag | string | `"5.0.1.0"` |  |
| upf.dnnDataplane.resources.limits.cpu | string | `"500m"` |  |
| upf.dnnDataplane.resources.limits.memory | string | `"256Mi"` |  |
| upf.dnnDataplane.resources.requests.cpu | string | `"50m"` |  |
| upf.dnnDataplane.resources.requests.memory | string | `"64Mi"` |  |
| upf.dnsSearchDomains[0] | string | `"firecell-core.svc.cluster.local"` |  |
| upf.dnsSearchDomains[1] | string | `"svc.cluster.local"` |  |
| upf.dnsSearchDomains[2] | string | `"cluster.local"` |  |
| upf.dnsServers[0] | string | `"10.152.183.10"` |  |
| upf.enableBpfDatapath | bool | `true` |  |
| upf.enabled | bool | `true` |  |
| upf.fcaps.datastore.file | string | `"cm.json"` |  |
| upf.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| upf.fcaps.datastore.size | string | `"128Mi"` |  |
| upf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| upf.fcaps.enabled | bool | `false` |  |
| upf.fcaps.intentConfigMap.name | string | `"oai-upf-cm-intent"` |  |
| upf.fcaps.intentConfigMap.optional | bool | `true` |  |
| upf.fcaps.intentMode | string | `"configmap"` |  |
| upf.fcaps.mnsPort | int | `9091` |  |
| upf.fcaps.seedConfigPath | string | `"/openair-upf/etc/config.yaml"` |  |
| upf.hostNetwork | bool | `true` |  |
| upf.hostPfcpIP | string | `""` |  |
| upf.hostPfcpMacvlan | string | `""` |  |
| upf.injectCiliumPodRoute | bool | `true` |  |
| upf.instances | list | `[]` |  |
| upf.maxSessions | int | `1024` |  |
| upf.n3IP | string | `"198.51.100.101"` |  |
| upf.n3Interface | string | `"eth1"` |  |
| upf.n4Interface | string | `"eth0"` |  |
| upf.n6Cidr | string | `""` |  |
| upf.n6Interface | string | `""` |  |
| upf.n9Interface | string | `""` |  |
| upf.o5gsImage | string | `"o5gs-upf"` |  |
| upf.o5gsImageOverride | string | `""` |  |
| upf.oaiEnableEthPdu | bool | `false` |  |
| upf.oaiHostNet.smfN4Interface | string | `""` |  |
| upf.oaiHostNet.stubInterface | string | `""` |  |
| upf.oaiImage | string | `"oai-upf"` |  |
| upf.oaiImageOverride | string | `""` |  |
| upf.packetCapture.disableOnMultiInstance | bool | `true` |  |
| upf.packetCapture.enabled | bool | `true` |  |
| upf.packetCapture.imageOverride | string | `""` |  |
| upf.packetCapture.imageTag | string | `"5.0.1.0"` |  |
| upf.performance.conntrackMax | int | `524288` |  |
| upf.performance.conntrackUdpStreamTimeout | int | `3600` |  |
| upf.performance.conntrackUdpTimeout | int | `120` |  |
| upf.performance.cpuAffinity | string | `""` |  |
| upf.performance.disableLRO | bool | `true` |  |
| upf.performance.enableBBR | bool | `true` |  |
| upf.performance.enabled | bool | `false` |  |
| upf.performance.mtu | int | `1420` |  |
| upf.performance.netdevBudget | int | `600` |  |
| upf.performance.netdevBudgetUsecs | int | `8000` |  |
| upf.performance.socketRmemMax | int | `26214400` |  |
| upf.performance.socketWmemMax | int | `26214400` |  |
| upf.performance.tcpMssClamp | bool | `true` |  |
| upf.performance.tunQdisc | string | `"pfifo_fast"` |  |
| upf.performance.txQueueLen | int | `10000` |  |
| upf.pfcpHost | string | `""` |  |
| upf.privileged | bool | `true` |  |
| upf.protectedSshNetworks | string | `"10.0.0.0/8,192.168.31.0/24,172.17.5.0/24"` |  |
| upf.remoteN6Gw | string | `""` |  |
| upf.resources.limits.cpu | string | `"1000m"` |  |
| upf.resources.limits.memory | string | `"1Gi"` |  |
| upf.resources.requests.cpu | string | `"200m"` |  |
| upf.resources.requests.memory | string | `"512Mi"` |  |
| upf.sbiInterface | string | `""` |  |
| upf.serviceType | string | `"LoadBalancer"` |  |
| upf.sshExemptedIps | string | `"192.168.31.254"` |  |
| upf.type | string | `"o5gs"` |  |
| upf.xdpAttachMode | string | `"auto"` |  |

## 5. Maintenance & Troubleshooting
- **Check Release Status:**
  ```bash
  helm status firecell-core -n firecell-core
  ```
- **Inspect Verification Hook Logs:**
  ```bash
  kubectl logs -n firecell-core job/firecell-core-postflight-verify -f
  ```
- **Inspect NF Health Endpoints:**
  All OAI NFs expose HTTP health probes on `8080` (or `80`) via internal sidecars.
- **Manual Rollback:**
  If needed, roll back to a specific revision manually:
  ```bash
  helm rollback firecell-core <REVISION> -n firecell-core
  ```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
