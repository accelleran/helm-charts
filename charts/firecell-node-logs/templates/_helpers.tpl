{{/*
Common labels.
*/}}
{{- define "firecell-node-logs.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/part-of: firecell-node-logs
{{- end }}

{{/*
Node label that picks a store profile.
*/}}
{{- define "firecell-node-logs.profileLabel" -}}
firecell.io/log-profile
{{- end }}

{{/*
Port of every store. Fixed: the NMS and vlagent rely on it.
*/}}
{{- define "firecell-node-logs.storePort" -}}
9428
{{- end }}

{{/*
Where vlagent writes: the store on its own node, through the Service with
internalTrafficPolicy Local.
*/}}
{{- define "firecell-node-logs.localStoreUrl" -}}
{{- printf "http://vlogs-local.%s.svc:%s/insert/native" .Release.Namespace (include "firecell-node-logs.storePort" .) -}}
{{- end }}

{{/*
Build a container image reference.
Usage: include "firecell-node-logs.image" (dict "global" .Values.global "image" .Values.store.image "name" "store.image")
global.imageRegistry replaces image.registry when set. digest, when set,
replaces the tag: registry/repository@digest.
*/}}
{{- define "firecell-node-logs.image" -}}
{{- $name := .name | default "image" -}}
{{- $img := .image | required (printf "firecell-node-logs: %s is required" $name) -}}
{{- if kindIs "string" $img -}}
{{- fail (printf "firecell-node-logs: %s must be a map with registry, repository and tag, not a full image string" $name) -}}
{{- end -}}
{{- $registry := .global.imageRegistry | default $img.registry | required (printf "firecell-node-logs: set %s.registry or global.imageRegistry" $name) -}}
{{- $repository := $img.repository | required (printf "firecell-node-logs: %s.repository is required" $name) -}}
{{- if $img.digest -}}
{{- printf "%s/%s@%s" $registry $repository $img.digest -}}
{{- else -}}
{{- $tag := $img.tag | required (printf "firecell-node-logs: %s.tag is required (or set %s.digest)" $name $name) -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}
{{- end -}}

{{/*
Fails unless a resources map stays out of whole CPUs. A whole-CPU request
can make the pod Guaranteed, and the static CPU manager then gives it
isolated cores the RAN needs.
Usage: include "firecell-node-logs.checkResources" (dict "resources" $r "name" "profiles.standard.resources")
*/}}
{{- define "firecell-node-logs.checkResources" -}}
{{- $cpu := toString (((.resources | default dict).requests | default dict).cpu | default "") -}}
{{- if $cpu -}}
{{- $milli := 0 -}}
{{- if hasSuffix "m" $cpu -}}
{{- $milli = int (trimSuffix "m" $cpu) -}}
{{- else if regexMatch "^[0-9]+$" $cpu -}}
{{- $milli = mul (int $cpu) 1000 -}}
{{- else -}}
{{- $milli = int (mulf (float64 $cpu) 1000) -}}
{{- end -}}
{{- if and (gt (int $milli) 0) (eq (mod (int $milli) 1000) 0) -}}
{{- fail (printf "firecell-node-logs: %s.requests.cpu is %s, a whole number of CPUs; request a fraction (e.g. 50m) so the pod stays in the shared CPU pool" .name $cpu) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
The enabled profiles after validation, as JSON: {"<name>": <profile>}.
Each profile gets its VictoriaLogs retention flags as environment
variables (dots become underscores with -envflag.enable).
*/}}
{{- define "firecell-node-logs.profiles" -}}
{{- $out := dict -}}
{{- range $name, $p := .Values.profiles -}}
{{- if and $p $p.enabled -}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]{0,38}[a-z0-9])?$" $name) -}}
{{- fail (printf "firecell-node-logs: profile name %q must be a lowercase DNS label of at most 40 characters" $name) -}}
{{- end -}}
{{- $period := toString ($p.retentionPeriod | required (printf "firecell-node-logs: profiles.%s.retentionPeriod is required" $name)) -}}
{{- $m := regexFindAll "^([0-9]+)([hdwMy])$" $period -1 -}}
{{- if not $m -}}
{{- fail (printf "firecell-node-logs: profiles.%s.retentionPeriod %q must be a whole number and a unit h, d, w, M or y (e.g. 7d)" $name $period) -}}
{{- end -}}
{{- $hours := mul (int (trimSuffix (regexFind "[hdwMy]$" $period) $period)) (get (dict "h" 1 "d" 24 "w" 168 "M" 720 "y" 8760) (regexFind "[hdwMy]$" $period)) -}}
{{- if lt (int $hours) 24 -}}
{{- fail (printf "firecell-node-logs: profiles.%s.retentionPeriod %q is below the VictoriaLogs minimum of 1d" $name $period) -}}
{{- end -}}
{{- $limit := $p.diskLimit | default dict -}}
{{- $env := dict "retentionPeriod" $period -}}
{{- if eq (toString $limit.kind) "bytes" -}}
{{- $v := toString ($limit.value | required (printf "firecell-node-logs: profiles.%s.diskLimit.value is required" $name)) -}}
{{- if not (regexMatch "^[0-9]+(\\.[0-9]+)?(KB|MB|GB|TB|KiB|MiB|GiB|TiB)?$" $v) -}}
{{- fail (printf "firecell-node-logs: profiles.%s.diskLimit.value %q is not a size (e.g. 5GiB)" $name $v) -}}
{{- end -}}
{{- $_ := set $env "retention_maxDiskSpaceUsageBytes" $v -}}
{{- else if eq (toString $limit.kind) "percent" -}}
{{- $v := toString ($limit.value | required (printf "firecell-node-logs: profiles.%s.diskLimit.value is required" $name)) -}}
{{- if or (not (regexMatch "^[0-9]+$" $v)) (lt (int $v) 1) (gt (int $v) 100) -}}
{{- fail (printf "firecell-node-logs: profiles.%s.diskLimit.value %q must be a whole percentage from 1 to 100" $name $v) -}}
{{- end -}}
{{- $_ := set $env "retention_maxDiskUsagePercent" $v -}}
{{- else -}}
{{- fail (printf "firecell-node-logs: profiles.%s.diskLimit.kind must be bytes or percent, not %q" $name (toString $limit.kind)) -}}
{{- end -}}
{{- include "firecell-node-logs.checkResources" (dict "resources" $p.resources "name" (printf "profiles.%s.resources" $name)) -}}
{{- $_ := set $out $name (dict "nodeSelector" ($p.nodeSelector | default dict) "resources" ($p.resources | default dict) "env" $env) -}}
{{- end -}}
{{- end -}}
{{- if not $out -}}
{{- fail "firecell-node-logs: enable at least one profile" -}}
{{- end -}}
{{- if not (hasKey $out (toString .Values.defaultProfile)) -}}
{{- fail (printf "firecell-node-logs: defaultProfile %q must name an enabled profile (enabled: %s)" (toString .Values.defaultProfile) (keys $out | sortAlpha | join ", ")) -}}
{{- end -}}
{{- toJson $out -}}
{{- end }}
