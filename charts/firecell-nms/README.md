# firecell-nms

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 6.0.0](https://img.shields.io/badge/AppVersion-6.0.0-informational?style=flat-square)

Firecell NMS — frontend, nms-ng backend and VictoriaMetrics

## 1. Architectural Role

The Network Management System (NMS) provides the dashboard and the REST API for provisioning and supervising the 5G Core. One release installs all of it; install one release per namespace.

### 1.1 Stack Components

- **Frontend:** React UI served by nginx (`nms-front`). nginx sends `/api/` to nms-ng, `/nms-cm/` to the nms-ng built-in CM console (`/ui/`), `/metrics-api/` to VictoriaMetrics, and redirects `/grafana/` to `front.grafanaUrl`.
- **Backend:** nms-ng: the API (two or more replicas), the job workers, and exactly one control plane (supervision, reconciliation, subscriptions, audits).
- **Persistence:** the nms-ng MySQL (`nms-ng-db`).
- **Metrics:** VictoriaMetrics, where nms-ng writes PM reports and alarm gauges.

Not included: Grafana (use grafana-operator or any Grafana with a datasource on `nms-victoria-metrics`), an Ingress (route to `nms-front` with your gateway), the namespace, the platform monitor and anything from the 5G Core.

### 1.2 Services

Names are fixed, not derived from the release name, so other releases can rely on them.

| Service | Port | Serves |
|---------|------|--------|
| `nms-front` | 80 | UI; `/api/health_check` for probes |
| `nms-ng` | 8080 | API, FCAPS notification receiver, Grafana alert webhook `/api/alarms/webhook` |
| `nms-ng-db` | 3306 | nms-ng MySQL |
| `nms-victoria-metrics` | 8430 | VictoriaMetrics (Prometheus API) |

## 2. Before Installation

- Create the release namespace and `nmsNg.coreNamespace` (default `firecell-core`), plus `nmsNg.ranNamespace` when set. The chart renders Roles there and creates no namespace.
- Create the Secret named by `nmsNg.existingSecret` (default `nms-ng-secrets`) in the release namespace. The chart never creates it and has no default credentials.

| Key | Content |
|-----|---------|
| `database-root-password` | MySQL root password, applied on the database's first start only. Use URL-safe characters (letters, digits, `. _ ~ -`): it is also part of `database-url`. |
| `database-url` | `mysql+pymysql://root:<database-root-password>@nms-ng-db.<namespace>.svc.cluster.local:3306/<nmsNg.database.name>` |
| `network-name` | Name of the managed network, e.g. `firecell`. |
| `op` | Operator variant key: exactly 32 hexadecimal characters. |
| `api-tokens-json` | Non-empty JSON object of machine API tokens, e.g. `{"<token>":{"user":"automation","roles":["operator"]}}`. |
| `default-admin-user` | Local admin login the bootstrap creates when it does not exist yet. |
| `default-admin-password` | Its password. The backend always creates this user and would fall back to `admin`/`admin`, so both keys are required. |

```sh
pw="$(openssl rand -hex 16)"
kubectl -n firecell-nms create secret generic nms-ng-secrets \
  --from-literal=database-root-password="$pw" \
  --from-literal=database-url="mysql+pymysql://root:${pw}@nms-ng-db.firecell-nms.svc.cluster.local:3306/firecell_nms_ng" \
  --from-literal=network-name=firecell \
  --from-literal=op="$(openssl rand -hex 16)" \
  --from-literal=api-tokens-json="{\"$(openssl rand -hex 24)\":{\"user\":\"automation\",\"roles\":[\"operator\"]}}" \
  --from-literal=default-admin-user=admin@example.com \
  --from-literal=default-admin-password="$(openssl rand -base64 24)"
```

A changed Secret does not roll the pods; restart them after rotating a value.

## 3. Installation

```sh
helm install firecell-nms accelleran/firecell-nms --namespace firecell-nms
```

The install completes in one pass, with or without `--wait`, which also makes it safe under Flux helm-controller. There are no Helm hooks:

- The `nms-ng-control-plane` pod (one replica, `Recreate`) waits for MySQL, runs the schema migration, then the catalogue bootstrap, as init containers. Both are idempotent and run again on every control-plane start.
- The API and worker pods wait in a `wait-for-schema` init container until the schema is at the revision their image expects. nms-ng refuses to start on any other revision, so post-install hooks would leave `--wait` (and Flux) waiting for pods that can only become ready after the hook.

On an upgrade that changes the backend image, the old control plane stops first (up to `nmsNg.terminationGracePeriodSeconds`, 660s by default, while it finishes in-flight work), then the new one migrates while the old API pods keep serving. Give the upgrade a timeout above that grace period.

Bootstrap seeds the catalogue only when it is empty: `nmsNg.config.seedDnnsJson` and `seedSliceJson` matter on the first install only.

## 4. Gateway Identity

Behind oauth2-proxy, set `nmsNg.config.trustGatewayHeaders=true` and `nmsNg.networkPolicy.enabled=true` (the first without the second fails the render). nms-ng then believes `X-Forwarded-User` / `-Groups` without checking a token, so the NetworkPolicies decide who can send them:

- `nms-ng-api`: port 8080 from `nms-front`, oauth2-proxy (`app.kubernetes.io/name: <nmsNg.networkPolicy.oauth2ProxyLabel>`), every pod in `nmsNg.coreNamespace` (NFs post FCAPS notifications without a token) and `nmsNg.networkPolicy.extraFrom`. Add the Grafana that posts alerts and the platform monitor there.
- `nms-front`: port 80 from oauth2-proxy and `nmsNg.networkPolicy.frontExtraFrom` (e.g. a landing page probing `/api/health_check`). nginx forwards the identity headers, so it is closed too.

## 5. Configuration Parameters

The following table lists the configurable parameters of the firecell-nms chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| front.backendUrl | string | `""` | Where nginx sends /api/. Empty: the in-chart nms-ng Service. |
| front.cmUrl | string | `""` | Where nginx sends /nms-cm/ (the CM console). Empty: the nms-ng built-in console, `<nms-ng>/ui`. |
| front.grafanaUrl | string | `""` | External Grafana base URL (the chart has no Grafana of its own). The UI links to <origin>/grafana/...; /grafana/ redirects there, path and query intact. Empty leaves the location out. |
| front.image | string | `"ghcr.io/accelleran/nms-frontend:ping-299e22c"` | NMS frontend (nginx) image, as a full reference. Needs a CM-enabled build that talks to nms-ng. |
| front.metricsUrl | string | `""` | VictoriaMetrics base URL for the Device Performance charts (/metrics-api/ -> <metricsUrl>/api/v1/). Empty: the in-chart VictoriaMetrics. |
| front.resources.limits.cpu | string | `"200m"` |  |
| front.resources.limits.memory | string | `"128Mi"` |  |
| front.resources.requests.cpu | string | `"50m"` |  |
| front.resources.requests.memory | string | `"64Mi"` |  |
| global.imagePullPolicy | string | `"IfNotPresent"` | Pull policy of every image in the chart. |
| global.imagePullSecrets | list | `[]` | Pull secrets of every pod in the chart, e.g. `[{name: ghcr-pull}]`. |
| global.storageClass | string | `"local-path"` | StorageClass of every PVC. Must be non-empty: omitting storageClassName lets the API inject the default StorageClass, and Helm upgrades then try to unset it (immutable field). |
| nmsNg.api.replicas | int | `2` | API replicas (at least 2). |
| nmsNg.api.resources.limits.cpu | string | `"1"` |  |
| nmsNg.api.resources.limits.memory | string | `"1Gi"` |  |
| nmsNg.api.resources.requests.cpu | string | `"100m"` |  |
| nmsNg.api.resources.requests.memory | string | `"256Mi"` |  |
| nmsNg.config.allowedWsOriginsJson | string | `"[]"` | JSON string array of allowed WebSocket origins. |
| nmsNg.config.cmConfigMapKey | string | `"cm.json"` |  |
| nmsNg.config.defaultPlmn | string | `"00101"` |  |
| nmsNg.config.defaultSnssaisJson | string | `"[]"` | JSON object array of extra S-NSSAIs given to new subscribers. |
| nmsNg.config.jobRetentionSeconds | int | `604800` | Finished jobs older than this are deleted. 0 keeps everything. |
| nmsNg.config.n3InterfaceName | string | `"any"` | N3 capture interface on the UPF. |
| nmsNg.config.observationRetentionSeconds | int | `604800` | nf_observed rows older than this are deleted (the newest 50 per instance always stay). 0 keeps everything. |
| nmsNg.config.qosMaxRules | int | `4` |  |
| nmsNg.config.qosReconcileIntervalSeconds | int | `30` | How often the operator's PCC rules are re-asserted on the PCF. 0 disables it. |
| nmsNg.config.reconcileTimeoutSeconds | int | `15` |  |
| nmsNg.config.retentionIntervalSeconds | int | `3600` |  |
| nmsNg.config.seedDnnsJson | string | `""` | Level-1 "Data network" instances the bootstrap seeds on an EMPTY catalogue. Pass the DNNs the 5GC chart runs, e.g. `[{"dnn":"oai","ipv4Subnet":"12.1.1.0/25","pduSessionType":"IPV4"}]`. Empty keeps the built-in seed (a DNN called "default"). |
| nmsNg.config.seedSliceJson | string | `""` | The first slice the bootstrap seeds, e.g. `{"sst":1,"sd":"000001"}`. |
| nmsNg.config.southboundTimeoutSeconds | int | `6` |  |
| nmsNg.config.trustGatewayHeaders | bool | `false` | Believe X-Forwarded-User / -Groups from oauth2-proxy. Requires networkPolicy.enabled: nms-ng does not check tokens on this path. |
| nmsNg.controlPlane.resources.limits.cpu | string | `"1"` |  |
| nmsNg.controlPlane.resources.limits.memory | string | `"1Gi"` |  |
| nmsNg.controlPlane.resources.requests.cpu | string | `"100m"` |  |
| nmsNg.controlPlane.resources.requests.memory | string | `"256Mi"` |  |
| nmsNg.coreNamespace | string | `"firecell-core"` | Namespace of the 5GC NFs. The chart renders a Role there, so it must exist before install. |
| nmsNg.database.image | string | `"docker.io/library/mysql:8.0.46"` | nms-ng MySQL image, as a full reference. |
| nmsNg.database.name | string | `"firecell_nms_ng"` | Database the backend uses; `database-url` must name it. |
| nmsNg.database.resources.limits.cpu | string | `"2"` |  |
| nmsNg.database.resources.limits.memory | string | `"2Gi"` |  |
| nmsNg.database.resources.requests.cpu | string | `"200m"` |  |
| nmsNg.database.resources.requests.memory | string | `"512Mi"` |  |
| nmsNg.database.storage | string | `"10Gi"` | Size of PVC nms-ng-db-data (kept on uninstall). |
| nmsNg.endpoints.extdnProbe | string | `""` | ext-dn probe sidecar for device ping (enable extDn.sidecar in firecell-5gc first), e.g. `http://oai-ext-dn.firecell-core.svc.cluster.local:8080`. Empty: the ping routes answer 503. |
| nmsNg.endpoints.ims | string | `""` | IMS API. Empty: `http://ims.<coreNamespace>.svc.cluster.local:8080`. |
| nmsNg.endpoints.pcf | string | `""` | PCF API. Empty: `http://oai-pcf.<coreNamespace>.svc.cluster.local:8080`. |
| nmsNg.endpoints.udr | string | `""` | UDR provisioning API. Empty: `http://oai-udr.<coreNamespace>.svc.cluster.local:8080`. |
| nmsNg.endpoints.victoria | string | `""` | Where PM reports and alarm gauges are written. Empty: the in-chart VictoriaMetrics. Grafana alert rules read core_alarm_active from here and post to /api/alarms/webhook, so without it no alarm arrives. |
| nmsNg.existingSecret | string | `"nms-ng-secrets"` | Secret with the nms-ng credentials, created before install; the chart never creates it. Required keys: `database-root-password`, `database-url`, `network-name`, `op`, `api-tokens-json`, `default-admin-user`, `default-admin-password` (see README). |
| nmsNg.extraEnv | list | `[]` | Extra environment (EnvVar list) for the API, worker and control plane, e.g. FIRECELL_NMS_NG_ALARM_REASSERT_INTERVAL. |
| nmsNg.image | string | `"ghcr.io/accelleran/firecell-nms-backend-ng:master-de7132d"` | nms-ng backend image (API, worker, control plane, migration and bootstrap), as a full reference. |
| nmsNg.initResources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"50m","memory":"128Mi"}}` | Resources of the migrate, bootstrap and wait-for-schema init containers. |
| nmsNg.networkPolicy.enabled | bool | `false` | Restrict who reaches the nms-ng API (port 8080) and nms-front (port 80). Needed for config.trustGatewayHeaders. |
| nmsNg.networkPolicy.extraFrom | list | `[]` | More NetworkPolicyPeers allowed to the API besides nms-front, oauth2-proxy and coreNamespace: the Grafana that posts alerts to /api/alarms/webhook, the platform monitor that pushes FCAPS. |
| nmsNg.networkPolicy.frontExtraFrom | list | `[]` | More NetworkPolicyPeers allowed to nms-front besides oauth2-proxy, e.g. a landing page that probes /api/health_check. |
| nmsNg.networkPolicy.oauth2ProxyLabel | string | `"oauth2-proxy"` | app.kubernetes.io/name label of the oauth2-proxy pods in this namespace. |
| nmsNg.ranNamespace | string | `""` | Namespace of the RAN Deployments (the ocudu DU) when they do not run in coreNamespace. When set, RAN-domain elements are rolled there and a second Role over rbac.ranDeploymentNames is rendered. |
| nmsNg.rbac.deploymentNames | list | `["oai-amf","oai-smf","oai-upf","oai-udr","oai-udm","oai-pcf","oai-nrf","oai-ausf"]` | Deployments in coreNamespace the lifecycle may restart, stop and start. Empty grants no Deployment access. |
| nmsNg.rbac.ranDeploymentNames | list | `[]` | Deployments in ranNamespace the lifecycle may roll (only when ranNamespace is set), e.g. the ocudu DU `du-1`. |
| nmsNg.terminationGracePeriodSeconds | int | `660` | Longer than the backend's slowest lifecycle operation (600s), so workers and the control plane can finish in-flight work after SIGTERM. |
| nmsNg.worker.replicas | int | `1` | Worker replicas (at least 1). |
| nmsNg.worker.resources.limits.cpu | string | `"1"` |  |
| nmsNg.worker.resources.limits.memory | string | `"1Gi"` |  |
| nmsNg.worker.resources.requests.cpu | string | `"100m"` |  |
| nmsNg.worker.resources.requests.memory | string | `"256Mi"` |  |
| nmsNg.worker.threads | int | `4` | Job threads per worker. |
| victoriaMetrics.image | string | `"docker.io/victoriametrics/victoria-metrics:v1.93.4"` | VictoriaMetrics image, as a full reference. |
| victoriaMetrics.maxConcurrentInserts | int | `16` |  |
| victoriaMetrics.maxLabelsPerTimeseries | int | `50` |  |
| victoriaMetrics.resources.limits.cpu | string | `"500m"` |  |
| victoriaMetrics.resources.limits.memory | string | `"1Gi"` |  |
| victoriaMetrics.resources.requests.cpu | string | `"100m"` |  |
| victoriaMetrics.resources.requests.memory | string | `"256Mi"` |  |
| victoriaMetrics.retentionPeriod | string | `"7d"` |  |
| victoriaMetrics.storage | string | `"20Gi"` | Size of PVC nms-vm-data. |

## 6. Upgrading from 0.1.x

0.2.0 replaces the Flask API with nms-ng. Nothing is migrated from the Flask database.

- Before upgrading a release installed with `global.createNamespace=true` (the 0.1.x default), run `kubectl annotate namespace <namespace> helm.sh/resource-policy=keep`. Otherwise Helm deletes the namespace, and everything in it, when it drops the Namespace from the release.
- Removed: `api.*`, `db.*`, `redis.*`, `grafana.*`, `ingress.*`, `cmConsole.*`, `global.namespace`, `global.createNamespace`, `global.imageRegistry`, `global.pkgVersion`, `global.busyboxImage`, `global.timezone`, every `imageOverride` and `imageTag`. `front.image` and `victoriaMetrics.image` now take a full image reference.
- Service `nms-api-victoria-metrics-dev` is now `nms-victoria-metrics`; Services `nms-api`, `db`, `nms-db-headless`, `redis-cache` and `nms-grafana` are gone. Secret `nms-secrets` is no longer read.
- The Flask MySQL PVC (`nms-db-data-nms-db-0`) is left behind; delete it once nothing needs it.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
