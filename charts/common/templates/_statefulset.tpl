{{- define "accelleran.common.statefulset" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common statefulset" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $persistence := $values.persistence -}}
{{- if and (ne $persistence nil) (not (kindIs "slice" $persistence)) -}}
{{- fail "Volume claim templates need to be provided as a list to common statefulset" -}}
{{- end -}}

{{- $autoscaling := default (dict "enabled" false) (get $values "autoscaling") -}}
{{- $serviceName := printf "%s-headless" (include "accelleran.common.service.name" .) -}}

{{- $volumeClaimTemplates := list -}}
{{- range $persistence -}}
{{- $volumeClaimTemplates = append $volumeClaimTemplates (fromYaml (include "accelleran.common.statefulset.volumeClaimTemplate" (dict "top" $ "volumeClaimTemplate" .))) -}}
{{- end -}}

{{- $volumeMounts := list -}}
{{- with (get . "volumeMounts") -}}
{{- $volumeMounts = concat $volumeMounts . -}}
{{- end -}}
{{- range $persistence -}}
{{- $volumeMounts = append $volumeMounts (dict "name" .name "mountPath" .mountPath) -}}
{{- end -}}

{{- include "accelleran.common.statefulset.headlessService" (mergeOverwrite (deepCopy .) (dict "name" $serviceName)) }}
---
apiVersion: apps/v1
kind: StatefulSet
{{ include "accelleran.common.metadata" . }}
spec:
  {{- if ne $values.replicaCount nil }}
  replicas: {{ $values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "accelleran.common.selectorLabels" . | nindent 6 }}
  serviceName: {{ $serviceName | quote }}
  template:
    {{- include "accelleran.common.pod.tpl" (mergeOverwrite (deepCopy .) (dict "volumeMounts" $volumeMounts)) | nindent 4 }}
  {{- with $volumeClaimTemplates }}
  volumeClaimTemplates: {{ . | toYaml | nindent 4 }}
  {{- end }}
{{- end -}}


{{- define "accelleran.common.statefulset.headlessService" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common statefulset headless service" -}}
{{- $values := get . "values" | default $.Values -}}

{{- include "accelleran.common.service" (mergeOverwrite (deepCopy .) (dict "values" $values) (fromYaml (include "accelleran.common.statefulset.headlessService.valuesOverwrite" .))) }}
{{- end -}}


{{- define "accelleran.common.statefulset.headlessService.valuesOverwrite" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common statefulset headless service values overwrite" -}}

values:
  service:
    enabled: true
    type: "ClusterIP"
    clusterIP: "None"
    externalTrafficPolicy: null
{{- end -}}


{{- define "accelleran.common.statefulset.volumeClaimTemplate" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common statefulset volume claim template" -}}
{{- $volumeClaimTemplate := get . "volumeClaimTemplate" -}}

metadata:
  name: {{ $volumeClaimTemplate.name }}
spec:
  accessModes: {{ $volumeClaimTemplate.accessModes | default (list "ReadWriteOnce") | toYaml | nindent 2 }}
  {{- with $volumeClaimTemplate.storageClassName }}
  storageClassName: {{ . | quote }}
  {{- end }}
  resources:
    requests:
      storage: {{ $volumeClaimTemplate.size }}
{{- end -}}
