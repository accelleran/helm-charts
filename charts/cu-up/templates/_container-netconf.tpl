{{- define "accelleran.cu-up.netconf.container" -}}
{{- include
      "accelleran.common.container"
      (fromYaml (include "accelleran.cu-up.netconf.container.args" .))
-}}
{{- end -}}


{{- define "accelleran.cu-up.netconf.container.args" -}}
{{- $ := . -}}
{{- $values := $.Values.netconf -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ $values | toYaml | nindent 2 }}

env:
  - name: __APPNAME
    value: cuUpNetconf
{{- with (include "accelleran.common.bootstrap.instanceId" (dict "top" $)) }}
  - name: INSTANCE_FILTER
    value: {{ . | quote }}
{{- end }}
envFrom:
  - configMapRef:
      name: {{ include "accelleran.common.bootstrap.configMapName" (dict "top" $) | quote }}

{{- if gt (len $values.persistence) 0 }}
volumeMounts:
{{- range $values.persistence }}
  - name: {{ .name }}
    mountPath: {{ .mountPath }}
{{ end -}}
{{- end -}}

{{- end -}}
