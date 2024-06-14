{{/*
Expand the name of the chart.
*/}}
{{- define "accelleran.common.name" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common name" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $name := get $values "nameOverride" | default (get $.Values "nameOverride") | default $.Chart.Name -}}

{{- if not $name -}}
{{- /*
Work-around as .Chart.Name is undefined with (de)serializations (from/toYaml)
This can not be used with `default` as then it would be evaluated,
resulting in a failure when no (de)serializations took place.
*/ -}}
{{- $name = $.Chart.name -}}
{{- end -}}

{{- $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).

We consciously differ here from the standard Helm helper template.

The standard template usually uses the release name as the full name, if it contains the chart name.
We have chosen not to do that as it has caused issues for us in the past, when subchart names are contained
within the release name.
*/}}
{{- define "accelleran.common.fullname" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common full name" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $fullnameOverride := get $values "fullnameOverride" | default (get $.Values "fullnameOverride") -}}

{{- if $fullnameOverride -}}
{{- $fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $instance := include "accelleran.common.instance" . -}}
{{- $name := include "accelleran.common.name" . -}}
{{- printf "%s-%s" $instance $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Unique name for this instance of the chart
*/}}
{{- define "accelleran.common.instance" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common instance" -}}

{{- $instance := $.Release.Name -}}
{{- if not $instance -}}
{{- /*
Work-around as .Release.Name is undefined with (de)serializations (from/toYaml)
This can not be used with `default` as then it would be evaluated,
resulting in a failure when no (de)serializations took place.
*/ -}}
{{- $instance = $.Release.name -}}
{{- end -}}
{{- $instance -}}
{{- end -}}


{{- define "accelleran.common.component" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common part of" -}}
{{- $values := get . "values" | default $.Values -}}

{{- $values.component | default "" -}}
{{- end -}}


{{- define "accelleran.common.partOf" -}}
{{- $ := get . "top" | required "The top context needs to be provided to common part of" -}}

{{- ($.Values.global).partOf | default "" -}}
{{- end -}}
