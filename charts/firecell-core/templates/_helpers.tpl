{{/*
Expand the name of the chart.
*/}}
{{- define "firecell-5gc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "firecell-5gc.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "firecell-5gc.labels" -}}
helm.sh/chart: {{ include "firecell-5gc.name" . }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.global.pkgVersion | quote }}
app.kubernetes.io/part-of: firecell-5gc
{{- end }}

{{/*
NF-specific labels
*/}}
{{- define "firecell-5gc.nfLabels" -}}
{{ include "firecell-5gc.labels" . }}
app: {{ .nfName }}
tier: core-network
{{- end }}

{{/*
NF selector labels (used in service selectors and deployment matchLabels)
*/}}
{{- define "firecell-5gc.nfSelectorLabels" -}}
app: {{ .nfName }}
{{- end }}

{{/*
Build a full image reference: registry/image:tag
*/}}
{{- define "firecell-5gc.image" -}}
{{- printf "%s/%s:%s" .registry .image .tag }}
{{- end }}

{{/*
Image reference for a cn5g NF: registry/image:imageTag, used as-is. Empty
imageTag falls back to registry/image:<pkgVersion>.
dict: registry, image, imageTag, pkgVersion
*/}}
{{- define "firecell-5gc.nfImage" -}}
{{- if .imageTag -}}
{{- printf "%s/%s:%s" .registry .image .imageTag }}
{{- else -}}
{{- include "firecell-5gc.image" (dict "registry" .registry "image" .image "tag" .pkgVersion) }}
{{- end -}}
{{- end }}

{{/*
OAI nfs.*.host for SBI peers. hostNetwork SMF/UPF must use cluster DNS (not /etc/hosts pod IPs).
dict: ctx (root), name (service short name e.g. oai-udm), clusterDNS (bool)
*/}}
{{/*
A boolean value with a default that an explicit false keeps. Sprig's "default" treats false
as empty, so "x | default true" turned an explicit false into true (helm-charts #1912 review:
ims.pcscf.hostNetwork=false rendered hostNetwork: true).
list: value, default. Unset (nil) or "": the default. Strings false/no/0 (any case): false.
Renders "true" or "false".
*/}}
{{- define "firecell-5gc.flag" -}}
{{- $v := index . 0 -}}
{{- $d := index . 1 -}}
{{- if or (kindIs "invalid" $v) (eq (toString $v) "") -}}{{ ternary "true" "false" (eq (toString $d) "true") }}
{{- else if kindIs "bool" $v -}}{{ ternary "true" "false" $v }}
{{- else if has (lower (toString $v)) (list "false" "no" "0") -}}false
{{- else -}}true
{{- end -}}
{{- end }}

{{/*
The P-CSCF IPv4 address for the SMF (and the hostNetwork UPF config): coreConfig.ims.pcscfIpv4,
else ims.pcscf.ip when the IMS is on, else 0.0.0.0 ("no IPv4 P-CSCF"). Never "": the SMF
refuses an empty value at start.
*/}}
{{- define "firecell-5gc.pcscfIpv4" -}}
{{- $v := .Values -}}
{{- $ip := ($v.coreConfig.ims).pcscfIpv4 | default "" -}}
{{- if and (not $ip) $v.ims.enabled -}}{{- $ip = $v.ims.pcscf.ip | default "" -}}{{- end -}}
{{- $ip | default "0.0.0.0" -}}
{{- end }}

