{{/*
Number of configured DUs
*/}}
{{- define "cell-wrapper.nDus" -}}
{{- len .Values.global.config.dus -}}
{{- end }}

{{/*
Number of configured RUs
*/}}
{{- define "cell-wrapper.nRus" -}}
{{- $nRus := 0 -}}
{{- range $index, $du := .Values.global.config.dus -}}
  {{- $nRus = add $nRus (len $du.rus) -}}
{{- end -}}
{{- $nRus -}}
{{- end }}

{{/*
Work-around to get the cw-inst deployment name for the instance-scaler
*/}}
{{- define "cell-wrapper.cw-inst.fullname" -}}
{{- $values := index .Values "cw-inst" -}}
{{- if $values.fullnameOverride -}}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "cw-inst" $values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "cell-wrapper.instance-scaler.fullname" -}}
{{ printf "%s-instance-scaler" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Work-around for selector labels for the instance-scaler
*/}}
{{- define "cell-wrapper.instance-scaler.selectorLabels" -}}

{{- $values := index .Values "instance-scaler" -}}

app.kubernetes.io/name: {{ include "acc-common.name" . }}
app.kubernetes.io/instance: {{ include "acc-common.instance" . }}
{{- end -}}

{{/*
Work-around for labels for the instance-scaler
*/}}
{{- define "cell-wrapper.instance-scaler.labels" -}}

{{- $values := index .Values "instance-scaler" -}}

helm.sh/chart: {{ include "acc-common.chart" . }}
{{ include "cell-wrapper.instance-scaler.selectorLabels" . }}
app.kubernetes.io/version: {{ tpl (index $.Values "instance-scaler" "image" "tag") $ | default $.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if include "acc-common.topChart.name" . }}
app.kubernetes.io/part-of: {{ include "acc-common.topChart.name" . }}
{{- end }}
drax/helm-version: {{ include "acc-common.helmVersion" . | quote}}
{{- if include "acc-common.topChart.helmVersion" . }}
drax/top-helm-version: {{ include "acc-common.topChart.helmVersion" . | quote}}
{{- end }}
{{- if include "acc-common.drax.instanceId" . }}
drax/instanceId: {{ include "acc-common.drax.instanceId" . | quote }}
{{- end }}
drax/technology: 5g
drax/role: 5g
{{- end -}}
