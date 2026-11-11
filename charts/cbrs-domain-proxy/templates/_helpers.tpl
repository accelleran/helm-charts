{{- define "cbrs-domain-proxy.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: firecell-cbrs
{{- end }}

{{- define "cbrs-domain-proxy.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "cbrs-domain-proxy.config" -}}
sas:
  url: {{ required "sas.url is required" .Values.sas.url | quote }}
  user_id: {{ required "sas.userId is required" .Values.sas.userId | quote }}
  cert_file: /etc/cbrs-dp/sas/tls.crt
  key_file: /etc/cbrs-dp/sas/tls.key
  ca_file: /etc/cbrs-dp/sas/ca.crt
store:
  path: /var/lib/cbrs-dp/state.db
grpc:
  listen: {{ printf ":%d" (int .Values.grpc.port) | quote }}
  cert_file: /etc/cbrs-dp/cbsd/tls.crt
  key_file: /etc/cbrs-dp/cbsd/tls.key
  client_ca_file: /etc/cbrs-dp/cbsd/ca.crt
  allowlist_file: /etc/cbrs-dp/allowlist/allowlist.yaml
metrics:
  listen: {{ printf ":%d" (int .Values.metrics.port) | quote }}
{{- end }}
