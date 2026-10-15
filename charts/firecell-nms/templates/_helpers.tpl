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
app.kubernetes.io/version: {{ .Values.global.pkgVersion | quote }}
app.kubernetes.io/part-of: firecell-nms
{{- end }}

{{/*
In-cluster URLs of the chart's own Services. Names are fixed, not derived
from the release name, so other releases can rely on them.
*/}}
{{- define "firecell-nms.nmsNg.url" -}}
{{- printf "http://nms-ng.%s.svc.cluster.local:8080" .Release.Namespace }}
{{- end }}

{{- define "firecell-nms.victoriaMetrics.url" -}}
{{- printf "http://nms-victoria-metrics.%s.svc.cluster.local:8430" .Release.Namespace }}
{{- end }}

{{- define "firecell-nms.nmsNg.dbHost" -}}
{{- printf "nms-ng-db.%s.svc.cluster.local" .Release.Namespace }}
{{- end }}

{{/*
A southbound 5GC URL: the value when set, else the NF's HTTP API in coreNamespace.
Usage: include "firecell-nms.nmsNg.coreUrl" (list . "udr" "oai-udr")
*/}}
{{- define "firecell-nms.nmsNg.coreUrl" -}}
{{- $root := index . 0 }}
{{- $key := index . 1 }}
{{- $service := index . 2 }}
{{- index $root.Values.nmsNg.endpoints $key | default (printf "http://%s.%s.svc.cluster.local:8080" $service $root.Values.nmsNg.coreNamespace) }}
{{- end }}

{{- define "firecell-nms.nmsNg.secretName" -}}
{{- required "nmsNg.existingSecret is required: name the Secret holding the nms-ng credentials (see README)" .Values.nmsNg.existingSecret }}
{{- end }}

{{- define "firecell-nms.nmsNg.secretEnv" -}}
{{- $root := index . 0 }}
{{- range $name, $key := index . 1 }}
- name: FIRECELL_NMS_NG_{{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ include "firecell-nms.nmsNg.secretName" $root }}
      key: {{ $key }}
{{- end }}
{{- end }}

{{/*
Environment of every long-running nms-ng process. The rest comes from the
nms-ng-config ConfigMap.
*/}}
{{- define "firecell-nms.nmsNg.env" -}}
{{- include "firecell-nms.nmsNg.secretEnv" (list . (dict "DATABASE_URL" "database-url" "API_TOKENS_JSON" "api-tokens-json")) }}
{{- with .Values.nmsNg.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Rolls the nms-ng pods when the rendered configuration changes: config and
endpoints both land in these ConfigMaps.
*/}}
{{- define "firecell-nms.nmsNg.checksum" -}}
checksum/config: {{ include (print .Template.BasePath "/nms-ng/configmap.yaml") . | sha256sum }}
{{- end }}

{{- define "firecell-nms.nmsNg.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: 10001
runAsGroup: 10001
fsGroup: 10001
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "firecell-nms.nmsNg.containerSecurityContext" -}}
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
{{- define "firecell-nms.nmsNg.waitForSchema" -}}
- name: wait-for-schema
  image: {{ .Values.nmsNg.image | quote }}
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
    {{- include "firecell-nms.nmsNg.containerSecurityContext" . | nindent 4 }}
  env:
    {{- include "firecell-nms.nmsNg.secretEnv" (list . (dict "DATABASE_URL" "database-url")) | nindent 4 }}
  volumeMounts:
    - {name: tmp, mountPath: /tmp}
  resources:
    {{- toYaml .Values.nmsNg.initResources | nindent 4 }}
{{- end }}
