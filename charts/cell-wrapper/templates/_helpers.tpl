{{- define "accelleran.cell-wrapper.netconf.service.name" -}}
{{- $ := . -}}
{{ $.Values.netconf.service.name | default (printf "netconf-%s" (include "accelleran.common.bootstrap.instanceId" (dict "top" $ "values" $.Values.netconf))) }}
{{- end -}}
