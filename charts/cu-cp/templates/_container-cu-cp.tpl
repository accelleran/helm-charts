{{- define "accelleran.cu-cp.container" -}}
{{- include
      "accelleran.common.container"
      (fromYaml (include "accelleran.cu-cp.container.args" .))
-}}
{{- end -}}


{{- define "accelleran.cu-cp.container.args" -}}
{{- $ := . -}}

top:
  {{ $ | toYaml | nindent 2 }}

env:
  - name: __APPNAME
    value: cuCp
{{- with (include "accelleran.common.bootstrap.instanceId" (dict "top" $)) }}
  - name: INSTANCE_FILTER
    value: {{ . | quote }}
{{- end }}
envFrom:
  - configMapRef:
      name: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}
