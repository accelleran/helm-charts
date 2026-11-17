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

{{/*
Read-only rules support bundles need in the core and the RAN namespace:
events, and the workloads with their rollout history (ReplicaSets) and
managedFields. Never Secrets.
*/}}
{{- define "firecell-nms.backend.supportReadRules" -}}
- apiGroups: [""]
  resources: ["events"]
  verbs: ["list"]
# An element's URL names a Service; where it is not named like its workload,
# its selector finds the element's pods.
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["get", "list"]
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
Build a container image reference.
Usage: include "firecell-nms.image" (dict "global" .Values.global "image" .Values.front.image "name" "front.image")
global.imageRegistry replaces image.registry when set. digest, when set,
replaces the tag: registry/repository@digest.
*/}}
{{- define "firecell-nms.image" -}}
{{- $name := .name | default "image" -}}
{{- $img := .image | required (printf "firecell-nms: %s is required" $name) -}}
{{- if kindIs "string" $img -}}
{{- fail (printf "firecell-nms: %s must be a map with registry, repository and tag, not a full image string" $name) -}}
{{- end -}}
{{- $registry := .global.imageRegistry | default $img.registry | required (printf "firecell-nms: set %s.registry or global.imageRegistry" $name) -}}
{{- $repository := $img.repository | required (printf "firecell-nms: %s.repository is required" $name) -}}
{{- if $img.digest -}}
{{- printf "%s/%s@%s" $registry $repository $img.digest -}}
{{- else -}}
{{- $tag := $img.tag | required (printf "firecell-nms: %s.tag is required (or set %s.digest)" $name $name) -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}
{{- end -}}

{{- define "firecell-nms.backend.image" -}}
{{- include "firecell-nms.image" (dict "global" .Values.global "image" .Values.backend.image "name" "backend.image") -}}
{{- end -}}

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
  image: {{ include "firecell-nms.backend.image" .root | quote }}
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

{{/*
What nms-api and nms-worker need to call fc-acs: its in-cluster URL and the
northbound token, mounted from the generated Secret fc-acs. Only with acs.enabled.
*/}}
{{- define "firecell-nms.acs.clientEnv" -}}
{{- if .Values.acs.enabled }}
- name: FIRECELL_NMS_NG_ACS_URL
  value: "http://fc-acs:8080"
- name: FIRECELL_NMS_NG_ACS_TOKEN_FILE
  value: /etc/firecell-nms/acs/northbound-token
{{- end }}
{{- end }}

{{- define "firecell-nms.acs.clientMount" -}}
{{- if .Values.acs.enabled }}
- {name: acs-token, mountPath: /etc/firecell-nms/acs, readOnly: true}
{{- end }}
{{- end }}

{{- define "firecell-nms.acs.clientVolume" -}}
{{- if .Values.acs.enabled }}
- name: acs-token
  secret:
    secretName: fc-acs
    items:
      - {key: northbound-token, path: northbound-token}
    defaultMode: 0440
{{- end }}
{{- end }}

{{/*
One auth setting: the value when set, else a key of backend.auth.configMap.
Usage: include "firecell-nms.backend.authValue" (list . "OIDC_PROJECT_ID" .Values.backend.auth.projectId "project-id")
*/}}
{{- define "firecell-nms.backend.authValue" -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $value := index . 2 }}
{{- $key := index . 3 }}
{{- $cm := $root.Values.backend.auth.configMap }}
- name: FIRECELL_NMS_NG_{{ $name }}
{{- if $value }}
  value: {{ $value | quote }}
{{- else if $cm }}
  valueFrom:
    configMapKeyRef:
      name: {{ $cm }}
      key: {{ $key }}
{{- else }}
{{- fail (printf "backend.auth: set the value for FIRECELL_NMS_NG_%s or backend.auth.configMap" $name) }}
{{- end }}
{{- end }}

{{/*
JWT-mode environment of the API container (backend.auth). Empty when off.
*/}}
{{- define "firecell-nms.backend.authEnv" -}}
{{- $auth := .Values.backend.auth }}
{{- if $auth.enabled }}
{{- if .Values.backend.config.trustGatewayHeaders }}
{{- fail "backend.auth.enabled and backend.config.trustGatewayHeaders cannot both be on: the API validates the Zitadel token instead of believing the gateway headers" }}
{{- end }}
- name: FIRECELL_NMS_NG_OIDC_ISSUER_URL
  value: {{ required "backend.auth.issuer is required when backend.auth.enabled" $auth.issuer | quote }}
{{- with $auth.jwksUrl }}
- name: FIRECELL_NMS_NG_OIDC_JWKS_URL
  value: {{ . | quote }}
{{- end }}
{{- include "firecell-nms.backend.authValue" (list . "OIDC_PROJECT_ID" $auth.projectId "project-id") }}
{{- include "firecell-nms.backend.authValue" (list . "OIDC_CLIENT_IDS_JSON" (ternary ($auth.clientIds | toJson) "" (gt (len $auth.clientIds) 0)) "client-ids-json") }}
{{- include "firecell-nms.backend.authValue" (list . "OIDC_INTROSPECTION_CLIENT_ID" $auth.introspection.clientId "introspection-client-id") }}
- name: FIRECELL_NMS_NG_OIDC_INTROSPECTION_KEY_FILE
  value: /etc/firecell-nms/oidc/introspection/{{ $auth.introspection.key }}
- name: FIRECELL_NMS_NG_OIDC_INTROSPECTION_CACHE_SECONDS
  value: {{ $auth.introspection.cacheSeconds | quote }}
{{- if $auth.caBundle.existingSecret }}
- name: FIRECELL_NMS_NG_OIDC_CA_FILE
  value: /etc/firecell-nms/oidc/ca/{{ $auth.caBundle.key }}
{{- end }}
- name: FIRECELL_NMS_NG_OP_REVEAL_MAX_AUTH_AGE_SECONDS
  value: {{ $auth.opRevealMaxAuthAgeSeconds | quote }}
{{- $um := $auth.userManagement }}
{{- if $um.enabled }}
- name: FIRECELL_NMS_NG_ZITADEL_API_URL
  value: {{ $um.apiUrl | default $auth.issuer | quote }}
{{- include "firecell-nms.backend.authValue" (list . "ZITADEL_USERS_ORG_ID" $um.usersOrgId "users-org-id") }}
{{- include "firecell-nms.backend.authValue" (list . "ZITADEL_PROJECT_ORG_ID" $um.projectOrgId "project-org-id") }}
{{- include "firecell-nms.backend.authValue" (list . "ZITADEL_PROJECT_GRANT_ID" $um.projectGrantId "project-grant-id") }}
- name: FIRECELL_NMS_NG_ZITADEL_SERVICE_ACCOUNT_KEY_FILE
  value: /etc/firecell-nms/oidc/user-manager/{{ $um.key }}
{{- end }}
{{- else if $auth.userManagement.enabled }}
{{- fail "backend.auth.userManagement.enabled needs backend.auth.enabled" }}
{{- end }}
{{- end }}

{{/*
Mounts and volumes for backend.auth, API container only.
*/}}
{{- define "firecell-nms.backend.authMounts" -}}
{{- $auth := .Values.backend.auth }}
{{- if $auth.enabled }}
- {name: oidc-introspection, mountPath: /etc/firecell-nms/oidc/introspection, readOnly: true}
{{- if $auth.caBundle.existingSecret }}
- {name: oidc-ca, mountPath: /etc/firecell-nms/oidc/ca, readOnly: true}
{{- end }}
{{- if $auth.userManagement.enabled }}
- {name: oidc-user-manager, mountPath: /etc/firecell-nms/oidc/user-manager, readOnly: true}
{{- end }}
{{- end }}
{{- end }}

{{- define "firecell-nms.backend.authVolumes" -}}
{{- $auth := .Values.backend.auth }}
{{- if $auth.enabled }}
- name: oidc-introspection
  secret:
    secretName: {{ required "backend.auth.introspection.existingSecret is required when backend.auth.enabled" $auth.introspection.existingSecret }}
    defaultMode: 0440
    items:
      - {key: {{ $auth.introspection.key }}, path: {{ $auth.introspection.key }}}
{{- if $auth.caBundle.existingSecret }}
- name: oidc-ca
  secret:
    secretName: {{ $auth.caBundle.existingSecret }}
    defaultMode: 0444
    items:
      - {key: {{ $auth.caBundle.key }}, path: {{ $auth.caBundle.key }}}
{{- end }}
{{- if $auth.userManagement.enabled }}
- name: oidc-user-manager
  secret:
    secretName: {{ required "backend.auth.userManagement.existingSecret is required when backend.auth.userManagement.enabled" $auth.userManagement.existingSecret }}
    defaultMode: 0440
    items:
      - {key: {{ $auth.userManagement.key }}, path: {{ $auth.userManagement.key }}}
{{- end }}
{{- end }}
{{- end }}
