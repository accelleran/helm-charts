{{- define "accelleran.cu-up.upsCount" -}}
{{- add $.Values.numberOfUpStacks -}}
{{- end -}}


{{- define "accelleran.cu-up.xdpUpsCount" -}}
{{- add (len $.Values.xdpUpStacks) -}}
{{- end -}}


{{- define "accelleran.cu-up.netconf.service.name" -}}
{{- $ := . -}}
{{ $.Values.netconf.service.name | default (printf "%s-%s" (include "accelleran.common.name" (dict "top" $ "values" $.Values.netconf)) (include "accelleran.common.bootstrap.instanceId" (dict "top" $ "values" $.Values.netconf))) }}
{{- end -}}


{{- define "accelleran.cu-up.gtp-u.service.name" -}}
{{- $ := first . -}}
{{- $ordinal := index . 1 -}}

{{ $name := index $.Values "ups" "service" "name" | default (include "accelleran.common.fullname" (dict "top" $ "values" (index $.Values "ups"))) }}
{{- printf "%s-%d" $name $ordinal -}}
{{- end -}}


{{- define "accelleran.cu-up.init.args" -}}
{{- $ := . -}}
{{- $values := (index $.Values "cu-up") -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ mergeOverwrite (deepCopy $values) (fromYaml (include "accelleran.cu-up.disabledLicense" .)) | toYaml | nindent 2 }}

bootstrapConfigMapName: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}


{{- define "accelleran.cu-up.disabledLicense" -}}
accelleranLicense:
  enabled: false
{{- end -}}
