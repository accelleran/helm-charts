{{- define "accelleran.cu-up.upsCount" -}}
{{- add $.Values.numberOfUpStacks -}}
{{- end -}}


{{- define "accelleran.cu-up.xdpUpsCount" -}}
{{- add (len $.Values.xdpUpStacks) -}}
{{- end -}}


{{- define "accelleran.cu-up.gtp-u.service.name" -}}
{{- $ := first . -}}
{{- $ordinal := index . 1 -}}

{{ $name := index $.Values "ups" "service" "name" | default (include "accelleran.common.fullname" (dict "top" $ "values" (index $.Values "ups"))) }}
{{- printf "%s-%d" $name $ordinal -}}
{{- end -}}


{{- define "accelleran.cu-up.init.args" -}}
{{- $ := . -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ mergeOverwrite (omit (deepCopy $.Values) "readinessProbe") (fromYaml (include "accelleran.cu-up.disabledLicense" .)) | toYaml | nindent 2 }}

bootstrapConfigMapName: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}


{{- define "accelleran.cu-up.disabledLicense" -}}
accelleranLicense:
  enabled: false
{{- end -}}


{{- define "accelleran.cu-up.selectorLabels" -}}
{{- $ := get . "top" | required "The top context needs to be provided to cu-up selector labels" -}}
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


{{- define "accelleran.cu-up.labels" -}}
{{- $ := get . "top" | required "The top context needs to be provided to cu-up labels" -}}
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
