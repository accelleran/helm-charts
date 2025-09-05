{{- define "accelleran.cu-cp.init.args" -}}
{{- $ := . -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ mergeOverwrite (omit (deepCopy $.Values) "readinessProbe") (fromYaml (include "accelleran.cu-cp.disabledLicense" .)) | toYaml | nindent 2 }}

bootstrapConfigMapName: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}


{{- define "accelleran.cu-cp.disabledLicense" -}}
accelleranLicense:
  enabled: false
{{- end -}}


{{- define "accelleran.cu-cp.selectorLabels" -}}
{{- $ := get . "top" | required "The top context needs to be provided to cu-cp selector labels" -}}
{{- $values := get . "values" | default $.Values -}}

{{
  include "accelleran.common.selectorLabels"
    (dict
      "top" $
      "values" (mergeOverwrite
        (deepCopy $values)
        (dict
          "nameOverride" $.Values.nameOverride
          "fullnameOverride" $.Values.fullnameOverride
        )
      )
    )
}}
app.kubernetes.io/component: {{ $values.component }}
{{- end -}}


{{- define "accelleran.cu-cp.labels" -}}
{{- $ := get . "top" | required "The top context needs to be provided to cu-cp labels" -}}
{{- $values := get . "values" | default $.Values -}}

{{
  include "accelleran.common.labels"
    (dict
      "top" $
      "values" (mergeOverwrite
        (deepCopy $values)
        (dict
          "nameOverride" $.Values.nameOverride
          "fullnameOverride" $.Values.fullnameOverride
        )
      )
    )
  }}
{{- end -}}
