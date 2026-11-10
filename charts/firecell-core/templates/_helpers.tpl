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
- name: MYSQL_ROOT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mysql-secrets
      key: root-password
- name: REGISTRATION_EXPIRES
  value: {{ .root.Values.ims.registrationExpires | default "3600" | quote }}
- name: IMS_DOMAIN
  value: {{ include "firecell-5gc.imsDomain" .root | quote }}
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

{{/*
IPv6 user plane (P23) on: "true" when a coreConfig.dnns entry has ipv6Prefix, or
ipAllocationMode dhcp on an IPV6/IPV4V6 DNN (the /64 then comes from DHCPv6).
Empty otherwise. Every IPv6 item of the chart is behind this one test, so the
default values (the "ims" DNN is IPV4V6 without ipv6Prefix) render as before.
*/}}
{{- define "firecell-5gc.ipv6UserPlane" -}}
{{- $on := false -}}
{{- range .Values.coreConfig.dnns -}}
{{- $type := .pduSessionType | default "" | toString | upper -}}
{{- if .ipv6Prefix -}}{{- $on = true -}}{{- end -}}
{{- if and (eq (.ipAllocationMode | default "" | toString) "dhcp") (has $type (list "IPV6" "IPV4V6")) -}}{{- $on = true -}}{{- end -}}
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
{{- $type := .pduSessionType | default "" | toString | upper -}}
{{- if or .ipv6Prefix (and (eq (.ipAllocationMode | default "" | toString) "dhcp") (has $type (list "IPV6" "IPV4V6"))) -}}
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
N4 != N3 (user decision Q7, 9 Nov 2026: N4 and N3 shall not share an IP address).
Mirrors cn5g-upf cp_relay_config_error (P23-e): with enable_cp_relay on, the UPF
opens its N4-u GTP-U endpoint (UDP 2152) on the N4 IPv4 address and refuses to
load when that is the N3 or the N9 address. The chart fails earlier, from what it
knows: the interface names the UPF config gets (same coalesce chains as the two
config templates), and the N3/N4 addresses when both are set in the values. Two
different interfaces that carry the same address are left to the UPF check. N9 is
not checked: the UPF compares N4 with N9 only with n9.enabled, which the chart
never writes.
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
