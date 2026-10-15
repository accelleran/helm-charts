{{/*
Expand the name of the chart.
*/}}
{{- define "firecell-nms.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "firecell-nms.labels" -}}
helm.sh/chart: {{ include "firecell-nms.name" . }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: firecell-nms
{{- end }}

{{/*
In-cluster URLs of the chart's own Services. Names are fixed, not derived
from the release name, so other releases can rely on them.
*/}}
{{- define "firecell-nms.backend.url" -}}
{{- printf "http://nms-api.%s.svc.cluster.local:8080" .Release.Namespace }}
{{- end }}

{{- define "firecell-nms.victoriaMetrics.url" -}}
{{- printf "http://nms-victoria-metrics.%s.svc.cluster.local:8430" .Release.Namespace }}
{{- end }}

{{- define "firecell-nms.backend.dbHost" -}}
{{- printf "nms-db.%s.svc.cluster.local" .Release.Namespace }}
{{- end }}

{{/*
A southbound 5GC URL: the value when set, else the NF's HTTP API in rbac.coreNamespace.
Usage: include "firecell-nms.backend.coreUrl" (list . "udr" "oai-udr")
*/}}
{{- define "firecell-nms.backend.coreUrl" -}}
{{- $root := index . 0 }}
{{- $key := index . 1 }}
{{- $service := index . 2 }}
{{- index $root.Values.backend.endpoints $key | default (printf "http://%s.%s.svc.cluster.local:8080" $service $root.Values.rbac.coreNamespace) }}
{{- end }}

{{- define "firecell-nms.backend.secretName" -}}
{{- required "backend.existingSecret is required: name the Secret holding the backend credentials (see README)" .Values.backend.existingSecret }}
{{- end }}

{{/*
Secret-backed environment. The FIRECELL_NMS_NG_ prefix is the backend's own.
Usage: include "firecell-nms.backend.secretEnv" (list . (dict "DATABASE_URL" "database-url"))
*/}}
{{- define "firecell-nms.backend.secretEnv" -}}
{{- $root := index . 0 }}
{{- range $name, $key := index . 1 }}
- name: FIRECELL_NMS_NG_{{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ include "firecell-nms.backend.secretName" $root }}
      key: {{ $key }}
{{- end }}
{{- end }}

{{/*
Environment of every long-running backend process. The rest comes from the
nms-config ConfigMap.
*/}}
{{- define "firecell-nms.backend.env" -}}
{{- include "firecell-nms.backend.secretEnv" (list . (dict "DATABASE_URL" "database-url" "API_TOKENS_JSON" "api-tokens-json")) }}
{{- with .Values.backend.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Rolls the backend pods when the rendered configuration changes: config and
endpoints both land in these ConfigMaps.
*/}}
{{- define "firecell-nms.backend.checksum" -}}
checksum/config: {{ include (print .Template.BasePath "/backend/configmap.yaml") . | sha256sum }}
{{- end }}

{{- define "firecell-nms.backend.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: 10001
runAsGroup: 10001
fsGroup: 10001
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "firecell-nms.backend.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}

{{/*
Init container that holds a pod until the control plane has migrated the
schema to the revision this image expects. The backend refuses to start
against any other revision.
*/}}
{{- define "firecell-nms.backend.waitForSchema" -}}
- name: wait-for-schema
  image: {{ .Values.backend.image | quote }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  command:
    - python
    - -c
    - |
      import os, time
      from nms_backend.platform.migrations import current_revision, head_revision
      url, head = os.environ["FIRECELL_NMS_NG_DATABASE_URL"], head_revision()
      while True:
          try:
              current = current_revision(url)
          except Exception as exc:
              # The type only: the message can carry connection details.
              current = "unreachable (%s)" % type(exc).__name__
          if current == head:
              break
          print("schema at %s, waiting for %s" % (current, head), flush=True)
          time.sleep(5)
  securityContext:
    {{- include "firecell-nms.backend.containerSecurityContext" . | nindent 4 }}
  env:
    {{- include "firecell-nms.backend.secretEnv" (list . (dict "DATABASE_URL" "database-url")) | nindent 4 }}
  volumeMounts:
    - {name: tmp, mountPath: /tmp}
  resources:
    {{- toYaml .Values.backend.initResources | nindent 4 }}
{{- end }}