{{- define "firecell-5gc.oaiSbiHost" -}}
{{- $ctx := .ctx -}}
{{- $name := .name -}}
{{- if .clusterDNS -}}
{{- printf "%s.%s.svc.cluster.local" $name $ctx.Values.global.namespace -}}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/*
ConfigMap checksum annotation — triggers pod restart on config change.
Usage: include "firecell-5gc.configChecksum" .
*/}}
{{- define "firecell-5gc.configChecksum" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/healthz: {{ include (print $.Template.BasePath "/healthz-configmap.yaml") . | sha256sum }}
{{- end }}

{{/*
Resolve MySQL root password: explicit non-empty .Values first, then live mysql-secrets via lookup, then "linux".
*/}}
{{- define "firecell-5gc.mysqlRootPassword" -}}
{{- $explicit := coalesce .Values.mysql.rootPassword .Values.coreConfig.database.password -}}
{{- if $explicit -}}
{{- $explicit -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Values.global.namespace "mysql-secrets" -}}
{{- if and $existing $existing.data (hasKey $existing.data "root-password") -}}
{{- index $existing.data "root-password" | b64dec -}}
{{- else -}}
{{- "linux" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Resolve MySQL user: explicit non-empty .Values.mysql.user first, then live mysql-secrets via lookup, then .Values.coreConfig.database.user or "root".
*/}}
{{- define "firecell-5gc.mysqlUser" -}}
{{- if .Values.mysql.user -}}
{{- .Values.mysql.user -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Values.global.namespace "mysql-secrets" -}}
{{- if and $existing $existing.data (hasKey $existing.data "user") -}}
{{- index $existing.data "user" | b64dec -}}
{{- else -}}
{{- coalesce .Values.coreConfig.database.user "root" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Resolve MySQL user password: explicit non-empty .Values first, then live mysql-secrets via lookup, then "linux".
*/}}
{{- define "firecell-5gc.mysqlPassword" -}}
{{- $explicit := coalesce .Values.mysql.password .Values.mysql.rootPassword .Values.coreConfig.database.password -}}
{{- if $explicit -}}
{{- $explicit -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Values.global.namespace "mysql-secrets" -}}
{{- if and $existing $existing.data (hasKey $existing.data "password") -}}
{{- index $existing.data "password" | b64dec -}}
{{- else -}}
{{- "linux" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Resolve OAI coreConfig.database.password: explicit non-empty .Values first, then live mysql-secrets via lookup, then "linux".
*/}}
{{- define "firecell-5gc.databasePassword" -}}
{{- $dbUser := coalesce .Values.coreConfig.database.user .Values.mysql.user "root" -}}
{{- $explicit := "" -}}
{{- if eq $dbUser "root" -}}
  {{- $explicit = coalesce .Values.coreConfig.database.password .Values.mysql.rootPassword .Values.mysql.password -}}
{{- else -}}
  {{- $explicit = coalesce .Values.coreConfig.database.password .Values.mysql.password .Values.mysql.rootPassword -}}
{{- end -}}
{{- if $explicit -}}
{{- $explicit -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Values.global.namespace "mysql-secrets" -}}
{{- if and $existing $existing.data -}}
{{- if and (eq $dbUser "root") (hasKey $existing.data "root-password") -}}
{{- index $existing.data "root-password" | b64dec -}}
{{- else if hasKey $existing.data "password" -}}
{{- index $existing.data "password" | b64dec -}}
{{- else -}}
{{- "linux" -}}
{{- end -}}
{{- else -}}
{{- "linux" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Real liveness probe for OAI control-plane NFs via the healthz sidecar.
*/}}
{{- define "firecell-5gc.nfLivenessProbe" -}}
livenessProbe:
  httpGet:
    path: /health
    port: {{ .healthPort | default 9090 }}
  initialDelaySeconds: {{ .initialDelaySeconds | default 45 }}
  periodSeconds: {{ .periodSeconds | default 10 }}
  failureThreshold: {{ .failureThreshold | default 6 }}
  timeoutSeconds: {{ .timeoutSeconds | default 5 }}
{{- end -}}

{{/*
Init container that waits for NRF to be ready.
*/}}
{{- define "firecell-5gc.waitForNrf" -}}
{{- if .Values.nrf.enabled -}}
- name: wait-for-nrf
  image: {{ .Values.global.busyboxImage | default (printf "%s/busybox:stable" .Values.global.imageRegistry) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  command:
    - /bin/sh
    - -c
    - |
      NRF_PORT="{{ .Values.nrf.sbiPort | default 8080 }}"
      NS="{{ .Values.global.namespace }}"
      echo "Waiting for NRF HTTP port ${NRF_PORT}..."
      until false; do
        DNS=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf 2>/dev/null || true)
        if [ -n "${DNS}" ]; then
          IP=$(nslookup "oai-nrf.${NS}.svc.cluster.local" "${DNS}" 2>/dev/null | awk '/^Address: / { print $2; exit }')
          if [ -n "${IP}" ] && nc -z "${IP}" "${NRF_PORT}" 2>/dev/null; then
            echo "NRF reachable at ${IP}:${NRF_PORT} (cluster DNS)"
            exit 0
          fi
        fi
        for h in "oai-nrf.${NS}.svc.cluster.local" oai-nrf; do
          if nc -z "${h}" "${NRF_PORT}" 2>/dev/null; then
            echo "NRF reachable at ${h}:${NRF_PORT}"
            exit 0
          fi
        done
        echo "NRF not reachable yet, retrying in 3s..."
        sleep 3
      done
{{- end }}
{{- end }}

{{/*
Init container that waits for UDSF SBI when stateless mode is enabled.
*/}}
{{- define "firecell-5gc.waitForUdsf" -}}
- name: wait-for-udsf
  image: {{ .Values.global.busyboxImage | default (printf "%s/busybox:stable" .Values.global.imageRegistry) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  command:
    - /bin/sh
    - -c
    - |
      UDSF_PORT="{{ .Values.udsf.sbiPort | default 8080 }}"
      NS="{{ .Values.global.namespace }}"
      SVC="{{ .Values.udsf.serviceName | default "oai-udsf" }}"
      echo "Waiting for UDSF HTTP port ${UDSF_PORT}..."
      until false; do
        DNS=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf 2>/dev/null || true)
        if [ -n "${DNS}" ]; then
          IP=$(nslookup "${SVC}.${NS}.svc.cluster.local" "${DNS}" 2>/dev/null | awk '/^Address: / { print $2; exit }')
          if [ -n "${IP}" ] && nc -z "${IP}" "${UDSF_PORT}" 2>/dev/null; then
            echo "UDSF reachable at ${IP}:${UDSF_PORT} (cluster DNS)"
            exit 0
          fi
        fi
        for h in "${SVC}.${NS}.svc.cluster.local" "${SVC}.${NS}" "${SVC}"; do
          if nc -z "${h}" "${UDSF_PORT}" 2>/dev/null; then
            echo "UDSF reachable at ${h}:${UDSF_PORT}"
            exit 0
          fi
        done
        echo "UDSF not reachable, retrying in 3s..."
        sleep 3
      done
{{- end }}

{{/*
Sidecar that serves /health (default port 9090) with busybox httpd.
Runs /scripts/check.sh every 2 s; /health returns 200 if it exited 0, 404 otherwise.

Optional dict key healthPort — required when multiple hostNetwork pods share a node.

Usage:
  {{- include "firecell-5gc.healthzSidecar" (dict "Values" .Values "nfName" "amf" "healthPath" "/namf-comm/v1/health") | nindent 8 }}
*/}}
{{- define "firecell-5gc.healthzSidecar" -}}
{{- $healthPort := .healthPort | default 9090 }}
{{- $omitHealthzPort := .omitContainerPort | default false }}
- name: healthz
  image: {{ .Values.global.busyboxImage | default (printf "%s/busybox:stable" .Values.global.imageRegistry) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  env:
    - name: NF_NAME
      value: {{ .nfName | quote }}
    - name: HEALTH_PATH
      value: {{ .healthPath | quote }}
  command:
    - /bin/sh
    - -c
    - |
      # check.sh publishes /tmp/www/health while the NF is healthy; httpd answers
      # 200 for it and 404 when it is absent. httpd forks per request, so the
      # readiness and liveness probes can arrive together (a single nc -l refused
      # the second one, and phase-aligned probes then failed liveness every time).
      mkdir -p /tmp/www
      (
        while true; do
          if sh /scripts/check.sh >/dev/null 2>&1; then
            echo OK > /tmp/www/.health && mv /tmp/www/.health /tmp/www/health
          else
            rm -f /tmp/www/health
          fi
          sleep 2
        done
      ) &
      exec busybox httpd -f -p {{ $healthPort }} -h /tmp/www
  {{- if not $omitHealthzPort }}
  ports:
    - name: healthz
      containerPort: {{ $healthPort }}
      protocol: TCP
  {{- end }}
  volumeMounts:
    - name: healthz-scripts
      mountPath: /scripts
  resources:
    requests:
      memory: 4Mi
      cpu: 5m
    limits:
      memory: 8Mi
      cpu: 10m
{{- end }}

{{/*
Volume for the healthz sidecar scripts ConfigMap.
*/}}
{{- define "firecell-5gc.healthzVolume" -}}
- name: healthz-scripts
  configMap:
    name: healthz-scripts
    defaultMode: 0755
{{- end }}

{{/*
Init container that waits for MySQL to be ready.
HostNetwork IMS (Kamailio/Cx): set ims.mysqlHost to a node/external IP — ClusterIP
"mysql" is unreachable from hostNetwork pods.
*/}}
{{- define "firecell-5gc.waitForMysql" -}}
{{- $dbHost := .Values.ims.mysqlHost | default .Values.coreConfig.database.host | default "mysql" -}}
{{- $dbPort := .Values.coreConfig.database.port | default 3306 -}}
- name: wait-for-mysql
  image: {{ .Values.global.busyboxImage | default (printf "%s/busybox:stable" .Values.global.imageRegistry) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  command:
    - /bin/sh
    - -c
    - |
      echo "Waiting for MySQL ({{ $dbHost }}:{{ $dbPort }}) to be ready..."
      until nc -z "{{ $dbHost }}" {{ $dbPort }}; do
        echo "MySQL not ready, retrying in 5s..."
        sleep 5
      done
      echo "MySQL is ready!"
{{- end }}

{{/*
coreConfig.mcc / mnc as the digit strings the IMS images check (MCC ^[0-9]{3}$, MNC ^[0-9]{2,3}$).
values.yaml quotes them; a number (--set coreConfig.mnc=1, or an unquoted value in a values file)
has lost its leading zeros, so it is padded: MCC to 3 digits, MNC to 2 (1 -> "01", 123 -> "123").
Anything else fails the render.
*/}}
{{- define "firecell-5gc.mcc" -}}
{{- $v := .Values.coreConfig.mcc | default "001" -}}
{{- if or (kindIs "float64" $v) (kindIs "int64" $v) (kindIs "int" $v) -}}
{{- $v = printf "%03d" (int $v) -}}
{{- end -}}
{{- if not (regexMatch "^[0-9]{3}$" (toString $v)) -}}
{{- fail (printf "coreConfig.mcc must be 3 digits, quoted (got %v)" $v) -}}
{{- end -}}
{{- $v -}}
{{- end }}

{{- define "firecell-5gc.mnc" -}}
{{- $v := .Values.coreConfig.mnc | default "01" -}}
{{- if or (kindIs "float64" $v) (kindIs "int64" $v) (kindIs "int" $v) -}}
{{- $v = printf "%02d" (int $v) -}}
{{- end -}}
{{- if not (regexMatch "^[0-9]{2,3}$" (toString $v)) -}}
{{- fail (printf "coreConfig.mnc must be 2 or 3 digits, quoted (got %v)" $v) -}}
{{- end -}}
{{- $v -}}
{{- end }}

{{/*
IMS SIP domain from PLMN (999/99 -> ims.mnc099.mcc999.3gppnetwork.org).
*/}}
{{- define "firecell-5gc.imsDomain" -}}
{{- $mcc := include "firecell-5gc.mcc" . -}}
{{- $mnc := include "firecell-5gc.mnc" . -}}
{{- if eq (len $mnc) 3 -}}
ims.mnc{{ $mnc }}.mcc{{ $mcc }}.3gppnetwork.org
{{- else -}}
ims.mnc0{{ $mnc }}.mcc{{ $mcc }}.3gppnetwork.org
{{- end -}}
{{- end }}

{{/*
Kamailio CSCF common env (UDR MySQL).
*/}}
{{- define "firecell-5gc.kamailioCommonEnv" -}}
- name: COMPONENT_NAME
  value: {{ .component | quote }}
- name: MCC
  value: {{ include "firecell-5gc.mcc" .root | quote }}
- name: MNC
  value: {{ include "firecell-5gc.mnc" .root | quote }}
- name: MYSQL_HOST
  value: {{ .root.Values.ims.mysqlHost | default (printf "mysql.%s.svc.cluster.local" .root.Values.global.namespace) | quote }}
# The root password is used at start only (schema + account), then unset by the
# init; the runtime account password comes from the IMS credentials Secret.
# File form only: the Kamailio init lets a *_FILE win over the variable.
- name: MYSQL_ROOT_PASSWORD_FILE
  value: /run/secrets/ims/root-password
- name: KAMAILIO_DB_PASSWORD_FILE
  value: /run/secrets/ims/kamailio-db-password
{{- with .root.Values.ims.dbAccountHost }}
- name: KAMAILIO_DB_USER_HOST
  value: {{ . | quote }}
{{- end }}
- name: FIRECELL_STRICT_SECRETS
  value: {{ ternary "true" "false" (.root.Values.ims.strictSecrets | default false) | quote }}
- name: REGISTRATION_EXPIRES
  value: {{ .root.Values.ims.registrationExpires | default "3600" | quote }}
- name: IMS_DOMAIN
  value: {{ include "firecell-5gc.imsDomain" .root | quote }}
{{- end }}

{{/*
Cx gateway env shared by its provision init container and its runtime container.
Call with (dict "root" $ "mode" "provision|serve|all" "imsDomain" <domain>).
*/}}
{{- define "firecell-5gc.cxGatewayEnv" -}}
{{- $v := .root.Values -}}
- name: CX_MODE
  value: {{ .mode | quote }}
- name: MYSQL_HOST
  value: {{ $v.ims.mysqlHost | default (printf "mysql.%s.svc.cluster.local" $v.global.namespace) | quote }}
- name: CX_DB_PASSWORD_FILE
  value: /run/secrets/ims/cx-db-password
{{- with $v.ims.dbAccountHost }}
- name: CX_DB_ACCOUNT_HOST
  value: {{ . | quote }}
{{- end }}
{{- with $v.ims.cxGateway.allowedPeers }}
- name: CX_DIAMETER_ALLOWED_PEERS
  value: {{ . | quote }}
{{- end }}
- name: CX_STRICT_SECURITY
  value: {{ ternary "1" "0" ($v.ims.strictSecrets | default false) | quote }}
- name: CX_GATEWAY_IP
  value: {{ $v.ims.cxGateway.ip | quote }}
- name: CX_GATEWAY_PORT
  value: {{ $v.ims.cxGateway.port | default "3868" | quote }}
- name: MCC
  value: {{ include "firecell-5gc.mcc" .root | quote }}
- name: MNC
  value: {{ include "firecell-5gc.mnc" .root | quote }}
- name: IMS_DOMAIN
  value: {{ .imsDomain | quote }}
- name: CX_SOT
  value: {{ $v.ims.cxGateway.cxSot | default "udr" | quote }}
{{- end }}

{{/*
Name of the Secret with the IMS MySQL account passwords (keys cx-db-password,
kamailio-db-password): ims.credentials.existingSecret, else the chart's own.
*/}}
{{- define "firecell-5gc.imsCredentialsSecret" -}}
{{- .Values.ims.credentials.existingSecret | default "ims-db-credentials" -}}
{{- end }}

{{/*
One IMS account password: explicit value, else the live chart Secret (lookup,
so an upgrade keeps it), else 32 random alphanumerics. Alphanumerics fit both
the gateway charset and the narrower Kamailio one ([A-Za-z0-9._~-]{1,64}).
Call with (dict "root" $ "key" "cx-db-password" "value" <explicit>).
*/}}
{{- define "firecell-5gc.imsCredential" -}}
{{- if .value -}}
{{- .value -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .root.Values.global.namespace "ims-db-credentials" -}}
{{- if and $existing $existing.data (hasKey $existing.data .key) -}}
{{- index $existing.data .key | b64dec -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Projected volume /run/secrets/ims for the IMS containers: the MySQL root
password (mysql-secrets) and the account passwords named in .keys.
Mode 0440 with the pod's fsGroup lets the gateway (uid 10001) read them.
Call with (dict "root" $ "name" <volume> "withRoot" bool "keys" (list ...)).
*/}}
{{- define "firecell-5gc.imsSecretVolume" -}}
- name: {{ .name }}
  projected:
    defaultMode: 0440
    sources:
      {{- if .withRoot }}
      - secret:
          name: mysql-secrets
          items:
            - key: root-password
              path: root-password
      {{- end }}
      - secret:
          name: {{ include "firecell-5gc.imsCredentialsSecret" .root }}
          items:
            {{- range .keys }}
            - key: {{ . }}
              path: {{ . }}
            {{- end }}
{{- end }}

{{/*
Namespace of the firecell-nms release.
*/}}
{{/*
"true" when the chart renders the NMS SBI client certificate (Secret nms.sbiClientCert.secretName in
nms.namespace, templates/sbi-security/generated.yaml): global.sbi.tls on with source helm,
nms.sbiClientCert.enabled, and the NMS namespace exists (lookup). The Secret cannot be created in a
namespace that does not exist, and the core install must not fail for it: it is skipped, NOTES.txt
says so, and a helm upgrade after the NMS namespace exists renders it. helm template and a client
dry run cannot look up, so they never render it.
*/}}
{{- define "firecell-5gc.nmsSbiClientCertRendered" -}}
{{- $sbi := .Values.global.sbi -}}
{{- $c := (.Values.nms).sbiClientCert | default dict -}}
{{- if and $sbi.tls.enabled (eq $sbi.tls.source "helm") $c.enabled -}}
{{- if lookup "v1" "Namespace" "" (include "firecell-5gc.nmsNamespace" .) -}}
true
{{- end -}}
{{- end -}}
{{- end }}

{{- define "firecell-5gc.nmsNamespace" -}}
{{- required "nms.namespace is required" (.Values.nms).namespace -}}
{{- end }}

{{/*
The NF Deployments the NMS manages, as a JSON list. Must follow the names and
conditions of the NF Deployment templates.
*/}}
{{- define "firecell-5gc.nmsDeployments" -}}
{{- $names := list -}}
{{- /* eir, nef and nssf: deployed only when enabled (feature-wave NFs; EIR and NEF have FCAPS) */ -}}
{{- range $nf := list "amf" "smf" "pcf" "udr" "udm" "nrf" "ausf" "eir" "nef" "nssf" -}}
{{- if (index $.Values $nf).enabled -}}
{{- $names = append $names (printf "oai-%s" $nf) -}}
{{- end -}}
{{- end -}}
{{- if .Values.udsf.enabled -}}
{{- $names = append $names .Values.udsf.serviceName -}}
{{- end -}}
{{- if .Values.upf.enabled -}}
{{- range (.Values.upf.instances | default (list (dict))) -}}
{{- $names = append $names (printf "oai-upf%s" (.suffix | default "" | toString)) -}}
{{- end -}}
{{- end -}}
{{- toJson $names -}}
{{- end }}

{{/*
IPv6 DNN: "true" for a coreConfig.dnns entry of type IPV6 or IPV4V6 that has an
IPv6 pool: ipv6Prefix, or ipAllocationMode dhcp (the /64 then comes from DHCPv6).
The NFs read ipv6_prefix only for those two types (common-src dnn_config::validate),
and an IPV4V6 DNN without a pool is IPv4-only. Context: the DNN entry.
*/}}
{{- define "firecell-5gc.isIpv6Dnn" -}}
{{- if and (has (.pduSessionType | default "" | toString | upper) (list "IPV6" "IPV4V6")) (or .ipv6Prefix (eq (.ipAllocationMode | default "" | toString) "dhcp")) -}}true{{- end -}}
{{- end }}

{{/*
IPv6 user plane (P23) on: "true" when coreConfig.dnns has an IPv6 DNN
(firecell-5gc.isIpv6Dnn). Empty otherwise. Every IPv6 item of the chart is behind
this one test, so the default values (the "ims" DNN is IPV4V6 without an IPv6
pool) render as before.
*/}}
{{- define "firecell-5gc.ipv6UserPlane" -}}
{{- $on := false -}}
{{- range .Values.coreConfig.dnns -}}
{{- if include "firecell-5gc.isIpv6Dnn" . -}}{{- $on = true -}}{{- end -}}
{{- end -}}
{{- if $on -}}true{{- end -}}
{{- end }}

{{/*
"key: value" lines, one per pair (list "<NF yaml key>" <value>) whose value is
set; an unset ("" or absent) value is left out so the NF keeps its own default.
dict keys: pairs (list of pairs), indent (int).
*/}}
{{- define "firecell-5gc.optionalKeys" -}}
{{- range .pairs }}
{{- $v := index . 1 }}
{{- if not (or (kindIs "invalid" $v) (eq (toString $v) "")) }}
{{ printf "%s: %s" (index . 0) (ternary (quote $v) (toString $v) (kindIs "string" $v)) | indent $.indent }}
{{- end }}
{{- end }}
{{- end }}

{{/*
The IPv6 keys of one coreConfig.dnns entry (common-src dnn_config, P23-a/P23-g),
for both DNN lists (common config and the hostNetwork UPF config), so the SMF and
the UPF read the same pool. Context: the DNN entry.
*/}}
{{- define "firecell-5gc.dnnIpv6Keys" -}}
{{- with .ipAllocationMode }}
{{- if not (has (toString .) (list "static" "dhcp")) }}
{{- fail (printf "coreConfig.dnns[].ipAllocationMode must be static or dhcp (got %q)" (toString .)) }}
{{- end }}
{{- end }}
{{- include "firecell-5gc.optionalKeys" (dict "indent" 4 "pairs" (list (list "ipv6_prefix" .ipv6Prefix) (list "ip_allocation_mode" .ipAllocationMode))) }}
{{- end }}

{{/*
CP relay (cn5g-upf support_features.enable_cp_relay, cn5g-smf
upfs[].config.enable_cp_relay; P23-c/P23-e, D-1c) for one UPF instance: "true"
when the IPv6 user plane is on and the instance serves an IPv6 DNN (no "dnns"
list = all DNNs). Both sides must agree: the SMF defaults to yes and the UPF to
no, and with that pairing RS/RA never flow and SLAAC does not complete.
dict keys: ctx (root context), inst (upf.instances entry, or an empty dict for the
single UPF).
*/}}
{{- define "firecell-5gc.upfCpRelay" -}}
{{- $v := .ctx.Values -}}
{{- if include "firecell-5gc.ipv6UserPlane" .ctx -}}
{{- $v6dnns := list -}}
{{- range $v.coreConfig.dnns -}}
{{- if include "firecell-5gc.isIpv6Dnn" . -}}
{{- $v6dnns = append $v6dnns (.dnn | toString) -}}
{{- end -}}
{{- end -}}
{{- $serves := not .inst.dnns -}}
{{- range (.inst.dnns | default list) -}}
{{- if has (. | toString) $v6dnns -}}{{- $serves = true -}}{{- end -}}
{{- end -}}
{{- if $serves -}}true{{- end -}}
{{- end -}}
{{- end }}

{{/*
"true" when FCAPS (the MnS producer and its intent ConfigMap) is on for one UPF:
the instance's fcaps.enabled when that key is set, else upf.fcaps.enabled (read
as before: any non-empty value is on). Empty string when off.
dict keys: ctx (root context), inst (upf.instances entry, or the single-UPF dict).
*/}}
{{- define "firecell-5gc.upfFcapsOn" -}}
{{- $f := .inst.fcaps | default dict -}}
{{- if not (kindIs "map" $f) -}}
{{- fail (printf "upf.instances[] oai-upf%s: fcaps must be a map {enabled} (got %v)" (.inst.suffix | default "" | toString) $f) -}}
{{- end -}}
{{- if hasKey $f "enabled" -}}
{{- if eq (include "firecell-5gc.flag" (list $f.enabled false)) "true" }}true{{ end -}}
{{- else if (.ctx.Values.upf.fcaps | default dict).enabled -}}true
{{- end -}}
{{- end }}

{{/*
N4 != N3 (user decision Q7, 9 Nov 2026: N4 and N3 shall not share an IP address).
Mirrors cn5g-upf cp_relay_config_error (P23-e): with enable_cp_relay on, the UPF
opens its N4-u GTP-U endpoint (UDP 2152) on the N4 IPv4 address and refuses to
load when that is the N3 or the N9 address. The chart fails earlier, from what it
knows: the interface names the UPF config gets (same coalesce chains as the two
config templates), and the N3/N4 addresses when both are set in the values. Two
different interfaces that carry the same address are left to the UPF check. N9 is
not checked here: with an instance's n9.enabled the hostNetwork UPF config template
(firecell-5gc.oaiUpfHostnetConfig) already fails when the N9 interface is the N3,
N6, N4 or SBI one, which covers N4 = N9 by interface name.
dict keys: ctx, inst, appName.
*/}}
{{- define "firecell-5gc.upfN4N3Check" -}}
{{- $v := .ctx.Values -}}
{{- $inst := .inst -}}
{{- if include "firecell-5gc.upfCpRelay" (dict "ctx" .ctx "inst" $inst) -}}
{{- $n3 := "" -}}{{- $n4 := "" -}}
{{- if $v.upf.hostNetwork -}}
{{- $n3 = coalesce $inst.n3Interface $v.upf.n3Interface "eth0" -}}
{{- $n4 = coalesce $inst.hostPfcpMacvlan $inst.n4Interface $v.upf.hostPfcpMacvlan $v.upf.n4Interface "eno1" -}}
{{- else -}}
{{- $n3 = $v.upf.n3Interface | default "eth0" -}}
{{- $n4 = $v.upf.hostPfcpMacvlan | default "eth0" -}}
{{- end -}}
{{- $why := "the IPv6 CP relay (enable_cp_relay, on because a DNN has an IPv6 pool) opens the UPF N4-u GTP-U endpoint, UDP 2152 on the N4 IPv4 address, which must not be the N3 address (N4 and N3 shall not share an IP address): give N4 its own interface and address (upf.hostPfcpMacvlan + upf.hostPfcpIP, or upf.n4Interface)" -}}
{{- if eq $n4 $n3 -}}
{{- fail (printf "%s: N4 interface %q is the N3 interface; %s" .appName $n4 $why) -}}
{{- end -}}
{{- /* coalesce of only empty values is nil, and nil | toString is "<nil>" */ -}}
{{- $n3ip := (coalesce $inst.n3IP $v.upf.n3IP | default "") | toString -}}
{{- $n4ip := "" -}}
{{- if coalesce $inst.hostPfcpMacvlan $v.upf.hostPfcpMacvlan -}}
{{- $n4ip = (coalesce $inst.hostPfcpIP $v.upf.hostPfcpIP | default "") | toString -}}
{{- end -}}
{{- if and $n3ip $n4ip (eq $n3ip $n4ip) -}}
{{- fail (printf "%s: the N4 address %s is the N3 address; %s" .appName $n4ip $why) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
The SMF N4-u GTP-U port (cn5g-smf smf.ipv6.n4u.port, default 2152).
*/}}
{{- define "firecell-5gc.smfN4uPort" -}}
{{- (((.Values.coreConfig.smf.ipv6 | default dict).n4u | default dict).port | default 2152) -}}
{{- end }}

{{/*
"true" when the SMF N4-u address survives an SMF pod replacement (D-1b): the SMF
binds ipv6.n4u.address, default its N4 address, and puts it in the UPF's
"to CP function" FAR. Stable: a hostNetwork SMF on its PFCP macvlan
(smf.hostPfcpIP / smf.n4IP), a Multus SMF with smf.n4IP, or an explicit
coreConfig.smf.ipv6.n4u.address. Otherwise it is the pod IP.
*/}}
{{- define "firecell-5gc.smfN4uStable" -}}
{{- $s := .Values.smf -}}
{{- $n4u := ((.Values.coreConfig.smf.ipv6 | default dict).n4u | default dict) -}}
{{- if or $n4u.address (and $s.hostNetwork (coalesce $s.hostPfcpIP $s.n4IP "")) (and (not $s.hostNetwork) ($s.multus).enabled $s.n4IP) -}}true{{- end -}}
{{- end }}

{{/*
cn5g-upf support_features.delete_sessions_on_smf_restart (P20-upf), written only
when upf.deleteSessionsOnSmfRestart is set, as "yes"/"no" (true/false accepted).
Context: .Values.upf.
*/}}
{{- define "firecell-5gc.upfDeleteSessionsOnSmfRestart" -}}
{{- $d := .deleteSessionsOnSmfRestart -}}
{{- if not (or (kindIs "invalid" $d) (eq (toString $d) "")) }}
{{- $s := toString $d | lower }}
{{- if not (has $s (list "yes" "no" "true" "false")) }}
{{- fail (printf "upf.deleteSessionsOnSmfRestart must be yes or no (got %q)" (toString $d)) }}
{{- end }}
    delete_sessions_on_smf_restart: {{ if has $s (list "yes" "true") }}yes{{ else }}no{{ end }}
{{- end }}
{{- end }}

{{/*
cn5g-upf upf.gtpu_error_indication_restart_holdoff_s (accelleran/cn5g-upf#68): the seconds
after the UPF start without GTP-U Error Indication for a G-PDU that matches no PDR (TS 23.527
4.3.2), 0..3600, 0 = none. Written only when set; unset: the UPF default 60. The UPF does not
start outside 0..3600, so the render fails first; a whole number only (firecell-5gc.wholeNumber:
a YAML-file float64 or a --set int64). Called with the upf values map.
*/}}
{{- define "firecell-5gc.upfGtpuEiRestartHoldoff" -}}
{{- $raw := .gtpuErrorIndicationRestartHoldoffS -}}
{{- if not (or (kindIs "invalid" $raw) (eq (toString $raw) "")) }}
{{- $n := include "firecell-5gc.wholeNumber" $raw }}
{{- if or (not $n) (lt (int64 $n) 0) (gt (int64 $n) 3600) }}
{{- fail (printf "upf.gtpuErrorIndicationRestartHoldoffS must be a whole number 0 to 3600 (got %#v, a %s)" $raw (kindOf $raw)) }}
{{- end }}
  gtpu_error_indication_restart_holdoff_s: {{ $n }}
{{- end }}
{{- end }}

{{/*
cn5g-upf upf.pfcp_node_id_fqdn (accelleran/cn5g-upf#67): the PFCP Node ID of the UPF as an FQDN (TS 29.244
5.8.1), also its NRF profile fqdn. Unset or "": not written, the Node ID is the N4 IPv4 address (as before).
The SMF compares the Node ID with its upfs[].host / upf_pool[].host exactly, so the SMF side renders the
same string (firecell-5gc.upfPfcpHost); the SMF resolves it for N4, so it has to resolve to the UPF's N4
address. Only for the single UPF (not upf.instances[]), and upf.pfcpHost must be unset or the same string.
The UPF does not start on a value its PFCP encoder cannot carry, so the render fails first: 3 to 253
characters, labels of 1 to 63 letters, digits or '-' (not at either end), last label not all digits (so no
IPv4 address; IPv6 fails the character set). Called with the root values ($v).
*/}}
{{- define "firecell-5gc.upfPfcpNodeIdFqdn" -}}
{{- $f := toString (.upf.pfcpNodeIdFqdn | default "") -}}
{{- if $f }}
{{- if .upf.instances }}
{{- fail "upf.pfcpNodeIdFqdn is for the single UPF; with upf.instances[] it is not supported" }}
{{- end }}
{{- if and .upf.pfcpHost (ne (toString .upf.pfcpHost) $f) }}
{{- fail (printf "upf.pfcpHost (%s) must be unset or equal to upf.pfcpNodeIdFqdn (%s): the SMF matches the Node ID with that host" .upf.pfcpHost $f) }}
{{- end }}
{{- $label := "[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?" }}
{{- if or (lt (len $f) 3) (gt (len $f) 253) (not (regexMatch (printf "^%s(\\.%s)*$" $label $label) $f)) (regexMatch "(^|\\.)[0-9]+$" $f) }}
{{- fail (printf "upf.pfcpNodeIdFqdn %q is not an FQDN the UPF accepts: 3 to 253 characters, labels of 1 to 63 letters, digits or '-' (not at either end), last label not all digits" $f) }}
{{- end }}
{{- $f -}}
{{- end }}
{{- end }}

{{/*
The SMF's host for the single UPF (smf.upf_pool[].host, smf.upfs[].host): upf.pfcpNodeIdFqdn when set
(the SMF matches the Node ID with it), else upf.pfcpHost, else oai-upf (as before).
*/}}
{{- define "firecell-5gc.upfPfcpHost" -}}
{{- $f := include "firecell-5gc.upfPfcpNodeIdFqdn" . -}}
{{- if $f }}{{ $f }}{{ else if .upf.pfcpHost }}{{ .upf.pfcpHost }}{{ else }}oai-upf{{ end -}}
{{- end }}

{{/*
PCF AM policy Service Area Restriction (cn5g-pcf am_policy[.supi.<supi>].serv_area_res,
TS 29.571 ServiceAreaRestriction): restriction_type and a list of TACs. The PCF refuses
anything else at start, so the render fails first. dict: d (the values map), where (its
path, for the message). The TACs are written as strings: quote them in the values file
(an unquoted 000009 is the number 9).
*/}}
{{- define "firecell-5gc.pcfServAreaRes" -}}
{{- $t := required (printf "%s.restrictionType is required (ALLOWED_AREAS or NOT_ALLOWED_AREAS)" .where) .d.restrictionType -}}
{{- if not (has $t (list "ALLOWED_AREAS" "NOT_ALLOWED_AREAS")) }}
{{- fail (printf "%s.restrictionType must be ALLOWED_AREAS or NOT_ALLOWED_AREAS (got %q)" .where $t) }}
{{- end }}
{{- if not .d.tacs }}
{{- fail (printf "%s.tacs is required (a list of 4 or 6 hex digit TACs, quoted)" .where) }}
{{- end }}
restriction_type: {{ $t | quote }}
tacs:
{{- range .d.tacs }}
{{- if not (regexMatch "^([0-9A-Fa-f]{4}|[0-9A-Fa-f]{6})$" (toString .)) }}
{{- fail (printf "%s.tacs: %q is not a TAC of 4 or 6 hex digits (quote it in the values file)" $.where (toString .)) }}
{{- end }}
  - {{ toString . | quote }}
{{- end }}
{{- end }}

{{/*
PCF trace record directory (cn5g-pcf pcf.trace.dir, default /openair-pcf/trace): the one
place the config (pcf.trace.dir) and the Deployment (the emptyDir mounted there) read it
from. Takes the coreConfig.pcf.trace map. An absolute path is required.
*/}}
{{- define "firecell-5gc.pcfTraceDir" -}}
{{- $dir := .dir | default "/openair-pcf/trace" -}}
{{- if not (hasPrefix "/" $dir) }}
{{- fail (printf "coreConfig.pcf.trace.dir must be an absolute path (got %q)" $dir) }}
{{- end }}
{{- $dir }}
{{- end }}

{{/*
SBI security (global.sbi.tls / global.sbi.oauth2): the NFs that get a certificate, and the
volumes and mounts of an NF container. All empty when both are off.
*/}}
{{- define "firecell-5gc.sbiNfs" -}}
{{- $v := .Values -}}
{{- range $nf := list "amf" "smf" "upf" "ausf" "udm" "udr" "pcf" "nrf" "udsf" "eir" "nef" "nssf" -}}
{{- if (index $v $nf).enabled }}
- {{ $nf }}
{{- end }}
{{- end }}
{{- if include "firecell-5gc.rxN5IwfEnabled" . }}
- rx-n5-iwf
{{- end }}
{{- end }}

{{/*
The NSSF port the AMF dials (shared config nfs.nssf): nssf.config.http2Port with TLS or OAuth2 (the
NSSF then serves HTTP/2 only) or with coreConfig.httpVersion 2, else nssf.config.http1Port. The AMF
calls the NSSF with the shared http_version.
*/}}
{{- define "firecell-5gc.nssfAmfPort" -}}
{{- $sbi := .Values.global.sbi -}}
{{- $cfg := .Values.nssf.config -}}
{{- if or $sbi.tls.enabled $sbi.oauth2.enabled (eq (int .Values.coreConfig.httpVersion) 2) -}}
{{- $cfg.http2Port -}}
{{- else -}}
{{- $cfg.http1Port -}}
{{- end -}}
{{- end }}

{{/*
The EIR's effective auth profile: eir.config.authProfile, with auto (the default) resolved to
commercial when global.sbi.tls and global.sbi.oauth2 are both on, else lab. The commercial profile
checks the NRF's access tokens (JWT); the lab profile knows only its static tokens and answers 401
to the AMF's NRF token.
*/}}
{{- define "firecell-5gc.eirProfile" -}}
{{- $p := .Values.eir.config.authProfile | default "auto" -}}
{{- if eq $p "auto" -}}
{{- ternary "commercial" "lab" (and .Values.global.sbi.tls.enabled .Values.global.sbi.oauth2.enabled) -}}
{{- else if has $p (list "lab" "commercial") -}}
{{- $p -}}
{{- else -}}
{{- fail (printf "eir.config.authProfile must be auto, lab or commercial (got %q)" $p) -}}
{{- end -}}
{{- end }}

{{/* The EIR's cleartext health port: 0 when authProfile auto resolves to commercial (the EIR
serves none there), else eir.config.healthHttp1Port. */}}
{{- define "firecell-5gc.eirHealthPort" -}}
{{- if and (eq (.Values.eir.config.authProfile | default "auto") "auto") (eq (include "firecell-5gc.eirProfile" .) "commercial") -}}
0
{{- else -}}
{{- .Values.eir.config.healthHttp1Port -}}
{{- end -}}
{{- end }}

{{/* "true" when the Rx-N5 IWF is rendered (Kamailio IMS with ims.rxN5Iwf.enabled), else empty. */}}
{{- define "firecell-5gc.rxN5IwfEnabled" -}}
{{- if and .Values.ims.enabled (eq (.Values.ims.engine | default "kamailio") "kamailio") .Values.ims.rxN5Iwf.enabled -}}
true
{{- end -}}
{{- end }}

{{/*
nfInstanceId of the Rx-N5 IWF at the NRF: ims.rxN5Iwf.nrf.nfInstanceId, else a UUID version 4
derived from the namespace, so it stays the same across restarts and upgrades (the IWF draws a
new random one at every start without it). The NRF checks the version 4 form (validate_uuid).
*/}}
{{- define "firecell-5gc.rxN5IwfNfInstanceId" -}}
{{- with .Values.ims.rxN5Iwf.nrf.nfInstanceId -}}
{{- . -}}
{{- else -}}
{{- $h := sha256sum (printf "%s/ims-rx-n5-iwf" .Values.global.namespace) -}}
{{- $c := substr 16 17 $h -}}
{{- $variant := "b" -}}
{{- if contains $c "0123" }}{{ $variant = "8" }}{{ else if contains $c "4567" }}{{ $variant = "9" }}{{ else if contains $c "89ab" }}{{ $variant = "a" }}{{ end -}}
{{- printf "%s-%s-4%s-%s%s-%s" (substr 0 8 $h) (substr 8 12 $h) (substr 13 16 $h) $variant (substr 17 20 $h) (substr 20 32 $h) -}}
{{- end -}}
{{- end }}

{{/* dict: ctx (root), nf. The Service an NF's SBI certificate is issued for (its commonName). */}}
{{- define "firecell-5gc.sbiCertService" -}}
{{- if eq .nf "udsf" -}}
{{- .ctx.Values.udsf.serviceName | default "oai-udsf" -}}
{{- else if eq .nf "rx-n5-iwf" -}}
ims-rx-n5-iwf
{{- else -}}
{{- printf "oai-%s" .nf -}}
{{- end -}}
{{- end }}

{{/*
dict: ctx (root), nf. The DNS names of an NF's SBI certificate (a YAML list): the Service in its
short and namespace forms. The NFs dial the UDSF by udsf.host (shared config nfs.udsf.host), which
may differ from the Service name: it must be in the certificate too.
*/}}
{{- define "firecell-5gc.sbiCertDnsNames" -}}
{{- $ns := .ctx.Values.global.namespace -}}
{{- $svc := include "firecell-5gc.sbiCertService" . -}}
{{- $names := list $svc -}}
{{- if and (eq .nf "udsf") .ctx.Values.udsf.host (ne .ctx.Values.udsf.host $svc) -}}
{{- $names = append $names .ctx.Values.udsf.host -}}
{{- end -}}
{{- range $n := $names }}
- {{ $n }}
- {{ $n }}.{{ $ns }}
- {{ $n }}.{{ $ns }}.svc
- {{ $n }}.{{ $ns }}.svc.cluster.local
{{- end }}
{{- end }}

{{/* dict: ctx (root), nf */}}
{{- define "firecell-5gc.sbiSecurityMounts" -}}
{{- $sbi := .ctx.Values.global.sbi -}}
{{- if $sbi.tls.enabled }}
- name: sbi-tls
  mountPath: /etc/firecell/sbi-tls
  readOnly: true
{{- end }}
{{- if $sbi.oauth2.enabled }}
- name: sbi-oauth2-public
  mountPath: /etc/firecell/sbi-oauth2
  readOnly: true
{{- if eq .nf "nrf" }}
- name: sbi-oauth2-signing
  mountPath: /etc/firecell/sbi-oauth2-signing
  readOnly: true
{{- end }}
{{- end }}
{{- end }}

{{/* dict: ctx (root), nf */}}
{{- define "firecell-5gc.sbiSecurityVolumes" -}}
{{- $sbi := .ctx.Values.global.sbi -}}
{{- if $sbi.tls.enabled }}
- name: sbi-tls
  secret:
    secretName: {{ printf "%s-%s" $sbi.tls.secretPrefix .nf }}
{{- end }}
{{- if $sbi.oauth2.enabled }}
- name: sbi-oauth2-public
  secret:
    secretName: {{ $sbi.oauth2.publicKeySecret }}
{{- if eq .nf "nrf" }}
- name: sbi-oauth2-signing
  secret:
    secretName: {{ $sbi.oauth2.signingKeySecret }}
{{- end }}
{{- end }}
{{- end }}


{{- /*
  A whole number from values as a decimal string, or "" when it is not one.
  Values from a YAML file are float64 (1000000 prints as 1e+06 through
  toString), --set gives int64: both are accepted when they have no fractional
  part. Strings, booleans and fractions give "".
*/ -}}
{{- define "firecell-5gc.wholeNumber" -}}
{{- if or (kindIs "int" .) (kindIs "int64" .) -}}
{{- int64 . -}}
{{- else if and (kindIs "float64" .) (eq (float64 (int64 .)) .) -}}
{{- int64 . -}}
{{- end -}}
{{- end }}

{{/*
Load balancer provider for type LoadBalancer Services: "metallb" (default) or
"cilium" (network.loadBalancer.provider).
*/}}
{{- define "firecell-5gc.lbProvider" -}}
{{- $p := dig "loadBalancer" "provider" "metallb" (.Values.network | default dict) -}}
{{- if not (has $p (list "metallb" "cilium")) -}}
{{- fail (printf "network.loadBalancer.provider must be metallb or cilium, got %q" $p) -}}
{{- end -}}
{{- $p -}}
{{- end -}}

{{/*
Pod placement (nodeSelector, tolerations) for one NF's pod spec. The NF's own
values win; when empty, global.nodeSelector / global.tolerations apply.
Renders nothing when both are empty, so the default render is unchanged.
Usage (pod spec at indent 6):
  {{- include "firecell-5gc.placement" (dict "root" $ "nf" $.Values.amf "indent" 6) }}
*/}}
{{- define "firecell-5gc.placement" -}}
{{- $nf := .nf | default dict -}}
{{- $g := .root.Values.global -}}
{{- $out := dict -}}
{{- with (dig "nodeSelector" nil $nf | default $g.nodeSelector) }}{{- $_ := set $out "nodeSelector" . -}}{{- end -}}
{{- with (dig "tolerations" nil $nf | default $g.tolerations) }}{{- $_ := set $out "tolerations" . -}}{{- end -}}
{{- if $out }}{{- toYaml $out | nindent (int .indent) }}{{- end -}}
{{- end -}}
