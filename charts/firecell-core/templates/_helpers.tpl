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
{{- printf "%s/%s:v%s" .registry .image .tag }}
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
      echo 0 > /tmp/ready
      (
        while true; do
          if sh /scripts/check.sh >/dev/null 2>&1; then
            echo 1 > /tmp/ready
          else
            echo 0 > /tmp/ready
          fi
          sleep 2
        done
      ) &
      while true; do
        if [ "$(cat /tmp/ready 2>/dev/null)" = "1" ]; then
          printf 'HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: 2\r\n\r\nOK' | nc -w 1 -l -p {{ $healthPort }} >/dev/null 2>&1 || sleep 0.1
        else
          printf 'HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\nContent-Length: 9\r\n\r\nNOT READY' | nc -w 1 -l -p {{ $healthPort }} >/dev/null 2>&1 || sleep 0.1
        fi
      done
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

{{- /*
  DNN dataplane helper sidecar.

  Lives in the UPF pod because the routes and SNAT rules for a DNN pool exist
  in that pod's network namespace and nowhere else: the NMS ServiceAccount has
  no pods/exec and cannot reach them. Called once by the NMS after an operator
  Start/Restart, or on explicit request. It has no loop of its own and never
  deletes a rule it did not expect.

  Deployed for every UPF type, not only the one it can act on, so that support
  gets the same answer shape from every UPF. On OAI XDP and Open5GS it reports
  NOT_APPLICABLE and touches nothing — a UPF with no helper at all is
  indistinguishable from one whose helper is broken.

  Params: Values, port, mode, configVolume, configSubPath, omitContainerPort.
*/ -}}
{{- define "firecell-5gc.dnnDataplaneSidecar" -}}
{{- $dnnDp := .Values.upf.dnnDataplane | default dict }}
{{- $port := .port | default 8196 }}
- name: fc-dnn-dataplane
  image: {{ $dnnDp.imageOverride | default (include "firecell-5gc.image" (dict "registry" .Values.global.imageRegistry "image" ($dnnDp.image | default "fc-dnn-dataplane") "tag" ($dnnDp.imageTag | default .Values.global.pkgVersion))) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  # Keep the chart explicit even if an older locally imported image has the
  # original uvicorn command, which hardcoded 8096 and ignored FC_DNN_PORT.
  command: ["python", "app.py"]
  env:
    - name: FC_DNN_PORT
      value: {{ $port | quote }}
    {{- if eq (.mode | default "auto") "auto" }}
    # auto: derive the datapath from enable_bpf_datapath in the UPF's config,
    # so an XDP/userspace switch does not need a values change here too.
    {{- end }}
    - name: FC_DNN_MODE
      value: {{ .mode | default "auto" | quote }}
    {{- if .configVolume }}
    # The config this UPF is actually running, not what the NMS intends. The
    # helper reads dnns[] order from here because OAI gives dnns[0] the tun0
    # address and routes every other pool via it; a different order invents a
    # different gateway.
    - name: FC_DNN_UPF_CONFIG
      value: /etc/upf/config.yaml
    {{- end }}
    {{- if .intentVolume }}
    # ConfigMap intent is overlaid on the seed before the UPF builds tun0.
    # Reading only the seed checks stale pools after a CM change.
    - name: FC_DNN_CM_INTENT
      value: /var/lib/firecell/cm/cm.json
    {{- end }}
  {{- if or .configVolume .intentVolume }}
  volumeMounts:
    {{- if .configVolume }}
    - name: {{ .configVolume }}
      mountPath: /etc/upf/config.yaml
      {{- if .configSubPath }}
      subPath: {{ .configSubPath }}
      {{- end }}
      readOnly: true
    {{- end }}
    {{- if .intentVolume }}
    - name: {{ .intentVolume }}
      mountPath: /var/lib/firecell/cm
      readOnly: true
    {{- end }}
  {{- end }}
  {{- if not (.omitContainerPort | default false) }}
  ports:
    - containerPort: {{ $port }}
      protocol: TCP
  {{- end }}
  securityContext:
    # `ip route add` and `iptables -t nat -A` in the namespace it already
    # shares. Not privileged: it does not touch the host beyond that namespace
    # and does not load eBPF.
    capabilities:
      add:
        - NET_ADMIN
        - NET_RAW
  readinessProbe:
    httpGet:
      path: /health
      port: {{ $port }}
    initialDelaySeconds: 5
    periodSeconds: 10
    failureThreshold: 3
    timeoutSeconds: 3
  resources:
    {{- toYaml ($dnnDp.resources | default dict) | nindent 4 }}
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
{{- if and .Values.upf.enabled (has .Values.upf.type (list "oai" "o5gs")) -}}
{{- $prefix := ternary "oai-upf" "o5gs-upf" (eq .Values.upf.type "oai") -}}
{{- range (.Values.upf.instances | default (list (dict))) -}}
{{- $names = append $names (printf "%s%s" $prefix (.suffix | default "" | toString)) -}}
{{- end -}}
{{- end -}}
{{- toJson $names -}}
{{- end }}
