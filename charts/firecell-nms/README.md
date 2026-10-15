# firecell-nms

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 5.0.1](https://img.shields.io/badge/AppVersion-5.0.1-informational?style=flat-square)

Firecell NMS — Network Management System (Kubernetes-native, Consul-free)

## 1. Architectural Role
The Network Management System (NMS) provides the central dashboard and REST API for provisioning the 5G Core.

### 1.1 Stack Components
- **Frontend:** React-based UI served via Nginx.
- **Backend:** Flask REST API (`nms-api`).
- **Persistence:** MySQL (`nms-db`) and Redis (`redis-cache`).
- **Monitoring:** VictoriaMetrics and Grafana.

## 2. Configuration Parameters
The following table lists the configurable parameters of the Firecell-nms chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| api.enabled | bool | `true` | Set false to skip the Flask API (nms-ng cutover). |
| api.image | string | `"nms-backend"` |  |
| api.mailPort | int | `465` |  |
| api.mailServer | string | `"smtp.gmail.com"` |  |
| api.resources.limits.cpu | string | `"1000m"` |  |
| api.resources.limits.memory | string | `"1Gi"` |  |
| api.resources.requests.cpu | string | `"100m"` |  |
| api.resources.requests.memory | string | `"256Mi"` |  |
| db.enabled | bool | `true` | Set false to skip chart MySQL (nms-ng cutover). |
| db.database | string | `"firecell_nms_api"` |  |
| db.image | string | `"mysql:8.0.31"` |  |
| db.resources.limits.cpu | string | `"1000m"` |  |
| db.resources.limits.memory | string | `"1Gi"` |  |
| db.resources.requests.cpu | string | `"300m"` |  |
| db.resources.requests.memory | string | `"512Mi"` |  |
| db.storage | string | `"10Gi"` |  |
| db.user | string | `"firecell_nms_user"` |  |
| front.backendUrl | string | `"http://nms-api:5001"` | nginx `/api/` upstream. |
| front.cmUrl | string | `""` | Optional CM console proxy. |
| front.grafanaUrl | string | `""` | Optional external Grafana redirect. |
| front.image | string | `"nms-frontend"` |  |
| front.metricsUrl | string | `""` | Optional VictoriaMetrics PromQL proxy. |
| front.resources.limits.cpu | string | `"200m"` |  |
| front.resources.limits.memory | string | `"128Mi"` |  |
| front.resources.requests.cpu | string | `"50m"` |  |
| front.resources.requests.memory | string | `"64Mi"` |  |
| global.imagePullPolicy | string | `"IfNotPresent"` |  |
| global.imagePullSecrets[0].name | string | `"gitlab-regcred"` |  |
| global.imageRegistry | string | `"registry.gitlab.com/firecell/r-d/firecellrd"` |  |
| global.namespace | string | `"firecell-nms"` |  |
| global.pkgVersion | string | `"6.0.0"` |  |
| global.storageClass | string | `"local-path"` |  |
| global.timezone | string | `"Europe/Paris"` |  |
| grafana.image | string | `"ue-monitoring-graphana:stable"` |  |
| grafana.replicas | int | `1` | Set 0 to skip in-chart Grafana (no PVC). |
| grafana.resources.limits.cpu | string | `"500m"` |  |
| grafana.resources.limits.memory | string | `"512Mi"` |  |
| grafana.resources.requests.cpu | string | `"100m"` |  |
| grafana.resources.requests.memory | string | `"128Mi"` |  |
| grafana.storage | string | `"2Gi"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-read-timeout" | string | `"300"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-send-timeout" | string | `"300"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect" | string | `"true"` |  |
| ingress.className | string | `"nginx"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hostname | string | `"nms.example.com"` |  |
| ingress.tls.enabled | bool | `true` |  |
| ingress.tls.secretName | string | `"nms-tls"` |  |
| redis.image | string | `"redis:stable"` |  |
| redis.resources.limits.cpu | string | `"200m"` |  |
| redis.resources.limits.memory | string | `"256Mi"` |  |
| redis.resources.requests.cpu | string | `"50m"` |  |
| redis.resources.requests.memory | string | `"64Mi"` |  |
| redis.storage | string | `"1Gi"` |  |
| victoriaMetrics.image | string | `"ue-monitoring-victoria-metrics:stable"` |  |
| victoriaMetrics.maxConcurrentInserts | int | `16` |  |
| victoriaMetrics.maxLabelsPerTimeseries | int | `50` |  |
| victoriaMetrics.resources.limits.cpu | string | `"500m"` |  |
| victoriaMetrics.resources.limits.memory | string | `"1Gi"` |  |
| victoriaMetrics.resources.requests.cpu | string | `"100m"` |  |
| victoriaMetrics.resources.requests.memory | string | `"256Mi"` |  |
| victoriaMetrics.retentionPeriod | string | `"7d"` |  |
| victoriaMetrics.storage | string | `"20Gi"` |  |

## 3. Maintenance & Troubleshooting
- Ensure `nms-secrets` is pre-created before installation.
- Ingress requires an Nginx Ingress Controller.
- Set `grafana.replicas=0` when Grafana is provided by an operator (skips the Grafana PVC).
- Set `api.enabled=false` and `db.enabled=false` for the nms-ng cutover.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
