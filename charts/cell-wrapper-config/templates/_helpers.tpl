{{/*
Number of configured DUs
*/}}
{{- define "accelleran.cell-wrapper.duCount" -}}
{{- len .Values.global.config.dus -}}
{{- end -}}


{{/*
Number of configured RUs
*/}}
{{- define "accelleran.cell-wrapper.ruCount" -}}
{{- $nRus := 0 -}}
{{- range $index, $du := .Values.global.config.dus -}}
  {{- $nRus = add $nRus (len (default list $du.rus)) -}}
{{- end -}}
{{- $nRus -}}
{{- end -}}


{{- define "accelleran.cell-wrapper.netconf.service.name" -}}
{{- $ := . -}}
{{ (($.Values.netconf).service).name | default (printf "%s-%s" (include "accelleran.common.name" (dict "top" $ "values" ($.Values).netconf)) (include "accelleran.common.bootstrap.instanceId" (dict "top" $ "values" ($.Values).netconf))) }}
{{- end -}}


{{- define "accelleran.cell-wrapper.netconf.secret.authentication.name" -}}
{{- $ := . -}}
{{ (($.Values.netconf).authentication).secretName | default (printf "%s-netconf-authentication" (include "accelleran.common.fullname" (dict "top" $ "values" $.Values.netconf))) }}
{{- end -}}


{{- define "accelleran.cell-wrapper.netconf.wait.container" -}}
{{- $ := . -}}
{{- $values := $.Values.netconf -}}
{{- include
      "accelleran.common.container"
      (fromYaml (include "accelleran.cell-wrapper.netconf.wait.container.args" $))
-}}
{{- end -}}


{{- define "accelleran.cell-wrapper.netconf.wait.container.args" -}}
{{- $ := . -}}
{{- $values := $.Values.netconf -}}

top:
  {{ $ | toYaml | nindent 2 }}
values:
  {{ (mergeOverwrite (deepCopy $values) (fromYaml (include "accelleran.cell-wrapper.netconf.wait.container.valueOverrides" .))) | toYaml | nindent 2 }}
{{- end -}}


{{- define "accelleran.cell-wrapper.netconf.wait.container.valueOverrides" -}}
{{- $ := . -}}
{{- $values := $.Values.netconf -}}

{{- $image := $values.netconfInitImage | required "The netconf init image needs to be provided to cell-wrapper netconf wait container value overrides" -}}

containerName: wait-for-netconf
image:
  {{ $image | toYaml | nindent 2 }}
command:
  - "/bin/sh"
args:
  - "-c"
  - |
    backoff=5

    rc=1
    i=0
    while [ "$rc" = 1 ] && [ "$i" -lt 5 ] ; do
      echo "Checking if netconf is ready"
      nc -z {{ include "accelleran.cell-wrapper.netconf.service.name" $ }} {{ ((($values.service).ports).netconf).port | default 8300 }} 2>/dev/null \
      && rc=0

      i=$((i+1))

      if [ "$rc" = 1 ] && [ "$i" -lt 5 ] ; then
        echo "Netconf is not ready - backing off for $backoff seconds"
        sleep $backoff
        backoff=$(( 2 * backoff ))
      fi
    done

    if [ $rc = 0 ] ; then
      echo "Netconf is ready!"
    else
      echo "Netconf is not ready - failed"
    fi

    exit $rc
{{- end -}}
