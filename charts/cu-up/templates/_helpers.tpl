{{- define "accelleran.cu-up.upsCount" -}}
{{- add .Values.global.numberOfUpStacks (len .Values.global.xdpUpsInterfaces) -}}
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
