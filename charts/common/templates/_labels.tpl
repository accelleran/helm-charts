{{- define "accelleran.common.selectorLabels" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common selector labels" -}}

{{- $selectorLabels := get . "selectorLabels" -}}
{{- if $selectorLabels -}}
{{- $selectorLabels | toYaml -}}
{{- else -}}
app.kubernetes.io/name: {{ include "accelleran.common.name" . }}
app.kubernetes.io/instance: {{ include "accelleran.common.instance" . }}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.labels" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common labels" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $labels := get . "labels" -}}

{{- if $labels -}}
{{- $labels | toYaml }}
{{- else -}}
helm.sh/chart: {{ include "accelleran.common.chart" . }}
{{ include "accelleran.common.selectorLabels" . }}
{{- with (include "accelleran.common.component" .) }}
app.kubernetes.io/component: {{ . | quote }}
{{- end }}
{{- with (include "accelleran.common.appVersion" . | default (include "accelleran.common.helmVersion" .)) }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
{{- with (include "accelleran.common.partOf" .) }}
app.kubernetes.io/part-of: {{ . | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
drax/helm-version: {{ include "accelleran.common.helmVersion" . | quote }}
{{- with (include "accelleran.common.drax.role" .) }}
drax/role: {{ . | quote }}
{{- end }}
{{- with (include "accelleran.common.drax.technology" .) }}
drax/technology: {{ . | quote }}
{{- end }}
{{- with (include "accelleran.common.bootstrap.instanceId" .) }}
drax/instanceId: {{ . | quote }}
{{- end }}
{{- with $values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}
{{- end -}}
