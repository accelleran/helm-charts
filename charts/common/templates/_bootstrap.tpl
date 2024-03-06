{{- define "accelleran.common.bootstrap.configMap" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap config map" -}}

{{- if eq (include "accelleran.common.bootstrap.configMap.create" .) "true" -}}
{{- include
      "accelleran.common.configMap"
      (fromYaml (include "accelleran.common.bootstrap.configMap.args" .))
-}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.bootstrap.configMap.args" -}}
{{- $ := get . "top" | required "The top context needs to be provided common bootstrap config map args" -}}
{{- $values := get . "values" | default $.Values -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ $values | toYaml | nindent 2 }}

name: {{ include "accelleran.common.bootstrap.configMapName" . | quote }}

data:
  {{- with (include "accelleran.common.bootstrap.redis.hostname" .) }}
  REDIS_HOSTNAME: {{ . | quote }}
  {{- end }}
  {{- with (include "accelleran.common.bootstrap.redis.port" .) }}
  REDIS_PORT: {{ . | quote }}
  {{- end }}
  {{- with ( include "accelleran.common.bootstrap.nats.hostname" .) }}
  NATS_HOSTNAME: {{ . | quote }}
  {{- end }}
  {{- with ( include "accelleran.common.bootstrap.nats.port" .) }}
  NATS_PORT: {{ . | quote }}
  {{- end }}
  {{- with ( include "accelleran.common.bootstrap.kafka.hostname" .) }}
  KAFKA_HOSTNAME: {{ . | quote }}
  {{- end }}
  {{- with ( include "accelleran.common.bootstrap.kafka.port" .) }}
  KAFKA_PORT: {{ . | quote }}
  {{- end }}
{{- end -}}


{{- define "accelleran.common.bootstrap.configMap.create" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap create" -}}
{{ ($.Values.bootstrap).create | default false }}
{{- end -}}


{{- define "accelleran.common.bootstrap.configMapName" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap config map name" -}}
{{ tpl (($.Values.bootstrap).name | default (printf "%s-bootstrap" (include "accelleran.common.fullname" .))) $ }}
{{- end -}}


{{- define "accelleran.common.bootstrap.instanceId" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap instance id" -}}

{{- $instanceId := ($.Values.bootstrap).instanceId -}}
{{- if $instanceId -}}
{{- $instanceId = tpl (toString $instanceId) $ -}}
{{- if not (and (regexMatch "^[a-z]([a-z0-9-]*[a-z0-9])?$" $instanceId) (le (len $instanceId) 16)) }}
{{- required "The Instance ID you have chosen is invalid! The Instance ID must consist of lower case alphanumeric characters or '-', start with an alphabetic character, and end with an alphanumeric character (e.g. 'my-name',  or 'abc-123', regex used for validation is '^[a-z]([a-z0-9-]*[a-z0-9])?$'). The Instance ID also cannot be longer than 16 alphanumeric characters!" nil }}
{{- else -}}
{{- $instanceId -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.bootstrap.redis.hostname" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap redis hostname" -}}

{{- if (($.Values.bootstrap).redis).enabled -}}
{{- $redisHostname := tpl ((($.Values.bootstrap).redis).hostname) $ -}}
{{- if and (eq (include "accelleran.common.bootstrap.configMap.create" .) "true") (not (($.Values.redis).enabled)) (not $redisHostname) -}}
{{- fail (
  printf
  "When redis is disabled a bootstrap redis hostname needs to be provided when creating a bootstrap configmap in the %s chart (bootstrap.redis.hostname). More info at %s"
  (include "accelleran.common.name" .)
  "https://github.com/accelleran/helm-charts/tree/main/charts/common#bootstrap-hostnames"
  )
-}}
{{- end -}}
{{- $redisHostname | default (printf "%s-redis-master" $.Release.Name) -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.bootstrap.redis.port" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap redis port" -}}
{{- if (($.Values.bootstrap).redis).enabled -}}
{{- tpl (toString ((($.Values.bootstrap).redis).port | default 6379)) $ -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.bootstrap.nats.hostname" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap nats hostname" -}}

{{- if (($.Values.bootstrap).nats).enabled -}}
{{- $natsHostname := tpl ((($.Values.bootstrap).nats).hostname) $ -}}
{{- if and (eq (include "accelleran.common.bootstrap.configMap.create" .) "true") (not (($.Values.nats).enabled)) (not $natsHostname) -}}
{{- fail (
  printf
  "When nats is disabled a bootstrap nats hostname needs to be provided when creating a bootstrap configmap in the %s chart (bootstrap.nats.hostname). More info at %s"
  (include "accelleran.common.name" .)
  "https://github.com/accelleran/helm-charts/tree/main/charts/common#bootstrap-hostnames"
  )
-}}
{{- end -}}
{{- $natsHostname | default (printf "%s-nats" $.Release.Name) -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.bootstrap.nats.port" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap nats port" -}}
{{- if (($.Values.bootstrap).nats).enabled -}}
{{- tpl (toString ((($.Values.bootstrap).nats).port | default 4222)) $ -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.bootstrap.kafka.hostname" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap kafka hostname" -}}

{{- if (($.Values.bootstrap).kafka).enabled -}}
{{- $kafkaHostname := tpl ((($.Values.bootstrap).kafka).hostname) $ -}}
{{- if and (eq (include "accelleran.common.bootstrap.configMap.create" .) "true") (not (($.Values.kafka).enabled)) (not $kafkaHostname) -}}
{{- fail "When kafka is disabled a bootstrap kafka hostname needs to be provided when creating a bootstrap configmap (bootstrap.kafka.hostname). More info at https://github.com/accelleran/helm-charts/tree/main/charts/common#bootstrap-hostnames" -}}
{{- fail (
  printf
  "When kafka is disabled a bootstrap kafka hostname needs to be provided when creating a bootstrap configmap in the %s chart (bootstrap.kafka.hostname). More info at %s"
  (include "accelleran.common.name" .)
  "https://github.com/accelleran/helm-charts/tree/main/charts/common#bootstrap-hostnames"
  )
-}}
{{- end -}}
{{- $kafkaHostname | default (printf "%s-kafka" $.Release.Name) -}}
{{- end -}}
{{- end -}}


{{- define "accelleran.common.bootstrap.kafka.port" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common bootstrap kafka port" -}}
{{- if (($.Values.bootstrap).kafka).enabled -}}
{{- tpl (toString ((($.Values.bootstrap).kafka).port | default 9092)) $ -}}
{{- end -}}
{{- end -}}
