{{/*
Expand the name of the chart.
*/}}
{{- define "e2t.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "e2t.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "e2t.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "e2t.labels" -}}
helm.sh/chart: {{ include "e2t.chart" . }}
{{ include "e2t.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
drax/role: ric
drax/instanceId: "{{ tpl .Values.bootstrapId . }}"
{{- end }}

{{/*
Sctp labels
*/}}
{{- define "e2t.sctp.labels" -}}
{{ include "e2t.labels" . }}
{{ include "e2t.sctp.selectorLabels" . }}
{{- end }}

{{/*
E2ap labels
*/}}
{{- define "e2t.e2ap.labels" -}}
{{ include "e2t.labels" . }}
{{ include "e2t.e2ap.selectorLabels" . }}
{{- end }}

{{/*
Kpm labels
*/}}
{{- define "e2t.kpm.labels" -}}
{{ include "e2t.labels" . }}
{{ include "e2t.kpm.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "e2t.selectorLabels" -}}
app.kubernetes.io/name: {{ include "e2t.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector SCTP labels
*/}}
{{- define "e2t.sctp.selectorLabels" -}}
app.kubernetes.io/component: e2t-sctp
{{ include "e2t.selectorLabels" . }}
{{- end }}

{{/*
Selector E2AP labels
*/}}
{{- define "e2t.e2ap.selectorLabels" -}}
app.kubernetes.io/component: e2t-e2ap
{{ include "e2t.selectorLabels" . }}
{{- end }}

{{/*
Selector KPM labels
*/}}
{{- define "e2t.kpm.selectorLabels" -}}
app.kubernetes.io/component: e2t-sm-kpm
{{ include "e2t.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "e2t.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "e2t.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
