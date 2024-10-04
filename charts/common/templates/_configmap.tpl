{{- define "accelleran.common.configMap" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common config map" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $data := get . "data" | default dict -}}
{{- $binaryData := get . "binaryData" | default dict -}}

apiVersion: v1
kind: ConfigMap
{{ include "accelleran.common.metadata" . }}
{{- with $data }}
data: {{ . | toYaml | nindent 2 }}
{{- end }}
{{- with $binaryData }}
binaryData: {{ . | toYaml | nindent 2 }}
{{- end }}
{{- end -}}
