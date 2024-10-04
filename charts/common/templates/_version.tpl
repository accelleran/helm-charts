{{/*
Version of application to be deployed
*/}}
{{- define "accelleran.common.appVersion" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common app version" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $version := ($values.image).tag | default ($.Values.global).tag | default $.Chart.AppVersion -}}

{{- if not $version -}}
{{- /*
Work-around as .Chart.AppVersion is undefined with (de)serializations (from/toYaml)
This can not be used with `default` as then it would be evaluated,
resulting in a failure when no (de)serializations took place.
*/ -}}
{{- $chart := $.Chart | toYaml | fromYaml -}}
{{- with get $chart "appVersion" -}}
{{- $version = . -}}
{{- end -}}
{{- end -}}

{{- $version -}}
{{- end -}}


{{/*
Version of the Helm chart
*/}}
{{- define "accelleran.common.helmVersion" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common helm version" -}}

{{- $version := $.Chart.Version -}}

{{- if not $version -}}
{{- /*
Work-around as .Chart.Version is undefined with (de)serializations (from/toYaml)
This can not be used with `default` as then it would be evaluated,
resulting in a failure when no (de)serializations took place.
*/ -}}
{{- $version = $.Chart.version -}}
{{- end -}}

{{- $version -}}
{{- end -}}
