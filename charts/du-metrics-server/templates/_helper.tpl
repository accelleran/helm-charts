{{/*
Init container check waiting until influxdb is available
*/}}
{{- define "accelleran.du-metrics-server.init.influxdb" -}}
{{- $ := get . "top" | required "The top context needs to be provided to du metrics server init influxdb" -}}

{{ include "accelleran.common.init.container"
    (include "accelleran.du-metrics-server.init.influxdb.args" . | fromYaml)
}}
{{- end -}}


{{- define "accelleran.du-metrics-server.init.influxdb.args" -}}
{{- $ := get . "top" | required "The top context needs to be provided to du metrics server init influxdb args" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $image := ($values.initImage).influxdb | required "The influxdb init image needs to be provided to du metrics server init influxdb args" -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{
    (mergeOverwrite
      (deepCopy $values)
      (dict "image" $image)
    ) | toYaml | nindent 2
  }}

name: check-influxdb
command:
- "/bin/sh"
- "-c"
- |
    until (timeout 10s curl -sL -I {{ printf "http://%s/ping?wait_for_leader=5s" (printf "%s.%s:%v" ($.Values.influxdb.fullnameOverride | default (printf "%s-%s" $.Release.Name ($.Values.influxdb.nameOverride | default "influxdb"))) $.Release.Namespace $.Values.influxdb.service.port) }} > /dev/null 2>&1)
    do
        sleep 1
    done
    echo "$(date) InfluxDB ready"
{{- end -}} 
