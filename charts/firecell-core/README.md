# firecell-core

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Firecell 5G Core Network (AMF, SMF, UPF, NRF, UDR, UDM, AUSF, PCF, MySQL, IMS Kamailio+Cx (Asterisk optional))

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
  - **UPF** (`oai-upf`): User Plane Function handling GTP-U packet forwarding (UDP 2152) and DNN routing.
  - **Ext-DN** (`ext-dn`): External Data Network simulation container providing uplink routing and Internet connectivity.
- **Persistence & Storage:**
  - **MySQL Database** (`mysql`): StatefulSet storing 3GPP subscriber credentials, PCF policies, and provisioning records. Initialized automatically via SQL scripts in `sql/`.
- **Support & Agents:**
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
  - If any verification step fails, exits non-zero to trigger Helm's `--rollback-on-failure` automatic rollback.
- **Post-Delete Cleanup (`post-delete`):**
  - Reaps dangling ephemeral resources while respecting PVC retention policies.

## 3. Quick Start & Installation

MetalLB is **optional**. The chart ships `templates/metallb-pool.yaml` only when `network.metallb.enabled` is true (for AMF/ACS LoadBalancer VIPs toward an off-cluster gNB). Set `network.metallb.enabled: false` (and typically `network.amfServiceType: ClusterIP` or hostNetwork UPF paths) when the cluster has no MetalLB.

### 3.1 Prerequisites
1. Ensure the `sctp` kernel module is loaded on Kubernetes nodes:
   ```bash
   sudo modprobe sctp
   ```
2. Pre-create the container registry secret in the target namespace (e.g. `firecell-core`).
   The images come from `ghcr.io/accelleran` (private packages; a token with `read:packages`),
   each NF at its release tag (`v6.x-rc-02-<commit>`, its `imageTag` in `values.yaml`). The
   secret keeps its old default name, `dockerhub-regcred` (`global.imagePullSecrets`):
   ```bash
   kubectl create namespace firecell-core
   kubectl create secret docker-registry dockerhub-regcred \
     --docker-server=ghcr.io \
     --docker-username=<USERNAME> \
     --docker-password=<TOKEN> \
     --namespace firecell-core
   ```
3. To try a cn5g **PR build from GHCR** instead of the release tags, layer
   [`examples/values-images-ghcr.yaml`](examples/values-images-ghcr.yaml) and set
   `global.pkgVersion` to the PR tag (`pr-<NUMBER>`):
   ```bash
   helm upgrade --install firecell-core ./charts/firecell-core \
     --namespace firecell-core \
     -f examples/values-images-ghcr.yaml \
     --set global.pkgVersion=pr-<NUMBER> \
     --rollback-on-failure --timeout 15m
   ```
   That overlay points `imageRegistry` at `ghcr.io/accelleran` and expects a
   `ghcr-regcred` pull secret (`--docker-server=ghcr.io`).

### 3.2 Atomic Installation
Deploy the chart with `--rollback-on-failure` and an appropriate timeout:
```bash
helm install --repo https://accelleran.github.io/helm-charts firecell-core firecell-core \
  --namespace firecell-core \
  --rollback-on-failure \
  --timeout 15m
```

### 3.3 Atomic Upgrade
Upgrades will automatically roll back to the previous release if post-flight verification detects any regression:
```bash
helm upgrade --repo https://accelleran.github.io/helm-charts firecell-core firecell-core \
  --namespace firecell-core \
  --rollback-on-failure \
  --timeout 15m
```

#### Upgrading from an earlier chart version (0.1.0, 0.2.0)
Check these before `helm upgrade`. Each one changes what an existing install gets.
- **Images.** They come from `ghcr.io/accelleran` at each NF's release tag (`v6.x-rc-02-<commit>`), no longer from Docker Hub. The pull secret (`global.imagePullSecrets`, default name `dockerhub-regcred`) must hold GHCR credentials.
- **IMS addresses.** `ims.{pcscf,icscf,scscf,cxGateway}.ip` have no defaults any more; an install that relied on `192.168.31.205`–`.208` must set them. Without `ims.pcscf.ip` or `coreConfig.ims.pcscfIpv4` the SMF gives UEs no IPv4 P-CSCF (`0.0.0.0`), and the chart prints a warning.
- **Database.** With the chart's MySQL, the pre-upgrade Job `<release>-db-upgrade` (`hooks.dbUpgrade`) widens the callback URI columns of older schemas to `varchar(255)` and creates `MbsSubscriptionData`. Its statements change nothing on a database that already has them. With an external database, run the same changes by hand (`sql/oai_db-5mbs.sql` and the `ALTER TABLE`s in `templates/hooks/pre-upgrade-db.yaml`).
- **SBI TLS and OAuth2 are on** (`global.sbi.tls.enabled`, `global.sbi.oauth2.enabled`). Turning TLS on in a running core needs a maintenance window in which the UEs register again. The released Firecell NMS provisions over cleartext HTTP/1.1 without a token, so a core it manages needs both set to `false`.
- **EIR and NEF are enabled** (`eir.enabled`, `nef.enabled`). Set them to `false` to keep the earlier set of NFs.
- **Ciphering preference.** The AMF now prefers NEA2, NEA1, then NEA0 (`coreConfig.amf.supportedEncryptionAlgorithms`). Earlier it offered NEA0 first.
- **UE-AMBR default** (`coreConfig.amf.ueAmbrDefault`) is 10 Gbps. It applies when neither the PCF nor the subscription gives one; `"1 Gbps"` restores the AMF default.
- **UPF SNAT** (`upf.enableSnat`, default `true`) now also applies to the Multus UPF. A Kamailio IMS DNN needs it `false`, plus a route back to the UE subnet (`ims.upfN6Gateway`).

