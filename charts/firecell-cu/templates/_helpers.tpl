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

{{/*
True ("true") unless the value is null or empty. 0 and false count as set.
*/}}
{{- define "firecell-cu.isSet" -}}
{{- if not (or (kindIs "invalid" .) (eq (toString .) "")) }}true{{ end -}}
{{- end }}

{{/*
O1 NETCONF credential Secret mounted at /etc/ocudu/o1-netconf, or "" for none:
o1.netconf.existingSecret, else <name>-o1-netconf when the chart makes it
(username, password or authorizedKeys set). Pass (dict "netconf" <o1.netconf> "name" <element name>).
*/}}
{{- define "firecell-cu.o1NetconfSecret" -}}
{{- $n := .netconf | default dict -}}
{{- $own := or $n.username $n.password $n.authorizedKeys -}}
{{- if $n.existingSecret -}}
{{- if $own -}}
{{- fail "o1.netconf: set existingSecret, or username/password/authorizedKeys for a chart-made Secret, not both" -}}
{{- end -}}
{{- $n.existingSecret -}}
{{- else if $own -}}
{{- if not (or $n.password $n.authorizedKeys) -}}
{{- fail "o1.netconf: a chart-made Secret needs password or authorizedKeys (the element refuses a Secret with neither)" -}}
{{- end -}}
{{- with $n.username -}}
{{- if or (not (regexMatch "^[A-Za-z0-9._-]{1,64}$" (toString .))) (eq (toString .) "root") -}}
{{- fail (printf "o1.netconf.username %q: letters, digits, . _ - only, at most 64 characters, not root" (toString .)) -}}
{{- end -}}
{{- end -}}
{{- with $n.password -}}
{{- if or (contains "\n" (toString .)) (gt (len (toString .)) 256) -}}
{{- fail "o1.netconf.password: one line of at most 256 characters (the element refuses every login with a longer one)" -}}
{{- end -}}
{{- end -}}
{{- printf "%s-o1-netconf" .name -}}
{{- end -}}
{{- end }}

{{/*
"true" when the chart makes the O1 NETCONF Secret. Same argument as firecell-cu.o1NetconfSecret.
*/}}
{{- define "firecell-cu.o1NetconfOwnSecret" -}}
{{- if and (include "firecell-cu.o1NetconfSecret" .) (not (dig "existingSecret" "" (.netconf | default dict))) }}true{{ end -}}
{{- end }}

{{/*
authorized_keys file content: a string, or a list of key lines.
*/}}
{{- define "firecell-cu.o1NetconfKeys" -}}
{{- if kindIs "slice" . }}{{ join "\n" . }}{{ else }}{{ toString . }}{{ end -}}
{{- end }}

{{/*
Pod annotation that rolls the pod when a chart-made O1 NETCONF Secret changes
(the element reads it at start only). Nothing for an existingSecret.
Same argument as firecell-cu.o1NetconfSecret.
*/}}
{{- define "firecell-cu.o1NetconfChecksum" -}}
{{- if include "firecell-cu.o1NetconfOwnSecret" . }}
{{- $n := .netconf }}
# The element reads the NETCONF credential once at start; roll the pod when it changes.
checksum/o1-netconf-secret: {{ toJson (dict "name" (include "firecell-cu.o1NetconfSecret" .) "username" $n.username "password" $n.password "keys" (include "firecell-cu.o1NetconfKeys" $n.authorizedKeys)) | sha256sum }}
{{- end }}
{{- end }}

