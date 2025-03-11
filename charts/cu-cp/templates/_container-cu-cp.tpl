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
values:
  {{
    mergeOverwrite
      (omit $.Values "service")
      (dict "service"
        (mergeOverwrite
          (omit $.Values.service "ports")
          (dict "ports" (pick $.Values.service.ports "e1ap" "f1ap"))
        )
      ) | toYaml | nindent 2
  }}

env:
  - name: __APPNAME
    value: cuCp
{{- with (include "accelleran.common.bootstrap.instanceId" (dict "top" $)) }}
  - name: INSTANCE_FILTER
    value: {{ . | quote }}
{{- end }}
  - name: LICENSE_PATH
    value: {{ printf "%s/license.crt" (include "accelleran.common.drax.license.mountPath" (dict "top" $)) | quote }}
envFrom:
  - configMapRef:
      name: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}
{{- end -}}
