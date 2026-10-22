# firecell-nms

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 6.0.0](https://img.shields.io/badge/AppVersion-6.0.0-informational?style=flat-square)

Firecell NMS — frontend, backend and VictoriaMetrics

## 1. Architectural Role

The Network Management System (NMS) provides the dashboard and the REST API for provisioning and supervising the 5G Core. One release installs all of it; install one release per namespace.

### 1.1 Stack Components

- **Frontend:** React UI served by nginx (`nms-front`). nginx sends `/api/` to the API, `/nms-cm/` to the backend's built-in CM console (`/ui/`), `/metrics-api/` to VictoriaMetrics, and redirects `/grafana/` to `front.grafanaUrl`.
- **Backend:** the API (`nms-api`, two or more replicas), the job workers (`nms-worker`), and exactly one control plane (`nms-control-plane`: supervision, reconciliation, subscriptions, audits).
- **Persistence:** the backend's MySQL (`nms-db`).
- **Metrics:** VictoriaMetrics, where the backend writes PM reports and alarm gauges.

Not included: Grafana (use grafana-operator or any Grafana with a datasource on `nms-victoria-metrics`), an Ingress (route to `nms-front` with your gateway), the namespace, the platform monitor and anything from the 5G Core.

The `firecell-nms-ng-*` commands and the `FIRECELL_NMS_NG_*` environment variables come from the backend itself, so they keep its `ng` naming.

Both images come from the `master` branches of [nms-backend](https://github.com/accelleran/nms-backend) and [nms-frontend](https://github.com/accelleran/nms-frontend). Until there are releases, the defaults are the GHCR `edge-<sha>` builds; releases will be `docker.io/accelleran/nms-backend:X.Y.Z` and `docker.io/accelleran/nms-frontend:X.Y.Z`.

### 1.2 Services

Names are fixed, not derived from the release name, so other releases can rely on them.

| Service | Port | Serves |
|---------|------|--------|
| `nms-front` | 80 | UI, `/nginx-health` (nginx only), `/healthz` (the API's `/healthz` through nginx, no login) |
| `nms-api` | 8080 | API, `/healthz`, FCAPS notification receiver, Grafana alert webhook `/api/alarms/webhook` |
| `nms-db` | 3306 | Backend MySQL |
| `nms-victoria-metrics` | 8430 | VictoriaMetrics (Prometheus API) |

## 2. Before Installation

- Create the release namespace. The chart creates no namespace and renders nothing in `rbac.coreNamespace` (default `firecell-core`) or `rbac.ranNamespace`, so they need not exist yet: the charts deployed into them grant the NMS its access (see [Access to the Core and RAN](#21-access-to-the-core-and-ran)).
- Create the Secret named by `backend.existingSecret` (default `nms-secrets`) in the release namespace. The chart never creates it and has no default credentials.

| Key | Content |
|-----|---------|
| `database-root-password` | MySQL root password. Only MySQL uses it; the backend never connects as root. |
| `database-password` | Password of the backend's MySQL user (`backend.database.user`, default `nms`), which has privileges on `backend.database.name` only. Use URL-safe characters (letters, digits, `. _ ~ -`): it is also part of `database-url`. |
| `database-url` | `mysql+pymysql://<backend.database.user>:<database-password>@nms-db.<namespace>.svc.cluster.local:3306/<backend.database.name>` |
| `network-name` | Name of the managed network, e.g. `firecell`. |
| `op` | Operator variant key: exactly 32 hexadecimal characters. |
| `api-tokens-json` | Non-empty JSON object of machine API tokens, e.g. `{"<token>":{"user":"automation","roles":["operator"]}}`. |
| `default-admin-user` | Local admin login the bootstrap creates when it does not exist yet. |
| `default-admin-password` | Its password. The backend always creates this user and would fall back to `admin`/`admin`, so both keys are required. |

```sh
pw="$(openssl rand -hex 16)"
kubectl -n firecell-nms create secret generic nms-secrets \
  --from-literal=database-root-password="$(openssl rand -hex 16)" \
  --from-literal=database-password="$pw" \
  --from-literal=database-url="mysql+pymysql://nms:${pw}@nms-db.firecell-nms.svc.cluster.local:3306/firecell_nms" \
  --from-literal=network-name=firecell \
  --from-literal=op="$(openssl rand -hex 16)" \
  --from-literal=api-tokens-json="{\"$(openssl rand -hex 24)\":{\"user\":\"automation\",\"roles\":[\"operator\"]}}" \
  --from-literal=default-admin-user=admin@example.com \
  --from-literal=default-admin-password="$(openssl rand -base64 24)"
```

What the Secret changes after the first install:

- A changed Secret rolls no pod. Restart them yourself (`kubectl rollout restart deployment/nms-api deployment/nms-worker statefulset/nms-control-plane`).
- MySQL applies `database-root-password`, the user and `database-password` on its first start only, on an empty `nms-db-data`. To change a password later, change it in MySQL first, then in the Secret.
- Bootstrap never rotates anything: it creates the OP only when the network has none, and the admin only when no user has that login. A new `op` is ignored; a new `default-admin-user` adds a second admin.

### 2.1 Access to the Core and RAN

The backend reads pods, writes intent ConfigMaps, and restarts, stops and starts Deployments in the core and RAN namespaces. The chart ships the rules that apply to a whole namespace as two ClusterRoles, which grant nothing until bound. Each chart deployed into those namespaces binds one of them and grants its own Deployments by name.

| ClusterRole | Rules | Bound by |
|-------------|-------|----------|
| `nms-core-<namespace>` | pods and `pods/status`: get, list, watch; `pods/log`: get; ConfigMaps: get, create, update, patch | the core chart, in `rbac.coreNamespace` |
| `nms-ran-<namespace>` | pods and `pods/status`: get, list, watch | every CU-CP, CU-UP and DU chart, in `rbac.ranNamespace` |

`<namespace>` is the NMS release namespace. Each binding chart renders the following, named after its release, since several CU-CPs, CU-UPs and DUs share the RAN namespace (`<nms-namespace>`, `<release>` and `<deployment>` are placeholders):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: <release>-nms
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nms-ran-<nms-namespace>   # nms-core-<nms-namespace> in the core chart
subjects:
  - kind: ServiceAccount
    name: nms
    namespace: <nms-namespace>
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: <release>-nms-lifecycle
rules:
  # rollout restart patches the pod template; stop and start scale.
  - apiGroups: ["apps"]
    resources: ["deployments", "deployments/scale"]
    resourceNames: [<deployment>]   # every Deployment the chart renders
    verbs: ["get", "patch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: <release>-nms-lifecycle
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: <release>-nms-lifecycle
subjects:
  - kind: ServiceAccount
    name: nms
    namespace: <nms-namespace>
```

Until a chart carries these, the NMS sees no pods in that namespace (element readiness is unknown), and its CM writes, support bundles and lifecycle operations there fail with Forbidden.

## 3. Installation

```sh
helm install firecell-nms accelleran/firecell-nms --namespace firecell-nms --wait --timeout 20m
```

The install completes in one pass, with or without `--wait`, which also makes it safe under Flux helm-controller. There are no Helm hooks:

- The `nms-control-plane` pod runs three init containers. `check-schema` waits until MySQL accepts the backend's credentials. `migrate` then upgrades the schema, and `bootstrap` seeds the catalogue. Both steps are idempotent and run again on every control-plane start.
- The API and worker pods wait in a `wait-for-schema` init container until the schema is at the revision their image expects. The backend refuses to start on any other revision, so post-install hooks would leave `--wait` (and Flux) waiting for pods that can only become ready after the hook.
- The control plane is a StatefulSet of exactly one pod. When the pod is deleted, evicted or drained, its replacement starts only once the old pod is gone, so two control planes, or two migrations, never run at once. A Deployment would start the replacement during the old pod's grace period.
- The API and worker can start between `migrate` and `bootstrap`, before the catalogue is seeded. On a first install they briefly serve an empty network.
- While the database is unreachable, the init containers log the error class and the MySQL error number: 1045 is a wrong user or password, 2003 or 2005 a server that cannot be reached yet. They never log the URL or the password.

Bootstrap seeds the catalogue only when it is empty: `backend.config.seedDnnsJson` and `seedSliceJson` matter on the first install only.

## 4. Upgrades and Rollbacks

- **Migrations run once, before new pods serve.** On an upgrade that changes the backend image, the old control plane stops first. That takes up to `backend.terminationGracePeriodSeconds` (660s by default), while it finishes in-flight work. The new control plane then migrates. New API and worker pods wait for the migrated schema; until then the old pods keep serving.
- **Timeouts.** New API and worker pods can wait for the grace period plus the migration, so their rollout deadline (`backend.progressDeadlineSeconds`, 1200s) must exceed the grace period; the chart refuses to render otherwise. Give `helm upgrade --timeout`, or the HelmRelease `spec.timeout`, at least 20m with the defaults, and more if you raise either value.
- **Rolling the image back across a migration needs a manual schema downgrade.** The backend starts only on exactly its own head revision. An older image on a newer schema stops in `check-schema` / `wait-for-schema`, with `database is at migration <rev>, ahead of this image (head <old head>)`, and stays down. The API pods of the newer image keep serving: with two replicas, the rollout cannot take one away. Downgrade the schema with the newer image, from one of those pods; the older pods then start on their next retry:

  ```sh
  kubectl -n firecell-nms exec deploy/nms-api -c api -- python -c \
    'import os; from nms_backend.platform.migrations import downgrade; downgrade(os.environ["FIRECELL_NMS_NG_DATABASE_URL"], "<old head>")'
  ```

  A downgrade can drop data that the newer schema added. Back up `nms-db-data` first.
- **Keep Flux upgrade remediation off** (`spec.upgrade.remediation`, off by default). An automatic rollback after a failed upgrade that migrated would hit exactly this case. This holds until the backend adopts expand/contract migrations and a compatibility check, instead of exact-head equality.

## 5. Gateway Identity

Behind oauth2-proxy, set `backend.config.trustGatewayHeaders=true` and `networkPolicy.enabled=true` (the first without the second fails the render). The backend then believes `X-Forwarded-User` / `-Groups` without checking a token, so the NetworkPolicies decide who can send them:

- `nms-api`: port 8080 from `nms-front`, oauth2-proxy (`app.kubernetes.io/name: <networkPolicy.oauth2ProxyLabel>`), every pod in `rbac.coreNamespace` (NFs post FCAPS notifications without a token) and `networkPolicy.extraFrom`. Add the Grafana that posts alerts and the platform monitor there.
- `nms-front`: port 80 from oauth2-proxy and `networkPolicy.frontExtraFrom`. nginx forwards the identity headers, so it is closed too.

## 6. Configuration Parameters

The following table lists the configurable parameters of the firecell-nms chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backend.api.replicas | int | `2` | API replicas (at least 2). |
| backend.api.resources.limits.cpu | string | `"1"` |  |
| backend.api.resources.limits.memory | string | `"1Gi"` |  |
| backend.api.resources.requests.cpu | string | `"100m"` |  |
| backend.api.resources.requests.memory | string | `"256Mi"` |  |
| backend.config.allowedWsOriginsJson | string | `"[]"` | JSON string array of allowed WebSocket origins. |
| backend.config.cmConfigMapKey | string | `"cm.json"` |  |
| backend.config.defaultPlmn | string | `"00101"` |  |
| backend.config.defaultSnssaisJson | string | `"[]"` | JSON object array of extra S-NSSAIs given to new subscribers. |
| backend.config.jobRetentionSeconds | int | `604800` | Finished jobs older than this are deleted. 0 keeps everything. |
| backend.config.n3InterfaceName | string | `"any"` | N3 capture interface on the UPF. |
| backend.config.observationRetentionSeconds | int | `604800` | nf_observed rows older than this are deleted (the newest 50 per instance always stay). 0 keeps everything. |
| backend.config.qosMaxRules | int | `4` |  |
| backend.config.qosReconcileIntervalSeconds | int | `30` | How often the operator's PCC rules are re-asserted on the PCF. 0 disables it. |
| backend.config.reconcileTimeoutSeconds | int | `15` |  |
| backend.config.retentionIntervalSeconds | int | `3600` |  |
| backend.config.seedDnnsJson | string | `""` | Level-1 "Data network" instances the bootstrap seeds on an EMPTY catalogue. Pass the DNNs the 5GC chart runs, e.g. `[{"dnn":"oai","ipv4Subnet":"12.1.1.0/25","pduSessionType":"IPV4"}]`. Empty keeps the built-in seed (a DNN called "default"). |
| backend.config.seedSliceJson | string | `""` | The first slice the bootstrap seeds, e.g. `{"sst":1,"sd":"000001"}`. |
| backend.config.southboundTimeoutSeconds | int | `6` |  |
| backend.config.trustGatewayHeaders | bool | `false` | Believe X-Forwarded-User / -Groups from oauth2-proxy. Requires networkPolicy.enabled: the backend does not check tokens on this path. |
| backend.controlPlane.minReadySeconds | int | `20` | Seconds the control plane must stay up before it counts as available (its probes only check that the process lives). |
| backend.controlPlane.resources.limits.cpu | string | `"1"` |  |
| backend.controlPlane.resources.limits.memory | string | `"1Gi"` |  |
| backend.controlPlane.resources.requests.cpu | string | `"100m"` |  |
| backend.controlPlane.resources.requests.memory | string | `"256Mi"` |  |
| backend.database.image | string | `"docker.io/library/mysql:8.0.46"` | Backend MySQL image, as a full reference. |
| backend.database.name | string | `"firecell_nms"` | Database the backend uses; `database-url` must name it. |
| backend.database.resources.limits.cpu | string | `"2"` |  |
| backend.database.resources.limits.memory | string | `"2Gi"` |  |
| backend.database.resources.requests.cpu | string | `"200m"` |  |
| backend.database.resources.requests.memory | string | `"512Mi"` |  |
| backend.database.storage | string | `"10Gi"` | Size of PVC nms-db-data (kept on uninstall). |
| backend.database.user | string | `"nms"` | MySQL user the backend connects as, with privileges on `name` only; `database-url` must name it. Created on the database's first start. |
| backend.endpoints.extdnProbe | string | `""` | ext-dn probe sidecar for device ping (enable extDn.sidecar in firecell-5gc first), e.g. `http://oai-ext-dn.firecell-core.svc.cluster.local:8080`. Empty: the ping routes answer 503. |
| backend.endpoints.ims | string | `""` | IMS API. Empty: `http://ims.<rbac.coreNamespace>.svc.cluster.local:8080`. |
| backend.endpoints.pcf | string | `""` | PCF API. Empty: `http://oai-pcf.<rbac.coreNamespace>.svc.cluster.local:8080`. |
| backend.endpoints.udr | string | `""` | UDR provisioning API. Empty: `http://oai-udr.<rbac.coreNamespace>.svc.cluster.local:8080`. |
| backend.endpoints.victoria | string | `""` | Where PM reports and alarm gauges are written. Empty: the in-chart VictoriaMetrics. Grafana alert rules read core_alarm_active from here and post to /api/alarms/webhook, so without it no alarm arrives. |
| backend.existingSecret | string | `"nms-secrets"` | Secret with the backend credentials, created before install; the chart never creates it. Required keys: `database-root-password`, `database-password`, `database-url`, `network-name`, `op`, `api-tokens-json`, `default-admin-user`, `default-admin-password` (see README). |
| backend.extraEnv | list | `[]` | Extra environment (EnvVar list) for the API, worker and control plane, e.g. FIRECELL_NMS_NG_ALARM_REASSERT_INTERVAL. |
| backend.image | string | `"ghcr.io/accelleran/nms-backend:edge-1501118"` | Backend image (API, worker, control plane, migration and bootstrap), as a full reference. |
| backend.initResources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"50m","memory":"128Mi"}}` | Resources of the check-schema, migrate, bootstrap and wait-for-schema init containers. |
| backend.progressDeadlineSeconds | int | `1200` | Rollout deadline of the API and worker Deployments. New pods wait for the old control plane to stop and the migration to finish, so it must exceed terminationGracePeriodSeconds plus the migration time. Keep the Helm / HelmRelease timeout above it. |
| backend.terminationGracePeriodSeconds | int | `660` | Longer than the backend's slowest lifecycle operation (600s), so workers and the control plane can finish in-flight work after SIGTERM. On an image change the new control plane, and so the migration, starts only after the old one has stopped: up to this long. |
| backend.worker.minReadySeconds | int | `20` | Seconds a new worker must stay up before it counts as available (its probes only check that the process lives). |
| backend.worker.replicas | int | `1` | Worker replicas (at least 1). |
| backend.worker.resources.limits.cpu | string | `"1"` |  |
| backend.worker.resources.limits.memory | string | `"1Gi"` |  |
| backend.worker.resources.requests.cpu | string | `"100m"` |  |
| backend.worker.resources.requests.memory | string | `"256Mi"` |  |
| backend.worker.threads | int | `4` | Job threads per worker. |
| front.backendUrl | string | `""` | Where nginx sends /api/. Empty: the in-chart nms-api Service. |
| front.cmUrl | string | `""` | Where nginx sends /nms-cm/ (the CM console). Empty: the backend's built-in console, `<nms-api>/ui`. |
| front.grafanaUrl | string | `""` | External Grafana base URL (the chart has no Grafana of its own). The UI links to <origin>/grafana/...; /grafana/ redirects there, path and query intact. Empty leaves the location out. |
| front.image | string | `"ghcr.io/accelleran/nms-frontend:edge-db0447e"` | NMS frontend (nginx) image, as a full reference. Needs a CM-enabled build that talks to the new backend. |
| front.metricsUrl | string | `""` | VictoriaMetrics base URL for the Device Performance charts (/metrics-api/ -> <metricsUrl>/api/v1/). Empty: the in-chart VictoriaMetrics. |
| front.resources.limits.cpu | string | `"200m"` |  |
| front.resources.limits.memory | string | `"128Mi"` |  |
| front.resources.requests.cpu | string | `"50m"` |  |
| front.resources.requests.memory | string | `"64Mi"` |  |
| global.imagePullPolicy | string | `"IfNotPresent"` | Pull policy of every image in the chart. |
| global.imagePullSecrets | list | `[]` | Pull secrets of every pod in the chart, e.g. `[{name: ghcr-pull}]`. |
| global.storageClass | string | `"local-path"` | StorageClass of every PVC. Must be non-empty: omitting storageClassName lets the API inject the default StorageClass, and Helm upgrades then try to unset it (immutable field). |
| networkPolicy.enabled | bool | `false` | Restrict who reaches the API (nms-api, port 8080) and nms-front (port 80). Needed for backend.config.trustGatewayHeaders. |
| networkPolicy.extraFrom | list | `[]` | More NetworkPolicyPeers allowed to the API besides nms-front, oauth2-proxy and rbac.coreNamespace: the Grafana that posts alerts to /api/alarms/webhook, the platform monitor that pushes FCAPS. |
| networkPolicy.frontExtraFrom | list | `[]` | More NetworkPolicyPeers allowed to nms-front besides oauth2-proxy, e.g. a landing page that probes /healthz. |
| networkPolicy.oauth2ProxyLabel | string | `"oauth2-proxy"` | app.kubernetes.io/name label of the oauth2-proxy pods in this namespace. |
| rbac.coreNamespace | string | `"firecell-core"` | Namespace of the 5GC NFs: CM intent ConfigMaps, the default southbound URLs and the NetworkPolicy. The chart renders nothing there, so it need not exist yet; the core chart grants the access (see the README). |
| rbac.ranNamespace | string | `""` | Namespace of all the CU-CPs, CU-UPs and DUs when they do not run in coreNamespace. When set, RAN-domain elements are rolled there. The chart renders nothing there; the RAN charts grant the access. |
| victoriaMetrics.image | string | `"docker.io/victoriametrics/victoria-metrics:v1.93.4"` | VictoriaMetrics image, as a full reference. |
| victoriaMetrics.maxConcurrentInserts | int | `16` |  |
| victoriaMetrics.maxLabelsPerTimeseries | int | `50` |  |
| victoriaMetrics.resources.limits.cpu | string | `"500m"` |  |
| victoriaMetrics.resources.limits.memory | string | `"1Gi"` |  |
| victoriaMetrics.resources.requests.cpu | string | `"100m"` |  |
| victoriaMetrics.resources.requests.memory | string | `"256Mi"` |  |
| victoriaMetrics.retentionPeriod | string | `"7d"` |  |
| victoriaMetrics.storage | string | `"20Gi"` | Size of PVC nms-vm-data. |

## 7. Upgrading from 0.1.x

There is no in-place upgrade from 0.1.x: uninstall the 0.1.x release and install this chart fresh. Nothing is migrated from the 0.1.x database.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)

