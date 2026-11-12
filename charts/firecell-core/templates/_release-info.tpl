{{/*
Images of the pods the given templates render, as JSON:
{"<workload>/<container>": "<image>"}, init containers included. The
templates are rendered here exactly as they are for the release, so the map
cannot disagree with the pods. Every template that renders a pod must be in
the list in release-info.yaml.
Usage: include "firecell-5gc.releaseInfo.images" (dict "root" $ "templates" (list "deployment.yaml"))
*/}}
{{- define "firecell-5gc.releaseInfo.images" -}}
{{- $root := .root -}}
{{- $images := dict -}}
{{- range $path := .templates -}}
{{- $text := include (printf "%s/%s" $root.Template.BasePath $path) $root -}}
{{- range $doc := regexSplit "(?m)^---[ \\t]*$" $text -1 -}}
{{- $obj := fromYaml $doc | default dict -}}
{{- $kind := toString ($obj.kind | default "") -}}
{{- $pod := dict -}}
{{- if has $kind (list "Deployment" "StatefulSet" "DaemonSet" "ReplicaSet" "Job") -}}
{{- $pod = $obj.spec.template.spec -}}
{{- else if eq $kind "CronJob" -}}
{{- $pod = $obj.spec.jobTemplate.spec.template.spec -}}
{{- end -}}
{{- range $c := concat ($pod.initContainers | default (list)) ($pod.containers | default (list)) -}}
{{- $_ := set $images (printf "%s/%s" $obj.metadata.name $c.name) (toString $c.image) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toJson $images -}}
{{- end -}}

{{/*
This render as a release record: release, namespace, chart, appVersion,
revision, renderedAt (UTC), valuesDigest and images. The values only enter
as a digest, so no setting, password or Secret content ever lands here.
Usage: include "firecell-5gc.releaseInfo.record" (dict "root" $ "namespace" $ns "templates" (list ...))
*/}}
{{- define "firecell-5gc.releaseInfo.record" -}}
{{- $root := .root -}}
{{- toJson (dict
  "release" $root.Release.Name
  "namespace" .namespace
  "chart" (printf "%s-%s" $root.Chart.Name $root.Chart.Version)
  "appVersion" $root.Chart.AppVersion
  "revision" $root.Release.Revision
  "renderedAt" (dateInZone "2006-01-02T15:04:05Z07:00" (now) "UTC")
  "valuesDigest" (printf "sha256:%s" (toJson $root.Values | sha256sum))
  "images" (include "firecell-5gc.releaseInfo.images" (dict "root" $root "templates" .templates) | fromJson)
) -}}
{{- end -}}

{{/*
Earlier release records, newest first, at most 20: the previous record and
history of the live ConfigMap (live, from lookup). Empty when lookup finds
nothing (first install, helm template, client-side dry run). A re-render of
the same revision adds nothing.
Usage: include "firecell-5gc.releaseInfo.history" (dict "root" $ "live" (lookup "v1" "ConfigMap" $ns $name))
*/}}
{{- define "firecell-5gc.releaseInfo.history" -}}
{{- $history := list -}}
{{- $live := .live -}}
{{- if $live -}}
{{- $data := $live.data | default dict -}}
{{- range fromJsonArray (get $data "history.json" | default "[]") -}}
{{- if and (kindIs "map" .) (hasKey . "revision") -}}
{{- $history = append $history . -}}
{{- end -}}
{{- end -}}
{{- $previous := fromJson (get $data "release.json" | default "{}") -}}
{{- if and (hasKey $previous "revision") (ne (toString $previous.revision) (toString .root.Release.Revision)) -}}
{{- $history = prepend $history $previous -}}
{{- end -}}
{{- end -}}
{{- if gt (len $history) 20 -}}
{{- $history = slice $history 0 20 -}}
{{- end -}}
{{- toJson $history -}}
{{- end -}}
