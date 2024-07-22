{{- define "accelleran.common.ingress" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common ingress" -}}
{{- $values := get . "values" | default $.Values -}}

{{- if $values.ingress.enabled -}}

{{- $name := include "accelleran.common.ingress.name" . -}}
{{- $annotations := include "accelleran.common.ingress.annotations" . | fromYaml -}}

{{- $svcName := include "accelleran.common.service.name" . }}

apiVersion: networking.k8s.io/v1
kind: Ingress
{{ include "accelleran.common.metadata" (mergeOverwrite (deepCopy .) (dict "name" $name "annotations" $annotations)) }}
spec:
  {{- with ($values.ingress).className }}
  ingressClassName: {{ . }}
  {{- end }}
  {{- if ($values.ingress).tls }}
  tls:
    {{- range ($values.ingress).tls }}
    - 
      {{- with .hosts }}
      hosts:
        {{- range . }}
        - {{ . | quote }}
        {{- end }}
      {{- end }}
      {{- with .secretName }}
      secretName: {{ . | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
  rules:
    {{- range $hostIndex, $hostDetails := $values.ingress.hosts }}
    {{- $host := $hostDetails.host }}
    - {{- with $host }}
      host: {{ . | quote }}
      {{- end }}
      http:
        paths:
          {{- range $hostDetails.paths }}
          {{- $path := .path | default "/" }}
          {{- $portName := .port | required (printf "A port needs to be provided to ingress host %v with path %v" ($host | default $hostIndex) $path) }}
          {{- $svcPort := (get (($values.service).ports) $portName).port | required (printf "A port number needs to be provided to port %v of service %v" $portName $svcName) }}
          - path: {{ $path }}
            {{- with .pathType }}
            pathType: {{ . }}
            {{- end }}
            backend:
              service:
                name: {{ $svcName }}
                port:
                  number: {{ $svcPort }}
          {{- end }}
    {{- end }}
{{- end -}}

{{- end -}}


{{- define "accelleran.common.ingress.name" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common ingress name" -}}
{{- $values := get . "values" | default $.Values -}}

{{- get . "name" | default (get $values.ingress "name") | default (include "accelleran.common.fullname" .) -}}
{{- end -}}


{{- define "accelleran.common.ingress.annotations" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common ingress annotations" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with (get $values.ingress "annotations") -}}
{{- . | toYaml -}}
{{- end -}}
{{- end -}}
