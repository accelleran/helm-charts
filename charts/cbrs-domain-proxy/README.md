# cbrs-domain-proxy

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.5.0](https://img.shields.io/badge/AppVersion-0.5.0-informational?style=flat-square)

CBRS Domain Proxy - the CBSD-facing gRPC front for the SAS, one per site

## 1. Architectural Role
Deploys the CBRS Domain Proxy (`cbrs-dp`). It talks to a Spectrum Access System (SAS) on behalf of a site's CBRS
radios (CBSDs), which connect to it over gRPC with mutual TLS. Install one release per site; it runs one pod
(`Recreate`), because its store takes a single-writer lock.

### 1.1 Components
| Object | Notes |
|--------|-------|
| Deployment `<release>` | one replica, `Recreate` |
| ConfigMap `<release>-config` | `config.yaml`, rendered from values; do not edit |
| ConfigMap `<release>-allowlist` | the CBSDs the Domain Proxy serves; see [2.3](#23-allowlist) |
| PVC `<release>-store` | the Domain Proxy's state (`/var/lib/cbrs-dp/state.db`) and its CRL cache; kept on uninstall |
| Service `<release>` | `grpc` and `metrics` |
| Role and RoleBinding `<release>-nms-lifecycle` | with `nms.rbac`; see [2.2](#22-nms-access) |

## 2. Install
The image `docker.io/accelleran/cbrs-domain-proxy` is private, so the pod needs a pull secret. It also needs two
TLS Secrets, each holding `tls.crt`, `tls.key` and `ca.crt`: `<release>-sas` (the client certificate for the SAS and
the SAS CA) and `<release>-cbsd` (the server certificate for the CBSDs and the CBSD client CA). Set `sas.secret` and
`grpc.secret` to use other names. Here the release is `dp`, so the Secrets are `dp-sas` and `dp-cbsd`:

```bash
kubectl create namespace cbrs
kubectl -n cbrs create secret docker-registry dockerhub-regcred --docker-server=https://index.docker.io/v1/ \
  --docker-username=<user> --docker-password=<token>
kubectl -n cbrs create secret generic dp-sas \
  --from-file=tls.crt=sas-client.crt --from-file=tls.key=sas-client.key --from-file=ca.crt=sas-ca.crt
kubectl -n cbrs create secret generic dp-cbsd \
  --from-file=tls.crt=dp-server.crt --from-file=tls.key=dp-server.key --from-file=ca.crt=cbsd-ca.crt
helm install --repo https://accelleran.github.io/helm-charts dp cbrs-domain-proxy -n cbrs \
  --set sas.url=https://sas.example/v1.2 --set sas.userId=<user> \
  --set 'imagePullSecrets[0].name=dockerhub-regcred'
```

From a checkout of this repository, use the chart path instead: `helm install dp ./charts/cbrs-domain-proxy ...`.

The Domain Proxy reads its TLS files at start: restart it after replacing a Secret.

### 2.1 Uninstall
`helm uninstall` leaves the PVC `<release>-store` and the ConfigMap `<release>-allowlist`: deleting the store makes
every CBSD register again and drops its Grants. A new release with the same name and namespace picks both up. To start
from scratch, delete them by hand.

### 2.2 NMS Access
With `nms.rbac` (the default), the release grants ServiceAccount `nms` of the [`firecell-nms`](../firecell-nms)
release in `nms.namespace` get and patch on Deployment `<release>` (restart) and on ConfigMap `<release>-allowlist`,
by name only.

### 2.3 Allowlist
Only the CBSDs in `<release>-allowlist` (key `allowlist.yaml`) are served. The chart writes `allowlist` into it when
the ConfigMap does not exist yet; after that the NMS owns it and upgrades keep the live content. A change reaches the
Domain Proxy within about a minute (the kubelet's ConfigMap sync, then the Domain Proxy's 10 s reread).

- `helm rollback` writes the list stored with the target revision. Once the NMS has written the ConfigMap, Helm v4
  (server-side apply) refuses that as a conflict unless you pass `--force-conflicts`, which keeps the old list until
  the NMS writes it again.
- Tools that render with `helm template` (e.g. Argo CD) cannot see the live ConfigMap and reset it to `allowlist` on
  every sync.

## 3. Configuration Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| allowlist | list | `[]` | CBSDs (`fcc_id`, `serial_number`) written to `<release>-allowlist` at first install. See "Allowlist" in the README. |
| grpc.port | int | `50051` | CBSD-facing gRPC port (container and Service). |
| grpc.secret | string | `""` | Secret with tls.crt, tls.key and ca.crt (the CBSD client CA) for the CBSD-facing mTLS server. Empty uses `<release>-cbsd`. |
| image | string | `""` | Image reference. Empty uses `docker.io/accelleran/cbrs-domain-proxy:<appVersion>`. Development builds are on `ghcr.io/accelleran/cbrs-domain-proxy` (`edge-<sha>`, `pr-<n>`). |
| imagePullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| imagePullSecrets | list | `[]` | Image pull secrets for the pod. |
| metrics.port | int | `9464` | Port of the Prometheus endpoint (plain HTTP, `/metrics`), on the container and the Service. The NMS raises the Domain Proxy alarms from it. |
| nms.namespace | string | `"firecell-nms"` | Namespace of the firecell-nms release. |
| nms.rbac | bool | `true` | Let the NMS restart this Deployment and patch the allowlist ConfigMap (get and patch, both by name). |
| nodeSelector | object | `{}` | Node selector for the pod. |
| sas.secret | string | `""` | Secret with tls.crt, tls.key and ca.crt for the SAS-facing mTLS client. Empty uses `<release>-sas`. Replace the files and restart to rotate. |
| sas.url | string | `""` | SAS URL (https). Required. Pinned in the store: changing it later needs a fresh store. |
| sas.userId | string | `""` | SAS user ID. Required. Pinned in the store like the URL. |
| store.size | string | `"100Mi"` | Size of the PVC holding the registration and Grant store. |
| store.storageClass | string | `""` | Storage class of the PVC. Empty uses the cluster default. |
| tolerations | list | `[]` | Tolerations for the pod. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
