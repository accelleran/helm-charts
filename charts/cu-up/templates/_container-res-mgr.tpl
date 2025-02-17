{{- define "accelleran.cu-up.res-mgr.container" -}}
{{- include
      "accelleran.common.container"
      (fromYaml (include "accelleran.cu-up.res-mgr.container.args" .))
-}}
{{- end -}}


{{- define "accelleran.cu-up.res-mgr.container.args" -}}
{{- $ := . -}}
{{- $values := index $.Values "res-mgr-up" -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ $values | toYaml | nindent 2 }}

env:
  - name: __APPNAME
    value: resourceManagerUp
{{- with (include "accelleran.common.bootstrap.instanceId" (dict "top" $)) }}
  - name: INSTANCE_FILTER
    value: {{ . | quote }}
{{- end }}
  - name: LICENSE_PATH
    value: {{ printf "%s/license.crt" (include "accelleran.common.drax.license.mountPath" (dict "top" $ "values" $values)) | quote }}
envFrom:
  - configMapRef:
      name: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}
