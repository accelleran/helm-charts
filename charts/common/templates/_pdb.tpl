{{- define "accelleran.common.pdb" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common pdb" -}}
{{- $values := get . "values" | default $.Values -}}

{{- if ($values.pdb).create }}
apiVersion: policy/v1
kind: PodDisruptionBudget
{{ include "accelleran.common.metadata" . }}
spec:
  selector:
    matchLabels: {{- include "accelleran.common.selectorLabels" . | nindent 6 }}
{{- if ($values.pdb).minAvailable }}
  minAvailable: {{ ($values.pdb).minAvailable }}
{{- end }}
{{- if or ($values.pdb).maxUnavailable (not ($values.pdb).minAvailable) }}
  maxUnavailable: {{ ($values.pdb).maxUnavailable | default 1 }}
{{- end }}
{{- end }}
{{- end -}}
