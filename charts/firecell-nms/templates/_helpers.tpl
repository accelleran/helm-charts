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
Init container that checks the schema against this image's migrations. It
waits while the database is unreachable and fails when the database is at a
revision this image does not know: a newer image migrated it, and the backend
only starts on exactly its own head. With untilHead it also waits until the
control plane has migrated to that head (API, worker); without it, it lets
the control plane go on to migrate.
Usage: include "firecell-nms.backend.schemaCheck" (dict "root" . "name" "wait-for-schema" "untilHead" true)
*/}}
{{- define "firecell-nms.backend.schemaCheck" -}}
- name: {{ .name }}
  image: {{ .root.Values.backend.image | quote }}
  imagePullPolicy: {{ .root.Values.global.imagePullPolicy }}
  command:
    - python
    - -c
    - |
      import os, sys, time
      from alembic.script import ScriptDirectory
      from nms_backend.platform.migrations import alembic_config, current_revision
      until_head = {{ if .untilHead }}True{{ else }}False{{ end }}
      script = ScriptDirectory.from_config(alembic_config("sqlite://"))
      head, url = script.get_current_head(), os.environ["FIRECELL_NMS_NG_DATABASE_URL"]
      def known(revision):
          try:
              return script.get_revision(revision) is not None
          except Exception:
              return False
      while True:
          try:
              current = current_revision(url)
          except Exception as exc:
              # The MySQL error number only: the message names the user and host.
              args = getattr(getattr(exc, "orig", None), "args", ())
              code = ", MySQL error %d" % args[0] if args and isinstance(args[0], int) else ""
              print("database unreachable (%s%s)" % (type(exc).__name__, code), flush=True)
              time.sleep(5)
              continue
          if current is not None and not known(current):
              sys.exit(
                  "database is at migration %s, ahead of this image (head %s). Roll forward "
                  "to the newer image, or downgrade the schema with the newer image first "
                  "(see the chart README)." % (current, head)
              )
          if current == head or not until_head:
              print("schema at %s, image head %s" % (current or "none", head), flush=True)
              break
          print("schema at %s, waiting for %s" % (current or "none", head), flush=True)
          time.sleep(5)
  securityContext:
    {{- include "firecell-nms.backend.containerSecurityContext" .root | nindent 4 }}
  env:
    {{- include "firecell-nms.backend.secretEnv" (list .root (dict "DATABASE_URL" "database-url")) | nindent 4 }}
  volumeMounts:
    - {name: tmp, mountPath: /tmp}
  resources:
    {{- toYaml .root.Values.backend.initResources | nindent 4 }}
{{- end }}
