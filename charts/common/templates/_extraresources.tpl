{{- define "accelleran.common.extraResources" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common drax license enabled" -}}
{{- $values := get . "values" | default $.Values -}}

{{- range $values.extraResources }}
---
{{ tpl (toYaml .) $ }}
{{- end }}
{{- end -}}
