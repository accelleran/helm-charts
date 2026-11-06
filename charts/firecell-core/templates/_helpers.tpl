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
Sidecar that serves /health and /ready endpoints (default port 9090).
Calls /scripts/check.sh on every probe cycle; returns 200 if exit 0, 503 otherwise.

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
IMS SIP domain from PLMN (999/99 -> ims.mnc099.mcc999.3gppnetwork.org).
*/}}
{{- define "firecell-5gc.imsDomain" -}}
{{- $mcc := .Values.coreConfig.mcc | default "001" -}}
{{- $mnc := .Values.coreConfig.mnc | default "01" -}}
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
  value: {{ .root.Values.coreConfig.mcc | default "001" | quote }}
- name: MNC
  value: {{ .root.Values.coreConfig.mnc | default "01" | quote }}
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
  value: {{ $v.coreConfig.mcc | default "001" | quote }}
- name: MNC
  value: {{ $v.coreConfig.mnc | default "01" | quote }}
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
{{- define "firecell-5gc.nmsNamespace" -}}
{{- required "nms.namespace is required" (.Values.nms).namespace -}}
{{- end }}

{{/*
The NF Deployments the NMS manages, as a JSON list. Must follow the names and
conditions of the NF Deployment templates.
*/}}
{{- define "firecell-5gc.nmsDeployments" -}}
{{- $names := list -}}
{{- range $nf := list "amf" "smf" "pcf" "udr" "udm" "nrf" "ausf" -}}
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
