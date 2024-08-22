{{- define "accelleran.common.extraResources" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common drax license enabled" -}}
{{- $values := get . "values" | default $.Values -}}

{{- if and (ne $values.extraResources nil) (not (kindIs "slice" $values.extraResources)) -}}
{{- fail (printf "Extra resources need to be provided as a list in the %s chart" (include "accelleran.common.name" .)) -}}
{{- end -}}

{{- range $values.extraResources }}
---
{{ tpl (toYaml .) $ }}
{{- end }}
{{- end -}}
