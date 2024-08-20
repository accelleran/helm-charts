{{- define "accelleran.common.init.container" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init container" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $name := get . "name"  | required "Name needs to be provided to common init container" -}}
{{- $command := get . "command"  | required "Command needs to be provided to common init container" -}}

{{ include "accelleran.common.container"
    (mergeOverwrite
      (deepCopy .)
      (dict
        "values" (mergeOverwrite
          (deepCopy $values)
          (include "accelleran.common.init.container.args" . | fromYaml)
        )
      )
    )
}}
{{- end -}}


{{- define "accelleran.common.init.container.args" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init container" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $name := get . "name" | required "Name needs to be provided to common init container args" -}}
{{- $command := get . "command" -}}

containerName: {{ $name | quote }}

{{- with $command }}
command:
  {{- $command | toYaml | nindent 2 }}
{{- end }}

# prevent warning of duplicate port definition
service:
  enabled: false
{{- end -}}


{{/*
Init container check waiting until redis is available
*/}}
{{- define "accelleran.common.init.redis" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init redis" -}}

{{ include "accelleran.common.init.container"
    (include "accelleran.common.init.redis.args" . | fromYaml)
}}
{{- end -}}


{{- define "accelleran.common.init.redis.args" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init redis args" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $bootstrapConfigMapName :=  get . "bootstrapConfigMapName" | default (include "accelleran.common.bootstrap.configMapName" .) -}}
{{- $image := $values.redisInitImage | required "The redis init image needs to be provided to common init redis args" -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{
    (mergeOverwrite
      (deepCopy $values)
      (dict "image" $image)
    ) | toYaml | nindent 2
  }}

name: check-redis
command:
- "/bin/sh"
- "-c"
- |
    until [ "$(timeout 10s redis-cli -h ${REDIS_HOSTNAME} -p ${REDIS_PORT} ping)" == "PONG" ]
    do
      sleep 1
    done
    echo "$(date) Redis ready"
env:
- name: REDIS_HOSTNAME
  valueFrom:
    configMapKeyRef:
      name: {{ $bootstrapConfigMapName | quote }}
      key: REDIS_HOSTNAME
- name: REDIS_PORT
  valueFrom:
    configMapKeyRef:
      name: {{ $bootstrapConfigMapName | quote }}
      key: REDIS_PORT
{{- end -}} 


{{/*
Init container check waiting until NATS is available
*/}}
{{- define "accelleran.common.init.nats" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init nats" -}}

{{ include "accelleran.common.init.container"
    (include "accelleran.common.init.nats.args" . | fromYaml)
}}
{{- end -}}

{{- define "accelleran.common.init.nats.args" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init nats args" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $bootstrapConfigMapName := get . "bootstrapConfigMapName" | default (include "accelleran.common.bootstrap.configMapName" .)  -}}
{{- $image := $values.natsInitImage | required "The nats init image needs to be provided to common init nats args" -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{
    (mergeOverwrite
      (deepCopy $values)
      (dict "image" $image)
    ) | toYaml | nindent 2
  }}


name: check-nats
command:
  - "/bin/sh"
  - "-c"
  - |
    until nc -z -v -w1 ${NATS_HOSTNAME} ${NATS_PORT}
    do
      sleep 1
    done
    echo "$(date) NATS ready"
env:
  - name: NATS_HOSTNAME
    valueFrom:
      configMapKeyRef:
        name: {{ $bootstrapConfigMapName | quote }}
        key: NATS_HOSTNAME
  - name: NATS_PORT
    valueFrom:
      configMapKeyRef:
        name: {{ $bootstrapConfigMapName | quote }}
        key: NATS_PORT
{{- end -}} 


{{/*
Init container check waiting until kafka is available
*/}}
{{- define "accelleran.common.init.kafka" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init kafka" -}}

{{ include "accelleran.common.init.container"
    (include "accelleran.common.init.kafka.args" . | fromYaml)
}}
{{- end -}}

{{- define "accelleran.common.init.kafka.args" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common init kafka args" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $bootstrapConfigMapName := get . "bootstrapConfigMapName" | default (include "accelleran.common.bootstrap.configMapName" .)  -}}
{{- $image := $values.kafkaInitImage | required "The kafka init image needs to be provided to common init kafka args" -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{
    (mergeOverwrite
      (deepCopy $values)
      (dict "image" $image)
    ) | toYaml | nindent 2
  }}


name: check-kafka
command:
  - "/bin/sh"
  - "-c"
  - |
    until kcat -b "${KAFKA_HOSTNAME}:${KAFKA_PORT}" -t kafka-cluster-init -C -o -1 -e
    do
      sleep 1
    done
    echo "$(date) Kafka ready"
env:
  - name: KAFKA_HOSTNAME
    valueFrom:
      configMapKeyRef:
        name: {{ $bootstrapConfigMapName | quote }}
        key: KAFKA_HOSTNAME
  - name: KAFKA_PORT
    valueFrom:
      configMapKeyRef:
        name: {{ $bootstrapConfigMapName | quote }}
        key: KAFKA_PORT
{{- end -}} 
