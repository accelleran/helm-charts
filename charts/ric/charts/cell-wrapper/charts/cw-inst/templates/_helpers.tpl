{{/*
Replicas for the deployment
*/}}
{{- define "cw-inst.replicas" -}}
{{- default (add (len .Values.global.config.dus) .Values.spareInstanceCount) .Values.replicaCount -}}
{{- end }}
