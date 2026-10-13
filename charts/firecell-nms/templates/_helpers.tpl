{{/*
Expand the name of the chart.
*/}}
{{- define "firecell-nms.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "firecell-nms.labels" -}}
helm.sh/chart: {{ include "firecell-nms.name" . }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.global.pkgVersion | quote }}
app.kubernetes.io/part-of: firecell-nms
{{- end }}

{{/*
Build a full image reference: registry/image:vTag
*/}}
{{- define "firecell-nms.image" -}}
{{- printf "%s/%s:v%s" .registry .image .tag }}
{{- end }}

{{/*
Init container that waits for MySQL to be ready.
*/}}
{{- define "firecell-nms.waitForDb" -}}
- name: wait-for-db
  image: {{ .Values.global.busyboxImage | default (printf "%s/busybox:stable" .Values.global.imageRegistry) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  command:
    - /bin/sh
    - -c
    - |
      echo "Waiting for MySQL on db:3310..."
      until nc -z db 3310; do
        echo "MySQL not ready, retrying in 5s..."
        sleep 5
      done
      echo "MySQL is ready!"
{{- end }}

{{/*
Init container that waits for Redis to be ready.
*/}}
{{- define "firecell-nms.waitForRedis" -}}
- name: wait-for-redis
  image: {{ .Values.global.busyboxImage | default (printf "%s/busybox:stable" .Values.global.imageRegistry) }}
  imagePullPolicy: {{ .Values.global.imagePullPolicy }}
  command:
    - /bin/sh
    - -c
    - |
      echo "Waiting for Redis on redis-cache:6799..."
      until nc -z redis-cache 6799; do
        echo "Redis not ready, retrying in 3s..."
        sleep 3
      done
      echo "Redis is ready!"
{{- end }}
