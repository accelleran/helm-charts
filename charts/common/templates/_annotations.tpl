{{- define "accelleran.common.annotations" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common annotations" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $annotations := get . "annotations" -}}

{{- if $annotations -}}
{{- $annotations | toYaml }}
{{- else -}}
{{- with $values.annotations -}}
{{ tpl (toYaml .) $ }}
{{- end -}}
{{- end -}}
{{- end -}}
