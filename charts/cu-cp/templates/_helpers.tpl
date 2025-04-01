{{- define "accelleran.cu-cp.ueCount" -}}
{{- .Values.numOfUes -}}
{{- end -}}


{{- define "accelleran.cu-cp.init.args" -}}
{{- $ := . -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ mergeOverwrite (deepCopy $.Values) (fromYaml (include "accelleran.cu-cp.disabledLicense" .)) | toYaml | nindent 2 }}

bootstrapConfigMapName: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}


{{- define "accelleran.cu-cp.disabledLicense" -}}
accelleranLicense:
  enabled: false
{{- end -}}
