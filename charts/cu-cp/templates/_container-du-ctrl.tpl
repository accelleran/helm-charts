{{- define "accelleran.cu-cp.du-ctrl.container" -}}
{{- include
      "accelleran.common.container"
      (fromYaml (include "accelleran.cu-cp.du-ctrl.container.args" .))
-}}
{{- end -}}


{{- define "accelleran.cu-cp.du-ctrl.container.args" -}}
{{- $ := . -}}
{{- $values := index $.Values "du-ctrl" -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ $values | toYaml | nindent 2 }}

env:
  - name: __APPNAME
    value: duController
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
