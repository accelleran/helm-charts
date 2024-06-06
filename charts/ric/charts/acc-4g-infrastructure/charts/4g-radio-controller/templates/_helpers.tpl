{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "oran-clustercontrol.name" -}}
{{- $name := printf "%s-%s" .Chart.Name .Chart.Version | replace "." "-" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oran-clustercontrol.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default (include "oran-clustercontrol.name" .) .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "oran-clustercontrol.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "oran-clustercontrol.labels" -}}
helm.sh/chart: {{ include "oran-clustercontrol.chart" . }}
{{ include "oran-clustercontrol.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
drax/role: drax-core
drax/name: 4G-Radio-Controller
drax/component-name: {{ .Chart.Name }}
drax/component-version: {{ .Chart.Version }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "oran-clustercontrol.selectorLabels" -}}
app.kubernetes.io/name: {{ include "oran-clustercontrol.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "oran-clustercontrol.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "oran-clustercontrol.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
