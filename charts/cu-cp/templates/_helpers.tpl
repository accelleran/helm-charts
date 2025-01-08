{{- define "accelleran.cu-cp.amfCount" -}}
{{- .Values.numOfAmfs -}}
{{- end -}}


{{- define "accelleran.cu-cp.cuUpCount" -}}
{{- .Values.numOfCuUps -}}
{{- end -}}


{{- define "accelleran.cu-cp.duCount" -}}
{{- .Values.numOfDus -}}
{{- end -}}


{{- define "accelleran.cu-cp.cellCount" -}}
{{- .Values.numOfCells -}}
{{- end -}}


{{- define "accelleran.cu-cp.ueCount" -}}
{{- .Values.numOfUes -}}
{{- end -}}


{{- define "accelleran.cu-cp.netconf.service.name" -}}
{{- $ := . -}}
{{ $.Values.netconf.service.name | default (printf "%s-%s" (include "accelleran.common.name" (dict "top" $ "values" $.Values.netconf)) (include "accelleran.common.bootstrap.instanceId" (dict "top" $ "values" $.Values.netconf))) }}
{{- end -}}


{{- define "accelleran.cu-cp.e1.service.name" -}}
{{- $ := . -}}
{{ index $.Values "sctp-e1" "service" "name" | default (include "accelleran.common.fullname" (dict "top" $ "values" (index $.Values "sctp-e1"))) }}
{{- end -}}


{{- define "accelleran.cu-cp.f1.service.name" -}}
{{- $ := . -}}
{{ index $.Values "sctp-f1" "service" "name" | default (include "accelleran.common.fullname" (dict "top" $ "values" (index $.Values "sctp-f1"))) }}
{{- end -}}


{{- define "accelleran.cu-cp.init.args" -}}
{{- $ := . -}}
{{- $values := (index $.Values "cu-cp") -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ mergeOverwrite (deepCopy $values) (fromYaml (include "accelleran.cu-cp.disabledLicense" .)) | toYaml | nindent 2 }}

bootstrapConfigMapName: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}


{{- define "accelleran.cu-cp.disabledLicense" -}}
accelleranLicense:
  enabled: false
{{- end -}}
