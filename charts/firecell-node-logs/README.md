# firecell-node-logs

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v1.53.0](https://img.shields.io/badge/AppVersion-v1.53.0-informational?style=flat-square)

Firecell per-node log stores - a VictoriaLogs store and a vlagent collector on every Kubernetes node, queried by the NMS on demand

## 1. Architectural Role

Every Kubernetes node keeps the container logs of its own pods. On each node the chart runs:

- a [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/) single-node store, which keeps the logs on the node's disk (`store.hostPath`, default `/var/lib/firecell/vlogs/<profile>`), and
- [vlagent](https://docs.victoriametrics.com/victorialogs/vlagent/), which reads the stdout and stderr of every container on the node from the kubelet's log files (`/var/log/pods`, `/var/log/containers`) and sends them only to the store on the same node.

Nothing leaves a node until someone asks: the [`firecell-nms`](../firecell-nms) backend queries the stores of the nodes it needs when it builds a support bundle. With `centralCopy.enabled`, vlagent also sends every line to a central VictoriaLogs.

Install one release per cluster. Object names are fixed, not derived from the release name, so the NMS can rely on them.

### 1.1 Objects

| Object | Name | Purpose |
|--------|------|---------|
| DaemonSet | `vlogs-node-<profile>` | One store per node, one DaemonSet per enabled profile. Pods carry `app.kubernetes.io/name: vlogs-node` and `firecell.io/log-profile: <profile>`. |
| ConfigMap | `vlogs-node-<profile>-env` | The profile's retention as VictoriaLogs environment flags. Its checksum is in the pod template, so a change rolls that profile's stores. |
| Service | `vlogs-node` (headless, port 9428) | Every store. The NMS maps a node to its store from the EndpointSlices of this Service (each endpoint carries `nodeName`). |
| Service | `vlogs-local` (port 9428, `internalTrafficPolicy: Local`) | Where vlagent writes: `http://vlogs-local.<namespace>.svc:9428/insert/native`. Only the store on the sending node answers. |
| DaemonSet | `vlagent` | The collector, on every node. Checkpoints and send buffer under `vlagent.hostPath` (default `/var/lib/firecell/vlagent`). |
| ServiceAccount, ClusterRole, ClusterRoleBinding | `vlagent`, `vlagent-<namespace>` | get, list, watch on pods, nodes and namespaces, for the container metadata. |
| Role, RoleBinding | `nms-log-stores` | ServiceAccount `nms` in `nms.namespace`: get and list on EndpointSlices, Services and DaemonSets in this namespace. |
| NetworkPolicy | `vlogs-node` | Port 9428 of the stores accepts vlagent, the `nms.namespace` namespace and `networkPolicy.extraFrom` only. |

## 2. Profiles and Retention

A store keeps one retention for everything it holds, so nodes that need a different retention use a different profile. A node picks its profile with a label:

```sh
kubectl label node <node> firecell.io/log-profile=small
```

- `defaultProfile` (`standard`) runs on every node that has no `firecell.io/log-profile` label, or whose label names no other enabled profile. A single-node cluster needs no label.
- Every other enabled profile runs only on nodes labelled with its name.
- So each node runs exactly one store. Relabelling a node moves it to another store; the old store's directory stays on the node (`<store.hostPath>/<old profile>`) until you delete it.

| Profile | Retention | Disk limit |
|---------|-----------|------------|
| `standard` | 7d | 5GiB |
| `small` | 3d | 2GiB |

Each profile sets:

- `retentionPeriod`: logs older than this are deleted. At least `1d`; units `h`, `d`, `w`, `M`, `y`.
- `diskLimit.kind: bytes` with a size (`5GiB`), or `diskLimit.kind: percent` with the highest use (1-100) of the filesystem holding the store. VictoriaLogs drops the oldest days first when the limit is reached. The two are exclusive; any other kind fails the render.
- `resources`, and `nodeSelector` for extra node labels.

To add a profile, add a key under `profiles` (a DNS label of at most 40 characters) with the same fields. The NMS changes retention by writing a values override for this release (with Flux, a ConfigMap merged through the HelmRelease `valuesFrom`); the store DaemonSet of that profile then rolls, and vlagent buffers on disk while a store restarts.

## 3. Collection

vlagent collects every container except those matched by `collect.excludeFilter`, a [LogsQL filter](https://docs.victoriametrics.com/victorialogs/vlagent/#filtering-kubernetes-logs) on container metadata. The default skips pods with the annotation `firecell.io/log-exclude: "true"`:

```yaml
metadata:
  annotations:
    firecell.io/log-exclude: "true"
```

The filter can also name namespaces, containers or labels, e.g. `kubernetes.pod_namespace:in("kube-system") or "kubernetes.pod_annotations.firecell.io/log-exclude":="true"`. Quote field names that contain `/` or `-`. vlagent reads pod metadata when the pod starts, so annotate the pod template, not a running pod.

`collect.extraFields` adds fixed fields to every line, e.g. a site name.

## 4. Placement

- Neither DaemonSet requests whole CPUs, and the chart refuses a whole-CPU request: the pods stay in the shared CPU pool, away from the cores the static CPU manager isolates for the RAN.
- Both tolerate `node-role.firecell/ran` (`tolerations`), so RAN nodes keep their logs too.
- `priorityClassName` is empty by default. Set it to a class below the RAN and core workloads only if that class exists before this chart is installed.
- vlagent is not privileged. It runs as root, with every capability dropped, to read the kubelet's log files, which it mounts read-only.

## 5. Configuration Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| centralCopy.enabled | bool | `false` | Also send every line to centralCopy.url. vlagent buffers for it separately, so an unreachable central store does not hold up the local one. |
| centralCopy.url | string | `""` | Central VictoriaLogs insert URL, ending in `/insert/native`. |
| collect.excludeFilter | string | `"\"kubernetes.pod_annotations.firecell.io/log-exclude\":=\"true\""` | LogsQL filter on container metadata: matching containers are not collected at all. The default skips pods annotated `firecell.io/log-exclude: "true"`. Fields: kubernetes.pod_namespace, kubernetes.pod_name, kubernetes.container_name, kubernetes.pod_labels.<label>, kubernetes.pod_annotations.<annotation>, kubernetes.namespace_labels.<label>, kubernetes.node_labels.<label>. Quote field names that contain `/` or `-`. Empty collects everything. |
| collect.extraFields | object | `{}` | Fields added to every collected line, e.g. `{site: lab-1}`. |
| defaultProfile | string | `"standard"` | Profile that runs on nodes not labelled for another enabled profile. |
| global.imagePullPolicy | string | `"IfNotPresent"` | Pull policy of every image in the chart. |
| global.imagePullSecrets | list | `[]` | Pull secrets of every pod in the chart, e.g. `[{name: registry-secret}]`. |
| global.imageRegistry | string | `""` | Registry (host[:port][/path]) replacing every image's registry, keeping its repository path. Empty: each image's own registry. |
| networkPolicy.enabled | bool | `true` | Let only vlagent and the NMS namespace (and extraFrom) reach the stores on port 9428. |
| networkPolicy.extraFrom | list | `[]` | More NetworkPolicyPeers allowed to the stores, e.g. a monitoring namespace that scrapes /metrics. |
| nms.namespace | string | `"firecell-nms"` | Namespace of the firecell-nms release. Its ServiceAccount `nms` may list the store endpoints here, and the NetworkPolicy lets that namespace reach the stores. |
| priorityClassName | string | `""` | PriorityClass of the store and vlagent pods. Empty: none. Use a class below the RAN and core workloads, and one that exists before this chart is installed (a missing class makes every pod fail admission). |
| profiles.small.diskLimit.kind | string | `"bytes"` | `bytes` or `percent`, see profiles.standard.diskLimit.kind. |
| profiles.small.diskLimit.value | string | `"2GiB"` | Disk limit, see kind. |
| profiles.small.enabled | bool | `true` | Render this profile's DaemonSet. |
| profiles.small.nodeSelector | object | `{}` | Extra node labels a node must also have (ANDed with the profile rule). |
| profiles.small.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"10m","memory":"64Mi"}}` | Store resources. Never request whole CPUs. |
| profiles.small.retentionPeriod | string | `"3d"` | Logs older than this are deleted. |
| profiles.standard.diskLimit.kind | string | `"bytes"` | `bytes`: value is a size (e.g. 5GiB). `percent`: value is the highest use (1-100) of the filesystem holding the store. The oldest days are dropped first when the limit is reached. |
| profiles.standard.diskLimit.value | string | `"5GiB"` | Disk limit, see kind. |
| profiles.standard.enabled | bool | `true` | Render this profile's DaemonSet. |
| profiles.standard.nodeSelector | object | `{}` | Extra node labels a node must also have (ANDed with the profile rule). |
| profiles.standard.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"20m","memory":"96Mi"}}` | Store resources. Never request whole CPUs: with the static CPU manager that would take isolated cores away from the RAN. |
| profiles.standard.retentionPeriod | string | `"7d"` | Logs older than this are deleted. A number and a unit: h, d, w, M or y; at least 1d. |
| store.extraArgs | list | `[]` | Extra VictoriaLogs flags, e.g. `["-search.maxQueryDuration=120s"]`. Retention flags do not belong here: they come from the profile. |
| store.hostPath | string | `"/var/lib/firecell/vlogs"` | Host directory of the store data; each profile uses `<hostPath>/<profile>`. The data survives pod restarts and chart upgrades. |
| store.image.digest | string | `""` | Optional. When set, used as registry/repository@digest instead of :tag. |
| store.image.registry | string | `"docker.io"` | Image registry host. Replaced by global.imageRegistry when set. |
| store.image.repository | string | `"victoriametrics/victoria-logs"` | Image repository path, including the org (kept when the registry is rewritten). |
| store.image.tag | string | `"v1.53.0"` | Image tag. |
| store.terminationGracePeriodSeconds | int | `60` | Seconds the store gets to flush its data on shutdown. |
| tolerations | list | `[{"key":"node-role.firecell/ran","operator":"Exists"}]` | Tolerations of the store and vlagent pods. Both must run on every node, RAN nodes included, or that node's logs are not kept. |
| vlagent.extraArgs | list | `[]` | Extra vlagent flags. |
| vlagent.hostPath | string | `"/var/lib/firecell/vlagent"` | Host directory of the read checkpoints and the send buffer. Both survive restarts, so a restarted vlagent goes on where it stopped. |
| vlagent.image.digest | string | `""` | Optional. When set, used as registry/repository@digest instead of :tag. |
| vlagent.image.registry | string | `"docker.io"` | Image registry host. Replaced by global.imageRegistry when set. |
| vlagent.image.repository | string | `"victoriametrics/vlagent"` | Image repository path, including the org (kept when the registry is rewritten). |
| vlagent.image.tag | string | `"v1.53.0"` | Image tag. |
| vlagent.maxDiskUsagePerURL | string | `"256MiB"` | Largest send buffer per destination while a store is unreachable (e.g. during its rolling restart). The oldest buffered logs are dropped first. |
| vlagent.memoryAllowedBytes | string | `"24MiB"` | Memory vlagent may use for caches (`-memory.allowedBytes`). Empty: the VictoriaMetrics default. |
| vlagent.resources | object | `{"limits":{"cpu":"250m","memory":"192Mi"},"requests":{"cpu":"10m","memory":"48Mi"}}` | vlagent resources. Never request whole CPUs. |
| vlagent.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":false,"runAsUser":0}` | vlagent container securityContext. It runs as root to read the kubelet's log files, without privileges or capabilities. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
