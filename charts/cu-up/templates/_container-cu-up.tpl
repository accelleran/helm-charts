{{- define "accelleran.cu-up.container" -}}
{{- include
      "accelleran.common.container"
      (fromYaml (include "accelleran.cu-up.container.args" .))
-}}
{{- end -}}


{{- define "accelleran.cu-up.container.args" -}}
{{- $ := . -}}

top:
  {{ $ | toYaml | nindent 2 }}

env:
  - name: __APPNAME
    value: cuUp
{{- with (include "accelleran.common.bootstrap.instanceId" (dict "top" $)) }}
  - name: INSTANCE_FILTER
    value: {{ . | quote }}
{{- end }}
  - name: LICENSE_PATH
    value: {{ include "accelleran.common.drax.license.mountPath" (dict "top" $) | quote }}
envFrom:
  - configMapRef:
      name: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}
