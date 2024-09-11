{{- define "accelleran.common.service" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common service" -}}
{{- $values := get . "values" | default $.Values -}}

{{- if ($values.service).enabled -}}

{{- $name := include "accelleran.common.service.name" . -}}
{{- $annotations := include "accelleran.common.service.annotations" . | fromYaml -}}
{{- $type := $values.service.type | default "ClusterIP" -}}

apiVersion: v1
kind: Service
{{ include "accelleran.common.metadata" (mergeOverwrite (deepCopy .) (dict "name" $name "annotations" $annotations)) }}
spec:
  selector:
    {{- include "accelleran.common.selectorLabels" . | nindent 4 }}
  type: {{ $type }}
  {{- with $values.service.clusterIP }}
  clusterIP: {{ . }}
  {{- end }}
  {{- if eq $type "LoadBalancer" -}}
  {{- with $values.service.loadBalancerIP }}
  loadBalancerIP: {{ . }}
  {{- end }}
  {{- end }}
  {{- with $values.service.externalTrafficPolicy }}
  externalTrafficPolicy: {{ . }}
  {{- end }}
  {{- include "accelleran.common.service.ports" . | nindent 2 }}
{{- end -}}

{{- end -}}


{{- define "accelleran.common.service.name" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common service name" -}}
{{- $values := get . "values" | default $.Values -}}

{{- get . "name" | default (get $values.service "name") | default (include "accelleran.common.fullname" .) -}}
{{- end -}}


{{- define "accelleran.common.service.annotations" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common service annotations" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with (get $values.service "annotations") -}}
{{- . | toYaml -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.service.ports" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common service ports" -}}
{{- $values := get . "values" | default $.Values -}}
{{- $type := ($values.service).type | default "ClusterIP" -}}

ports:
{{- range $portName, $portDetails := (($values.service).ports | required "A service requires at least 1 port.") }}
  - name: {{ $portName }}
    {{- with $portDetails.appProtocol }}
    appProtocol: {{ . }}
    {{- end }}
    {{- with $portDetails.protocol }}
    protocol: {{ . }}
    {{- end }}
    port: {{ $portDetails.port | required (printf "A port number needs to be provided to port %v" $portName) }}
    {{- with $portDetails.targetPort }}
    targetPort: {{ . }}
    {{- end }}
    {{- if eq $type "NodePort" -}}
    {{- with $portDetails.nodePort }}
    nodePort: {{ . }}
    {{- end }}
    {{- end -}}
{{- end -}}
{{- end -}}