### 3.4 IMS (Kamailio default) / Asterisk option
Default IMS is **Kamailio** P/I/S-CSCF + Cx gateway (`CX_SOT=udr`). MySQL init applies `sql/ims_subscribers.sql` and `sql/cx_scscf_binding.sql`.

1. Ensure hostNetwork IPs for P/I/S-CSCF and Cx exist on the node (defaults `.205–.208`).
2. Build/import `kamailio-ims` and `ims-cx-gateway` images (or set `imageOverride` to GHCR/local tags).
3. Leave `ims.mysqlHost` empty to use `mysql.<ns>.svc.cluster.local` (works with hostNetwork when ClusterIP DNS is reachable). Override only for external MySQL.

**Asterisk-only** (disables Kamailio/Cx) — layer last:
```bash
helm upgrade --install firecell-core ./charts/firecell-core \
  --namespace firecell-core \
  -f examples/values-ims-asterisk.yaml \
  --rollback-on-failure --timeout 15m
```

### 3.4 Uninstallation
```bash
helm uninstall firecell-core --namespace firecell-core
```

With `mysql.keepSecretOnUninstall: true`, the Secrets `mysql-secrets` and `ims-db-credentials` stay after `helm uninstall`. A new install under the same release name and namespace takes them over; delete them first to install under another release name.

### 3.5 NMS Access
With `nms.rbac` (the default), the chart grants ServiceAccount `nms` of the [`firecell-nms`](../firecell-nms) release in `nms.namespace` (default `firecell-nms`) what the NMS needs in this namespace:

- RoleBinding `<release>-nms` to the firecell-nms chart's ClusterRole `nms-core-<nms namespace>`: reads of pods and their logs, events, and Deployments, ReplicaSets, StatefulSets and DaemonSets; ConfigMaps (read and the intent writes).
- Role and RoleBinding `<release>-nms-lifecycle`: get, patch and update on `deployments` and `deployments/scale` for the NF Deployments this release renders (`oai-amf`, `oai-smf`, `oai-pcf`, `oai-udr`, `oai-udm`, `oai-nrf`, `oai-ausf`, `udsf.serviceName`, and `oai-upf<suffix>` per UPF instance), so the NMS can restart, stop and start them.

The NMS and the core can be installed in either order: the bindings grant nothing until the NMS's ServiceAccount and ClusterRole exist.

