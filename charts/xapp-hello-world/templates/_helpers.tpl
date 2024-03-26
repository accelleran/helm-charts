{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "xapp_core.name" -}}
{{- $name := printf "%s-%s" .Chart.Name .Chart.Version -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "xapp_core.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default (include "xapp_core.name" .) .Values.nameOverride -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "xapp_core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "xapp_core.labels" -}}
helm.sh/chart: {{ include "xapp_core.chart" . }}
{{ include "xapp_core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
drax/role: xapp
drax/xapp-name: {{ .Release.Name }}
{{ if .Values.developerMode.enabled }}
xapp/mode: Developer
{{ else }}
xapp/mode: Production
{{ end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "xapp_core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "xapp_core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "xapp_core.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "xapp_core.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
