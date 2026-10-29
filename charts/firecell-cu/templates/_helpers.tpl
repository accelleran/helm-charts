{{/*
Namespace for every object.
*/}}
{{- define "firecell-cu.namespace" -}}
{{- .Values.global.namespace | default .Release.Namespace -}}
{{- end }}

{{/*
Common labels. Pass (dict "root" $ "component" "cu-cp").
*/}}
{{- define "firecell-cu.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .root.Chart.Name .root.Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ .root.Chart.Name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/part-of: firecell-ran
{{- with .component }}
app.kubernetes.io/component: {{ . }}
{{- end }}
{{- end }}

{{/*
Image for a component. Pass (dict "root" $ "image" <override>).
*/}}
{{- define "firecell-cu.image" -}}
{{- $img := .image | default .root.Values.global.image -}}
{{- if not $img }}
{{- fail "global.image (or a component image override) is required" }}
{{- end }}
{{- $img -}}
{{- end }}

{{/*
E1 target address for CU-UP.
*/}}
{{- define "firecell-cu.cuCpAddress" -}}
{{- .Values.cuUp.cuCpAddress | default (printf "%s.%s.svc.cluster.local" .Values.cuCpService.name (include "firecell-cu.namespace" .)) -}}
{{- end }}

{{/*
Pod scheduling block. Pass (dict "root" $ "nodeSelector" <map> "tolerations" <list>).
*/}}
{{- define "firecell-cu.scheduling" -}}
{{- $ns := .nodeSelector | default .root.Values.global.nodeSelector }}
{{- $tol := .tolerations | default .root.Values.global.tolerations }}
{{- with .root.Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $ns }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $tol }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Recursive map merge: src wins, nested maps merge, everything else (lists,
scalars, false, 0, "") replaces. Sprig mergeOverwrite skips zero values, so an
override could never turn a default true into false. Returns JSON.
Pass (dict "dst" <map> "src" <map>).
*/}}
{{- define "firecell-cu.merge" -}}
{{- $out := deepCopy (.dst | default dict) -}}
{{- range $k, $v := (.src | default dict) }}
{{- $cur := get $out $k }}
{{- if and (kindIs "map" $v) (kindIs "map" $cur) }}
{{- $_ := set $out $k (include "firecell-cu.merge" (dict "dst" $cur "src" $v) | fromJson) }}
{{- else }}
{{- $_ := set $out $k $v }}
{{- end }}
{{- end }}
{{- toJson $out -}}
{{- end }}

{{/*
IP part of an address/prefix.
*/}}
{{- define "firecell-cu.ip" -}}
{{- first (splitList "/" (toString .)) -}}
{{- end }}

{{/*
netopeer2 log level for NETCONF_VERBOSITY: error, warning, info, debug or 0-3. Pass the value.
*/}}
{{- define "firecell-cu.netconfVerbosity" -}}
{{- $v := toString . | lower -}}
{{- if not (has $v (list "error" "warning" "info" "debug" "0" "1" "2" "3")) -}}
{{- fail (printf "netconfVerbosity %q: use error, warning, info, debug or 0-3" $v) -}}
{{- end -}}
{{- $v -}}
{{- end }}
