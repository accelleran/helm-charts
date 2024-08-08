{{- define "accelleran.common.pod" -}}
apiVersion: v1
kind: Pod
{{ toYaml (merge
    (fromYaml (include "accelleran.common.metadata" .))
    (fromYaml (include "accelleran.common.pod.tpl" .))
) }}
{{- end -}}


{{- define "accelleran.common.pod.tpl" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod tpl" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $restartPolicy := get . "restartPolicy" -}}
{{- $initContainers := get . "initContainers" | default list -}}
{{- $containers := get . "containers" -}}
{{- if not $containers -}}
{{/*
Cannot use default as then the template is always evaluated
*/}}
{{-  $containers = list (fromYaml (include "accelleran.common.container" .)) -}}
{{- end -}}

{{- $volumes := list -}}
{{- if eq (include "accelleran.common.drax.license.enabled" .) "true" -}}
{{- $volumes = append $volumes (fromYaml (include "accelleran.common.drax.license.volume" .)) -}}
{{- end -}}
{{- with (get . "volumes") -}}
{{- $volumes = concat $volumes . -}}
{{- end -}}
{{- with $values.extraVolumes -}}
{{- $volumes = concat $volumes . -}}
{{- end -}}

metadata:
  labels:
    {{- include "accelleran.common.labels" . | nindent 4 }}
    {{- with $values.podLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $values.podAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with $restartPolicy }}
  restartPolicy: {{ . }}
  {{- end }}

  {{- if gt (len $volumes) 0 }}
  volumes:
    {{- range $volumes }}
    - {{- tpl (toYaml .) $ | nindent 6 }}
    {{- end }}
  {{- end }}

  {{- if gt (len $initContainers) 0 }}
  initContainers:
    {{- range $initContainers }}
    - {{- tpl (toYaml .) $ | nindent 6 }}
    {{- end }}
  {{- end }}

  containers:
    {{- range (required "A pod requires at least 1 container." $containers) }}
    - {{ tpl (toYaml .) $ | nindent 6 }}
    {{- end -}}

  {{- include "accelleran.common.pod.config" . | nindent 2 }}
{{- end -}}


{{- define "accelleran.common.pod.config" -}}
{{ include "accelleran.common.pod.imagePullSecrets" . }}
{{ include "accelleran.common.pod.serviceAccountName" . }}
{{ include "accelleran.common.pod.hostNetwork" . }}
{{ include "accelleran.common.pod.dnsPolicy" . }}
{{ include "accelleran.common.pod.securityContext" . }}
{{ include "accelleran.common.pod.nodeName" . }}
{{ include "accelleran.common.pod.nodeSelector" . }}
{{ include "accelleran.common.pod.affinity" . }}
{{ include "accelleran.common.pod.tolerations" . }}
{{- end -}}


{{- define "accelleran.common.pod.imagePullSecrets" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod image pull secret" -}}
{{- $values := get . "values" | default $.Values -}}

{{- if or $values.imagePullSecrets ($.Values.global).imagePullSecrets -}}
imagePullSecrets:
  {{- if $values.imagePullSecrets -}}
  {{- toYaml $values.imagePullSecrets | nindent 2 }}
  {{- else if ($.Values.global).imagePullSecrets -}}
  {{- toYaml $.Values.global.imagePullSecrets | nindent 2 }}
  {{- end -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.pod.serviceAccountName" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod service account name" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $serviceAccountName := include "accelleran.common.serviceAccount.name" . -}}
{{- with $serviceAccountName }}
serviceAccountName: {{ . | quote }}
{{- end }}
{{- end -}}


{{- define "accelleran.common.pod.hostNetwork" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod host network" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with $values.hostNetwork }}
hostNetwork: {{ . }}
{{- end }}
{{- end -}}


{{- define "accelleran.common.pod.dnsPolicy" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod DNS policy" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with $values.dnsPolicy }}
dnsPolicy: {{ . | quote }}
{{- end }}
{{- end -}}


{{- define "accelleran.common.pod.securityContext" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod security context" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with $values.podSecurityContext -}}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.pod.nodeName" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod node name" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with $values.nodeName -}}
nodeName:
  {{- toYaml . | nindent 2 }}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.pod.nodeSelector" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod node selector" -}}
{{- $values := get . "values" | default $.Values -}}

{{- if or $values.nodeSelector ($.Values.global).nodeSelector -}}
nodeSelector:
  {{- if $values.nodeSelector -}}
  {{- toYaml $values.nodeSelector | nindent 2 }}
  {{- else if ($.Values.global).nodeSelector -}}
  {{- toYaml $.Values.global.nodeSelector | nindent 2 }}
  {{- end -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.pod.affinity" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod affinity" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with $values.affinity -}}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.pod.tolerations" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pod tolerations" -}}
{{- $values := get . "values" | default $.Values -}}

{{- with $values.tolerations -}}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end -}}
{{- end -}}