Every install and upgrade also writes ConfigMap `<release>-release-info` (label `firecell.io/release-info: "true"`) in the release namespace, for the NMS support bundles and drift checks, since the NMS reads no Helm release Secret. `release.json` holds the release, namespace, chart (`<name>-<version>`), appVersion, revision, render time (`renderedAt`, UTC), a SHA-256 digest of the values (`valuesDigest`) and the image of every container the chart renders (`images`, keyed `<workload>/<container>`, taken from the rendered pods themselves). `history.json` keeps up to 20 earlier `release.json` records, newest first, read back from the live ConfigMap with `lookup`; it starts empty after `helm template` or a client-side dry run. Neither holds any values content or anything from a Secret. `helm rollback` reapplies the stored manifest of the target revision, so the record and its history roll back with it.

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
| amf.fcaps.intentMode | string | `"configmap"` |  |
| amf.fcaps.mnsPort | int | `9091` |  |
| amf.fcaps.seedConfigPath | string | `"/openair-amf/etc/config.yaml"` |  |
| amf.headlessN2.enabled | bool | `false` |  |
| amf.headlessN2.publishNotReadyAddresses | bool | `true` |  |
| amf.headlessN2.serviceName | string | `"oai-amf-n2"` |  |
| amf.image | string | `"cn5g-amf"` |  |
| amf.imageOverride | string | `""` |  |
| amf.imageTag | string | `"v6.x-rc-02-f985f309"` |  |
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
| ausf.image | string | `"cn5g-ausf"` |  |
| ausf.imageOverride | string | `""` |  |
| ausf.imageTag | string | `"v6.x-rc-02-61491d71"` |  |
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
| coreConfig.amf.amPolicy.enabled | bool | `false` |  |
| coreConfig.amf.amfPointer | string | `"01"` |  |
| coreConfig.amf.amfRegionId | string | `"01"` |  |
| coreConfig.amf.amfSetId | string | `"001"` |  |
| coreConfig.amf.callTrace | object | `{}` |  |
| coreConfig.amf.edrx | object | `{}` |  |
| coreConfig.amf.eir.enabled | bool | `true` |  |
| coreConfig.amf.eir.enforcementMode | string | `"permissive"` |  |
| coreConfig.amf.emergencySupport | bool | `false` |  |
| coreConfig.amf.enableIms | string | `"yes"` |  |
| coreConfig.amf.enableNssf | string | `""` |  |
| coreConfig.amf.enableSimpleScenario | string | `"no"` |  |
| coreConfig.amf.enableSmfSelection | string | `"no"` |  |
| coreConfig.amf.enableUdsf | string | `"yes"` |  |
| coreConfig.amf.handover.sourceReleaseDelayMs | int | `1000` |  |
| coreConfig.amf.name | string | `"OAI-AMF"` |  |
| coreConfig.amf.nasTimers.t3512Min | int | `50` |  |
| coreConfig.amf.nid | string | `""` |  |
| coreConfig.amf.npn | object | `{}` |  |
| coreConfig.amf.paging.fanoutMultiGnb | bool | `true` |  |
| coreConfig.amf.redcap | object | `{}` |  |
| coreConfig.amf.relativeCapacity | int | `30` |  |
| coreConfig.amf.releaseAllPduSessions | string | `"no"` |  |
| coreConfig.amf.rrcInactiveAssistance | bool | `true` |  |
| coreConfig.amf.sbiCallbackUseHost | bool | `true` |  |
| coreConfig.amf.statisticsTimerInterval | int | `20` |  |
| coreConfig.amf.supportedEncryptionAlgorithms[0] | string | `"NEA2"` |  |
| coreConfig.amf.supportedEncryptionAlgorithms[1] | string | `"NEA1"` |  |
| coreConfig.amf.supportedEncryptionAlgorithms[2] | string | `"NEA0"` |  |
| coreConfig.amf.supportedIntegrityAlgorithms[0] | string | `"NIA2"` |  |
| coreConfig.amf.ueAmbrDefault.downlink | string | `"10 Gbps"` |  |
| coreConfig.amf.ueAmbrDefault.uplink | string | `"10 Gbps"` |  |
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
| coreConfig.ims.pcscfIpv4 | string | `""` |  |
| coreConfig.ims.pcscfIpv6 | string | `""` |  |
| coreConfig.logLevel | string | `"info"` |  |
| coreConfig.mcc | string | `"001"` |  |
| coreConfig.mnc | string | `"01"` |  |
| coreConfig.nrf.heartbeat | int | `50` |  |
| coreConfig.nrf.suspendedNfInterval | int | `120` |  |
| coreConfig.nssai[0].sd | string | `"000001"` |  |
| coreConfig.nssai[0].sst | int | `1` |  |
| coreConfig.pcf.amPolicy | object | `{}` |  |
| coreConfig.pcf.enablePolicyProvisioningApi | string | `"yes"` |  |
| coreConfig.pcf.policyAuthorization.afEvents | bool | `true` |  |
| coreConfig.pcf.policyAuthorization.pcscfRestoration | bool | `true` |  |
| coreConfig.pcf.trace | object | `{}` |  |
| coreConfig.registerNf | string | `"yes"` |  |
| coreConfig.smf.enableDlPdrInPfcpSessionEstablishment | string | `"yes"` |  |
| coreConfig.smf.enableQer | string | `"yes"` |  |
| coreConfig.smf.enableUdsf | string | `"yes"` |  |
| coreConfig.smf.enableUpfWoNfDiscovery | string | `"yes"` |  |
| coreConfig.smf.enableUsageReporting | string | `"no"` |  |
| coreConfig.smf.handover.dataForwarding | string | `"direct_and_indirect"` |  |
| coreConfig.smf.handover.endMarker | bool | `true` |  |
| coreConfig.smf.handover.indirectForwardingTimerMs | int | `2000` |  |
| coreConfig.smf.ipv6.dhcpv6.allocateTimeoutS | string | `""` |  |
| coreConfig.smf.ipv6.dhcpv6.linkAddress | string | `""` |  |
| coreConfig.smf.ipv6.dhcpv6.primaryServer | string | `""` |  |
| coreConfig.smf.ipv6.dhcpv6.secondaryServer | string | `""` |  |
| coreConfig.smf.ipv6.dhcpv6.sendRelease | string | `""` |  |
| coreConfig.smf.ipv6.n4u.address | string | `""` |  |
| coreConfig.smf.ipv6.n4u.port | string | `""` |  |
| coreConfig.smf.ipv6.ra.initialCount | string | `""` |  |
| coreConfig.smf.ipv6.ra.initialIntervalS | string | `""` |  |
| coreConfig.smf.ipv6.ra.maxRtrAdvIntervalS | string | `""` |  |
| coreConfig.smf.ipv6.ra.mtu | string | `""` |  |
| coreConfig.smf.ipv6.ra.rdnss | string | `""` |  |
| coreConfig.smf.ipv6.ra.routerLifetimeS | string | `""` |  |
| coreConfig.smf.ipv6.smfLinkLocal | string | `""` |  |
| coreConfig.smf.locationApiRoot | string | `""` |  |
| coreConfig.smf.mbs.enabled | bool | `false` |  |
| coreConfig.smf.mbs.sessions | list | `[]` |  |
| coreConfig.smf.n4Restore.activeFirst | bool | `true` |  |
| coreConfig.smf.n4Restore.maxInFlightPerUpf | int | `64` |  |
| coreConfig.smf.n4Restore.ratePerUpf | int | `500` |  |
| coreConfig.smf.sbiServerThreads | int | `2` |  |
| coreConfig.smf.sbiWorkerThreads | int | `8` |  |
| coreConfig.smf.ueMtu | int | `1452` |  |
| coreConfig.smf.useLocalPccRules | string | `"no"` |  |
| coreConfig.smf.useLocalSubscriptionInfo | string | `"no"` |  |
| coreConfig.tac | string | `"0x0001"` |  |
| coreConfig.udm.suciKeyFile | string | `"/openair-udm/etc/a.key"` |  |
| coreConfig.udm.suciProfileId | int | `1` |  |
| coreConfig.udm.suciScheme | int | `1` |  |
| eir.command[0] | string | `"/usr/local/bin/cn5g-eir"` |  |
| eir.command[1] | string | `"--config"` |  |
| eir.command[2] | string | `"/etc/cn5g-eir/eir.yaml"` |  |
| eir.config.advertiseApiRoot | string | `""` |  |
| eir.config.allowAnonymous | bool | `true` |  |
| eir.config.authProfile | string | `"auto"` |  |
| eir.config.checkToken | string | `"lab-amf-token"` |  |
| eir.config.healthHttp1Port | int | `8081` |  |
| eir.config.listenHost | string | `"0.0.0.0"` |  |
| eir.config.listenPort | int | `8080` |  |
| eir.config.mysqlDatabase | string | `""` |  |
| eir.config.nrfEnabled | bool | `true` |  |
| eir.config.nrfNfmUrl | string | `""` |  |
| eir.config.nrfRequired | bool | `true` |  |
| eir.config.peiSupiBindingCheck | bool | `true` |  |
| eir.config.provToken | string | `""` |  |
| eir.configMountPath | string | `"/etc/cn5g-eir/eir.yaml"` |  |
| eir.enabled | bool | `true` |  |
| eir.fcaps.datastore.file | string | `"cm.json"` |  |
| eir.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| eir.fcaps.datastore.size | string | `"128Mi"` |  |
| eir.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| eir.fcaps.enabled | bool | `false` |  |
| eir.fcaps.intentConfigMap.name | string | `"oai-eir-cm-intent"` |  |
| eir.fcaps.intentConfigMap.optional | bool | `true` |  |
| eir.fcaps.intentMode | string | `"configmap"` |  |
| eir.fcaps.mnsPort | int | `9091` |  |
| eir.image | string | `"cn5g-eir"` |  |
| eir.imageOverride | string | `""` |  |
| eir.imageTag | string | `"v6.x-rc-02-66ea8c4c"` |  |
| eir.priorityClassName | string | `"firecell-prio-normal"` |  |
| eir.resources.limits.cpu | string | `"1000m"` |  |
| eir.resources.limits.memory | string | `"1Gi"` |  |
| eir.resources.requests.cpu | string | `"100m"` |  |
| eir.resources.requests.memory | string | `"256Mi"` |  |
| extDn.enabled | bool | `false` |  |
| extDn.image | string | `"trf-gen-cn5g"` |  |
| extDn.imageOverride | string | `""` |  |
| extDn.imageTag | string | `"latest"` |  |
| extDn.n6.ip | string | `""` |  |
| extDn.n6.nadName | string | `"ext-dn-n6"` |  |
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
| fcAcsAgent.enabled | bool | `false` |  |
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
| global.busyboxImage | string | `"docker.io/library/busybox:1.38.0-glibc"` |  |
| global.imagePullPolicy | string | `"IfNotPresent"` |  |
| global.imagePullSecrets[0].name | string | `"dockerhub-regcred"` |  |
| global.imageRegistry | string | `"ghcr.io/accelleran"` |  |
| global.namespace | string | `"firecell-core"` |  |
| global.pkgVersion | string | `"6.0.0"` |  |
| global.sbi.oauth2.enabled | bool | `true` |  |
| global.sbi.oauth2.keySource | string | `"helm"` |  |
| global.sbi.oauth2.publicKeySecret | string | `"nrf-oauth2-public-key"` |  |
| global.sbi.oauth2.signingKeySecret | string | `"nrf-oauth2-signing-key"` |  |
| global.sbi.oauth2.tokenRefreshMarginS | int | `30` |  |
| global.sbi.oauth2.tokenValiditySeconds | int | `3600` |  |
| global.sbi.tls.certManager.duration | string | `"8760h"` |  |
| global.sbi.tls.certManager.renewBefore | string | `"720h"` |  |
| global.sbi.tls.enabled | bool | `true` |  |
| global.sbi.tls.helm.caDays | int | `3650` |  |
| global.sbi.tls.helm.certDays | int | `825` |  |
| global.sbi.tls.requireClientCert | bool | `true` |  |
| global.sbi.tls.secretPrefix | string | `"sbi-tls"` |  |
| global.sbi.tls.source | string | `"helm"` |  |
| global.sbi.tls.verifyPeer | bool | `true` |  |
| global.timezone | string | `"Europe/Paris"` |  |
| hooks.dbUpgrade.enabled | bool | `true` |  |
| hooks.dbUpgrade.timeoutSeconds | int | `180` |  |
| hooks.enabled | bool | `true` |  |
| hooks.postDelete.enabled | bool | `true` |  |
| hooks.postDelete.image | string | `""` |  |
| hooks.postDelete.timeoutSeconds | int | `90` |  |
| hooks.postFlight.apiImage | string | `""` |  |
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
| ims.credentials.cxDbPassword | string | `""` |  |
| ims.credentials.existingSecret | string | `""` |  |
| ims.credentials.kamailioDbPassword | string | `""` |  |
| ims.cxGateway.allowedPeers | string | `""` |  |
| ims.cxGateway.cxSot | string | `"udr"` |  |
| ims.cxGateway.dropWildcardAccount | bool | `false` |  |
| ims.cxGateway.enabled | bool | `true` |  |
| ims.cxGateway.hostNetwork | bool | `true` |  |
| ims.cxGateway.image | string | `"ims-cx-gateway"` |  |
| ims.cxGateway.imageOverride | string | `""` |  |
| ims.cxGateway.imageTag | string | `"v6.x-rc-02-0535d42f"` |  |
| ims.cxGateway.ip | string | `""` |  |
| ims.cxGateway.mode | string | `"split"` |  |
| ims.cxGateway.port | int | `3868` |  |
| ims.cxGateway.resources.limits.cpu | string | `"500m"` |  |
| ims.cxGateway.resources.limits.memory | string | `"512Mi"` |  |
| ims.cxGateway.resources.requests.cpu | string | `"100m"` |  |
| ims.cxGateway.resources.requests.memory | string | `"256Mi"` |  |
| ims.dbAccountHost | string | `""` |  |
| ims.enabled | bool | `true` |  |
| ims.engine | string | `"kamailio"` |  |
| ims.icscf.bindPort | int | `4060` |  |
| ims.icscf.hostNetwork | bool | `true` |  |
| ims.icscf.ip | string | `""` |  |
| ims.image | string | `"kamailio-ims"` |  |
| ims.imageOverride | string | `""` |  |
| ims.imageTag | string | `"v6.x-rc-02-0535d42f"` |  |
| ims.mysqlHost | string | `""` |  |
| ims.pcscf.alternative.bindPort | string | `""` |  |
| ims.pcscf.alternative.enabled | bool | `false` |  |
| ims.pcscf.alternative.ip | string | `""` |  |
| ims.pcscf.alternative.ipsecClientPort | string | `""` |  |
| ims.pcscf.alternative.ipsecServerPort | string | `""` |  |
| ims.pcscf.alternative.pcfHttpVersion | string | `""` |  |
| ims.pcscf.alternative.pcfUri | string | `""` |  |
| ims.pcscf.bindPort | int | `5060` |  |
| ims.pcscf.hostNetwork | bool | `true` |  |
| ims.pcscf.ip | string | `""` |  |
| ims.pcscf.ipsecClientPort | int | `5100` |  |
| ims.pcscf.ipsecServerPort | int | `6100` |  |
| ims.pcscf.privileged | bool | `true` |  |
| ims.priorityClassName | string | `"firecell-prio-support"` |  |
| ims.registrationExpires | string | `"3600"` |  |
| ims.resources.limits.cpu | string | `"2000m"` |  |
| ims.resources.limits.memory | string | `"2Gi"` |  |
| ims.resources.requests.cpu | string | `"250m"` |  |
| ims.resources.requests.memory | string | `"512Mi"` |  |
| ims.rtpengine.enabled | bool | `false` |  |
| ims.rtpengine.ip | string | `"127.0.0.1"` |  |
| ims.rxN5Iwf.allowedPeers | string | `""` |  |
| ims.rxN5Iwf.diameterPort | int | `3868` |  |
| ims.rxN5Iwf.enabled | bool | `false` |  |
| ims.rxN5Iwf.epcDomain | string | `""` |  |
| ims.rxN5Iwf.image | string | `"rx-n5-iwf"` |  |
| ims.rxN5Iwf.imageOverride | string | `""` |  |
| ims.rxN5Iwf.imageTag | string | `"v6.x-rc-02-0535d42f"` |  |
| ims.rxN5Iwf.logLevel | string | `"INFO"` |  |
| ims.rxN5Iwf.notifyPort | int | `8080` |  |
| ims.rxN5Iwf.notifyUri | string | `""` |  |
| ims.rxN5Iwf.nrf.nfInstanceId | string | `""` |  |
| ims.rxN5Iwf.nrf.register | bool | `false` |  |
| ims.rxN5Iwf.nrf.uri | string | `""` |  |
| ims.rxN5Iwf.originHost | string | `""` |  |
| ims.rxN5Iwf.pcfHttpVersion | string | `""` |  |
| ims.rxN5Iwf.pcfTimeoutS | int | `5` |  |
| ims.rxN5Iwf.pcfUri | string | `""` |  |
| ims.rxN5Iwf.resources.limits.cpu | string | `"500m"` |  |
| ims.rxN5Iwf.resources.limits.memory | string | `"256Mi"` |  |
| ims.rxN5Iwf.resources.requests.cpu | string | `"50m"` |  |
| ims.rxN5Iwf.resources.requests.memory | string | `"64Mi"` |  |
| ims.rxN5Iwf.rxRegEnabled | bool | `false` |  |
| ims.rxN5Iwf.state.maxAgeS | int | `86400` |  |
| ims.rxN5Iwf.state.size | string | `"64Mi"` |  |
| ims.rxN5Iwf.state.storageClassName | string | `"local-path"` |  |
| ims.rxN5Iwf.state.volume | string | `"emptyDir"` |  |
| ims.scscf.bindPort | int | `6060` |  |
| ims.scscf.hostNetwork | bool | `true` |  |
| ims.scscf.ip | string | `""` |  |
| ims.scscf.pcscfDownSeconds | string | `""` |  |
| ims.sidecar.enabled | bool | `false` |  |
| ims.sidecar.image | string | `"nms-ims-sidecar"` |  |
| ims.sidecar.imageOverride | string | `""` |  |
| ims.sidecar.imageTag | string | `"latest"` |  |
| ims.sidecar.resources.limits.cpu | string | `"200m"` |  |
| ims.sidecar.resources.limits.memory | string | `"128Mi"` |  |
| ims.sidecar.resources.requests.cpu | string | `"50m"` |  |
| ims.sidecar.resources.requests.memory | string | `"64Mi"` |  |
| ims.sipConf | string | `"[general]\nlanguage=en\ntcpenable=yes\ntcpbindaddr=0.0.0.0\ntcpbindport=5060\nsrvlookup=yes\n"` |  |
| ims.strictSecrets | bool | `false` |  |
| ims.ueImsSubnet | string | `"14.1.1.0/25"` |  |
| ims.upfN6Gateway | string | `""` |  |
| ims.usersConf | string | `""` |  |
| mysql.database | string | `"oai_db"` |  |
| mysql.enabled | bool | `true` |  |
| mysql.extraInitSql | string | `""` |  |
| mysql.image | string | `"mysql:8.4"` |  |
| mysql.imageOverride | string | `"docker.io/library/mysql:8.4"` |  |
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
| nef.config.interfaceName | string | `"eth0"` |  |
| nef.config.monitoringEventEnabled | bool | `true` |  |
| nef.config.nrf.discoverAmf | bool | `false` |  |
| nef.config.nrf.hostname | string | `"oai-nrf"` |  |
| nef.config.nrf.port | int | `8080` |  |
| nef.config.nrf.register | bool | `true` |  |
| nef.config.peers.amf.hostname | string | `"oai-amf"` |  |
| nef.config.peers.amf.http2Port | int | `8080` |  |
| nef.config.peers.amf.port | int | `8080` |  |
| nef.config.peers.smf.hostname | string | `"oai-smf"` |  |
| nef.config.peers.smf.http2Port | int | `8080` |  |
| nef.config.peers.smf.port | int | `8080` |  |
| nef.config.peers.udm.hostname | string | `"oai-udm"` |  |
| nef.config.peers.udm.http2Port | int | `8080` |  |
| nef.config.peers.udm.port | int | `8080` |  |
| nef.config.sbiHttp2Port | int | `8080` |  |
| nef.config.sbiPort | int | `80` |  |
| nef.config.useHttp2 | bool | `false` |  |
| nef.enabled | bool | `true` |  |
| nef.fcaps.datastore.file | string | `"cm.json"` |  |
| nef.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| nef.fcaps.datastore.size | string | `"128Mi"` |  |
| nef.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| nef.fcaps.enabled | bool | `false` |  |
| nef.fcaps.intentConfigMap.name | string | `"oai-nef-cm-intent"` |  |
| nef.fcaps.intentConfigMap.optional | bool | `true` |  |
| nef.fcaps.intentMode | string | `"configmap"` |  |
| nef.fcaps.mnsPort | int | `9091` |  |
| nef.image | string | `"cn5g-nef"` |  |
| nef.imageOverride | string | `""` |  |
| nef.imageTag | string | `"v6.x-rc-02-643513b8"` |  |
| nef.priorityClassName | string | `"firecell-prio-normal"` |  |
| nef.resources.limits.cpu | string | `"1000m"` |  |
| nef.resources.limits.memory | string | `"1Gi"` |  |
| nef.resources.requests.cpu | string | `"100m"` |  |
| nef.resources.requests.memory | string | `"256Mi"` |  |
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
| nms.namespace | string | `"firecell-nms"` | Namespace of the firecell-nms release: the RBAC subject, and the namespace networkPolicies.allowNmsNamespace admits. |
| nms.rbac | bool | `true` | Let ServiceAccount nms of the firecell-nms release read pods and logs, write intent ConfigMaps, and restart, stop and start the NF Deployments (AMF, SMF, PCF, UDR, UDM, NRF, AUSF, UDSF and every UPF instance) here. |
| nms.sbiClientCert | object | `{"enabled":true,"secretName":"sbi-tls-nms"}` | SBI client certificate for the NMS-NG (mutual TLS to the PCF, UDR, NRF and AMF): with global.sbi.tls.source helm, the chart signs CN firecell-nms with its CA and writes Secret secretName (tls.crt, tls.key, ca.crt) into the NMS namespace; an upgrade keeps it (lookup). Only if that namespace exists: else it is skipped, NOTES says so, and a helm upgrade after the NMS namespace exists adds it (helm template never renders it: no lookup there). source secrets: make it yourself (gen-sbi-certs.sh, then a Secret in the NMS namespace). FIXME(limitation): source certManager has no NMS certificate: the chart's Issuer is namespaced (sbi-ca in the core namespace), and an NMS Certificate would need a ClusterIssuer backed by the CA. |
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
| nrf.image | string | `"cn5g-nrf"` |  |
| nrf.imageOverride | string | `""` |  |
| nrf.imageTag | string | `"v6.x-rc-02-1d130774"` |  |
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
| nssf.config.apiVersion | string | `"v2"` |  |
| nssf.config.http1Port | int | `80` |  |
| nssf.config.http2Port | int | `8080` |  |
| nssf.config.interfaceName | string | `"eth0"` |  |
| nssf.config.logLevel | string | `""` |  |
| nssf.config.nrf.port | string | `""` |  |
| nssf.config.nrf.register | bool | `true` |  |
| nssf.config.sliceConfig | object | `{}` |  |
| nssf.enabled | bool | `false` |  |
| nssf.image | string | `"cn5g-nssf"` |  |
| nssf.imageOverride | string | `""` |  |
| nssf.imageTag | string | `"v6.x-rc-02-d9f7b4ad"` |  |
| nssf.priorityClassName | string | `"firecell-prio-normal"` |  |
| nssf.resources.limits.cpu | string | `"500m"` |  |
| nssf.resources.limits.memory | string | `"512Mi"` |  |
| nssf.resources.requests.cpu | string | `"100m"` |  |
| nssf.resources.requests.memory | string | `"128Mi"` |  |
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
| pcf.image | string | `"cn5g-pcf"` |  |
| pcf.imageOverride | string | `""` |  |
| pcf.imageTag | string | `"v6.x-rc-02-26c302d3"` |  |
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
| smf.image | string | `"cn5g-smf"` |  |
| smf.imageOverride | string | `""` |  |
| smf.imageTag | string | `"v6.x-rc-02-2aefe25d"` |  |
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
| udm.extraSuciProfiles | list | `[]` | More SUCI home network profiles, next to the one from coreConfig.udm.suci* (TS 33.501 Annex C.3). Each entry: `id` = the home network public key ID the UE sends (the UDM has no fallback when it matches no profile), `scheme` = 1 (Profile A, X25519) or 2 (Profile B, P-256), `key` = PKCS#8 PEM private key. Each key is stored in ConfigMap oai-udm-config as suci-<id>.pem (like suciKey) and mounted at /openair-udm/etc/suci-<id>.pem. Empty (default): only the single profile, as before. Example:   extraSuciProfiles:     - id: 11       scheme: 1       key: |         -----BEGIN PRIVATE KEY-----         ...         -----END PRIVATE KEY----- |
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
| udm.image | string | `"cn5g-udm"` |  |
| udm.imageOverride | string | `""` |  |
| udm.imageTag | string | `"v6.x-rc-02-54d302a9"` |  |
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
| udr.image | string | `"cn5g-udr"` |  |
| udr.imageOverride | string | `""` |  |
| udr.imageTag | string | `"v6.x-rc-02-775aa976"` |  |
| udr.ports[0].containerPort | int | `8080` |  |
| udr.ports[0].name | string | `"http"` |  |
| udr.ports[0].protocol | string | `"TCP"` |  |
| udr.priorityClassName | string | `"firecell-prio-crit"` |  |
| udr.resources.limits.cpu | string | `"2000m"` |  |
| udr.resources.limits.memory | string | `"2Gi"` |  |
| udr.resources.requests.cpu | string | `"500m"` |  |
| udr.resources.requests.memory | string | `"512Mi"` |  |
| udr.waitForMysql | bool | `true` |  |
| udsf.enabled | bool | `true` |  |
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
| udsf.image | string | `"cn5g-udsf"` |  |
| udsf.imageOverride | string | `""` |  |
| udsf.imageTag | string | `"v6.x-rc-02-a7ca93e8"` |  |
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
| upf.configSchema | string | `"mr97"` |  |
| upf.datapathInit.n6GatewayArpIntervalSec | int | `5` |  |
| upf.datapathInit.n6GatewayArpRetries | int | `60` |  |
| upf.datapathInit.n6GatewayNdRetries | int | `12` |  |
| upf.deleteSessionsOnSmfRestart | string | `""` |  |
| upf.dnsSearchDomains[0] | string | `"firecell-core.svc.cluster.local"` |  |
| upf.dnsSearchDomains[1] | string | `"svc.cluster.local"` |  |
| upf.dnsSearchDomains[2] | string | `"cluster.local"` |  |
| upf.dnsServers[0] | string | `"10.152.183.10"` |  |
| upf.enableBpfDatapath | bool | `true` |  |
| upf.enableFramedRouting | bool | `false` |  |
| upf.enableSnat | bool | `true` |  |
| upf.enabled | bool | `true` |  |
| upf.ethDlBroadcastEnabled | bool | `true` |  |
| upf.ethDlFloodMaxCopies | int | `50` |  |
| upf.fcaps.datastore.file | string | `"cm.json"` |  |
| upf.fcaps.datastore.mountPath | string | `"/var/lib/firecell/cm"` |  |
| upf.fcaps.datastore.size | string | `"128Mi"` |  |
| upf.fcaps.datastore.storageClassName | string | `"local-path"` |  |
| upf.fcaps.enabled | bool | `false` |  |
| upf.fcaps.intentConfigMap.name | string | `"oai-upf-cm-intent"` |  |
| upf.fcaps.intentConfigMap.optional | bool | `true` |  |
| upf.fcaps.intentMode | string | `"configmap"` |  |
| upf.fcaps.measPeriodSec | int | `5` |  |
| upf.fcaps.mnsPort | int | `9091` |  |
| upf.fcaps.notifyIntervalSec | int | `5` |  |
| upf.fcaps.seedConfigPath | string | `"/openair-upf/etc/config.yaml"` |  |
| upf.gtpuErrorIndicationRestartHoldoffS | string | `""` |  |
| upf.hostNetwork | bool | `true` |  |
| upf.hostPfcpIP | string | `""` |  |
| upf.hostPfcpMacvlan | string | `""` |  |
| upf.injectCiliumPodRoute | bool | `true` |  |
| upf.instances | list | `[]` |  |
| upf.multus.enableBpfDatapath | bool | `false` |  |
| upf.multus.enabled | bool | `false` |  |
| upf.multus.n3.arpWarmIPs | list | `[]` |  |
| upf.multus.n3.cniType | string | `"macvlan"` |  |
| upf.multus.n3.ip | string | `""` |  |
| upf.multus.n3.masterInterface | string | `""` |  |
| upf.multus.n3.mode | string | `"bridge"` |  |
| upf.multus.n3.nadName | string | `"upf-n3-net"` |  |
| upf.multus.n3.subnetPrefix | int | `24` |  |
| upf.multus.n6.cniType | string | `"macvlan"` |  |
| upf.multus.n6.ip | string | `""` |  |
| upf.multus.n6.masterInterface | string | `""` |  |
| upf.multus.n6.mode | string | `"bridge"` |  |
| upf.multus.n6.nadName | string | `"upf-n6-net"` |  |
| upf.multus.n6.subnetPrefix | int | `24` |  |
| upf.multus.rpsCpus | string | `""` |  |
| upf.n3IP | string | `"198.51.100.101"` |  |
| upf.n3Interface | string | `"eth1"` |  |
| upf.n4Interface | string | `"eth0"` |  |
| upf.n6Cidr | string | `""` |  |
| upf.n6Interface | string | `""` |  |
| upf.n6Ipv6Cidr | string | `""` |  |
| upf.n9Interface | string | `""` |  |
| upf.oaiEnableEthPdu | bool | `false` |  |
| upf.oaiHostNet.smfN4Interface | string | `""` |  |
| upf.oaiHostNet.stubInterface | string | `""` |  |
| upf.oaiImage | string | `"cn5g-upf"` |  |
| upf.oaiImageOverride | string | `""` |  |
| upf.oaiImageTag | string | `"v6.x-rc-02-31eeb618"` |  |
| upf.pfcpHost | string | `""` |  |
| upf.pfcpNodeIdFqdn | string | `""` |  |
| upf.privileged | bool | `true` |  |
| upf.remoteN6Gw | string | `""` |  |
| upf.remoteN6GwIpv6 | string | `""` |  |
| upf.resources.limits.cpu | string | `"1000m"` |  |
| upf.resources.limits.memory | string | `"1Gi"` |  |
| upf.resources.requests.cpu | string | `"200m"` |  |
| upf.resources.requests.memory | string | `"512Mi"` |  |
| upf.sbiInterface | string | `""` |  |
| upf.serviceType | string | `"LoadBalancer"` |  |
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