{{/*
O1 NETCONF env for the O1 container. NETCONF_LISTEN_ADDRESS: o1.netconf.listenAddress, else the pod IP. O1_REQUIRE_SECRET: "true" when a Secret is
mounted (a lost Secret then keeps NETCONF off), else o1.netconf.requireSecret
when set (false: the deliberate way back to the lab login), else not set, so
the element's own mark (a Secret was used before) still keeps NETCONF off when
the Secret is dropped from the values. The others (group, nacm, keepRsaHostKey) only when set.
Same argument as firecell-cu.o1NetconfSecret.
*/}}
{{- define "firecell-cu.o1NetconfEnv" -}}
{{- $n := .netconf | default dict -}}
{{- $mounted := ne (include "firecell-cu.o1NetconfSecret" .) "" -}}
{{- $req := "" -}}
{{- if include "firecell-cu.isSet" $n.requireSecret -}}
{{- $req = toString $n.requireSecret | lower -}}
{{- if not (has $req (list "true" "false")) -}}
{{- fail (printf "o1.netconf.requireSecret %q: use true or false" $req) -}}
{{- end -}}
{{- if and $mounted (eq $req "false") -}}
{{- fail "o1.netconf.requireSecret cannot be false while a NETCONF Secret is mounted" -}}
{{- end -}}
{{- end -}}
{{- if $mounted -}}
{{- $req = "true" -}}
{{- end }}
{{- with $req }}
- name: O1_REQUIRE_SECRET
  value: {{ . | quote }}
{{- end }}
{{- with $n.group }}
{{- if not (has (toString .) (list "admin" "operator" "read-only")) }}
{{- fail (printf "o1.netconf.group %q: use admin, operator or read-only" (toString .)) }}
{{- end }}
- name: O1_NETCONF_GROUP
  value: {{ . | toString | quote }}
{{- end }}
{{- if include "firecell-cu.isSet" $n.nacm }}
{{- if not (kindIs "bool" $n.nacm) }}
{{- fail (printf "o1.netconf.nacm %q: use true or false" (toString $n.nacm)) }}
{{- end }}
- name: O1_NACM_ENABLED
  value: {{ $n.nacm | toString | quote }}
{{- end }}
{{- if include "firecell-cu.isSet" $n.keepRsaHostKey }}
{{- if not (kindIs "bool" $n.keepRsaHostKey) }}
{{- fail (printf "o1.netconf.keepRsaHostKey %q: use true or false" (toString $n.keepRsaHostKey)) }}
{{- end }}
- name: O1_HOSTKEY_KEEP_RSA
  value: {{ $n.keepRsaHostKey | toString | quote }}
{{- end }}
{{- /* The pod IP, not the image's 0.0.0.0: that would also open NETCONF on the
Multus interfaces (DU mplane0 and fronthaul, CU-UP N3), which a NetworkPolicy
does not filter. Needs POD_IP earlier in the same env list. */}}
- name: NETCONF_LISTEN_ADDRESS
  value: {{ $n.listenAddress | default "$(POD_IP)" | toString | quote }}
{{- end }}

{{/*
O1 NETCONF Secret volume mount, or nothing. Same argument as firecell-cu.o1NetconfSecret.
*/}}
{{- define "firecell-cu.o1NetconfMount" -}}
{{- if include "firecell-cu.o1NetconfSecret" . }}
- name: o1-netconf
  mountPath: /etc/ocudu/o1-netconf
  readOnly: true
{{- end }}
{{- end }}

{{/*
O1 NETCONF Secret volume, or nothing. optional: a deleted Secret leaves the
folder empty and only NETCONF off; the pod (and the radio) still starts.
Same argument as firecell-cu.o1NetconfSecret.
*/}}
{{- define "firecell-cu.o1NetconfVolume" -}}
{{- with include "firecell-cu.o1NetconfSecret" . }}
- name: o1-netconf
  secret:
    secretName: {{ . }}
    optional: true
    defaultMode: 0400
{{- end }}
{{- end }}

{{/*
Chart-made O1 NETCONF Secret, or nothing. Pass (dict "netconf" <o1.netconf> "name" <element name>
"namespace" <ns> "labels" <labels YAML>).
*/}}
{{- define "firecell-cu.o1NetconfSecretObject" -}}
{{- if include "firecell-cu.o1NetconfOwnSecret" . }}
{{- $n := .netconf }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "firecell-cu.o1NetconfSecret" . }}
  namespace: {{ .namespace }}
  labels:
    {{- .labels | nindent 4 }}
type: Opaque
stringData:
  {{- with $n.username }}
  username: {{ . | toString | quote }}
  {{- end }}
  {{- with $n.password }}
  password: {{ . | toString | quote }}
  {{- end }}
  {{- with $n.authorizedKeys }}
  authorized_keys: {{ include "firecell-cu.o1NetconfKeys" . | quote }}
  {{- end }}
{{- end }}
{{- end }}
