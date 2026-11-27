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
O1 NETCONF settings. Every helper below takes (dict "netconf" <o1.netconf map>
"name" <element name> "path" <values path, e.g. o1.netconf> "image" <element image>).
*/}}

{{/*
Image tags known to predate accelleran/ocudu#724: they ignore the NETCONF Secret
and keep netconf/netconf with NACM off; any o1.netconf value set with
one of them is refused. Only these exact tags are judged; any
other tag (pr-*, edge, a digest, a later release) passes.
*/}}
{{- define "firecell-cu.o1NetconfPreSecretTags" -}}
{{- toJson (list "0.1.0" "v0.1.0" "0.2.0" "v0.2.0") -}}
{{- end }}

{{/*
"true", "false" or "" (unset) for an O1 NETCONF switch: a bool, or the string
true/false in any case. Pass (dict "v" <value> "key" <values path>).
*/}}
{{- define "firecell-cu.o1NetconfBool" -}}
{{- if include "firecell-cu.isSet" .v -}}
{{- $b := toString .v | lower -}}
{{- if not (and (or (kindIs "bool" .v) (kindIs "string" .v)) (has $b (list "true" "false"))) -}}
{{- fail (printf "%s %q: use true or false" .key (toString .v)) -}}
{{- end -}}
{{- $b -}}
{{- end -}}
{{- end }}

{{/*
Refuses O1 NETCONF values the element would not take, so the mistake shows at
render time and not as a silent "NETCONF off" (or a wrong credential) later.
The rules are those of the image's docker/o1/entrypoint.sh (accelleran/ocudu#724).
*/}}
{{- define "firecell-cu.o1NetconfCheck" -}}
{{- $n := .netconf | default dict -}}
{{- $p := .path -}}
{{- $known := list "existingSecret" "username" "password" "authorizedKeys" "requireSecret" "group" "nacm" "keepRsaHostKey" "listenAddress" -}}
{{- range $k := keys $n | sortAlpha }}
{{- if not (has $k $known) }}
{{- fail (printf "%s.%s: unknown key (known: %s)" $p $k (join ", " $known)) }}
{{- end }}
{{- end }}
{{- range $k := list "existingSecret" "username" "password" "group" "listenAddress" }}
{{- $v := get $n $k }}
{{- if and (include "firecell-cu.isSet" $v) (not (kindIs "string" $v)) }}
{{- fail (printf "%s.%s must be a string; quote it (got %v)" $p $k $v) }}
{{- end }}
{{- end }}
{{- with $n.authorizedKeys }}
{{- $lines := list }}
{{- if kindIs "string" . }}
{{- $lines = splitList "\n" . }}
{{- else if kindIs "slice" . }}
{{- range $l := . }}
{{- if not (kindIs "string" $l) }}
{{- fail (printf "%s.authorizedKeys: every list item must be a string (got %v)" $p $l) }}
{{- end }}
{{- $lines = concat $lines (splitList "\n" $l) }}
{{- end }}
{{- else }}
{{- fail (printf "%s.authorizedKeys: a string (one key per line) or a list of strings" $p) }}
{{- end }}
{{- range $l := $lines }}
{{- $t := trim $l }}
{{- if and $t (not (hasPrefix "#" $t)) (not (regexMatch "^(ssh-|ecdsa-|sk-)[^ \t]+[ \t]+[A-Za-z0-9+/]+=*([ \t].*)?$" $t)) }}
{{- fail (printf "%s.authorizedKeys: line %q is not \"<type> <base64 key> [comment]\"; options (from=, command=, restrict, ...) are refused by the element" $p (trunc 40 $t)) }}
{{- end }}
{{- end }}
{{- end }}
{{- with $n.username }}
{{- if or (not (regexMatch "^[A-Za-z0-9._-]{1,64}$" .)) (eq . "root") }}
{{- fail (printf "%s.username %q: letters, digits, . _ - only, at most 64 characters, not root" $p .) }}
{{- end }}
{{- end }}
{{- with $n.password }}
{{- if regexMatch "^[[:space:]]*$" . }}
{{- fail (printf "%s.password is blank (the element refuses it)" $p) }}
{{- end }}
{{- if or (contains "\n" .) (contains "\r" .) (gt (len .) 256) }}
{{- fail (printf "%s.password: one line of at most 256 characters (the element refuses a longer one)" $p) }}
{{- end }}
{{- if and (regexMatch "^\\$[0-9a-z]{1,4}\\$" .) (not (or (hasPrefix "$6$" .) (hasPrefix "$5$" .))) }}
{{- fail (printf "%s.password looks like a crypt hash of an unsupported type; give a $6$/$5$ hash or the clear password (the element would take the hash itself as the password)" $p) }}
{{- end }}
{{- if and (or (hasPrefix "$6$" .) (hasPrefix "$5$" .)) (not (regexMatch "^\\$[56]\\$(rounds=[0-9]+\\$)?[./A-Za-z0-9]{1,16}\\$[./A-Za-z0-9]{43,86}$" .)) }}
{{- fail (printf "%s.password starts like a $6$/$5$ crypt hash but is not a valid one (the element refuses it)" $p) }}
{{- end }}
{{- end }}
{{- with $n.group }}
{{- if not (has . (list "admin" "operator" "read-only")) }}
{{- fail (printf "%s.group %q: use admin, operator or read-only" $p .) }}
{{- end }}
{{- end }}
{{- with $n.listenAddress }}
{{- $ok := false }}
{{- if regexMatch "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$" . }}
{{- $ok = true }}
{{- range $o := splitList "." . }}
{{- if gt (atoi $o) 255 }}{{ $ok = false }}{{ end }}
{{- end }}
{{- else if and (contains ":" .) (regexMatch "^[0-9A-Fa-f:.]{2,45}$" .) }}
{{- $ok = true }}
{{- end }}
{{- if not $ok }}
{{- fail (printf "%s.listenAddress %q: an IPv4 or IPv6 address literal (the element keeps NETCONF off otherwise)" $p .) }}
{{- end }}
{{- end }}
{{- $_ := include "firecell-cu.o1NetconfBool" (dict "v" $n.requireSecret "key" (printf "%s.requireSecret" $p)) }}
{{- $_ := include "firecell-cu.o1NetconfBool" (dict "v" $n.nacm "key" (printf "%s.nacm" $p)) }}
{{- $_ := include "firecell-cu.o1NetconfBool" (dict "v" $n.keepRsaHostKey "key" (printf "%s.keepRsaHostKey" $p)) }}
{{- $set := false }}
{{- range $k, $v := $n }}{{ if include "firecell-cu.isSet" $v }}{{ $set = true }}{{ end }}{{ end }}
{{- if $set }}
{{- $img := toString .image }}
{{- $tag := "" }}
{{- if not (contains "@" $img) }}
{{- $last := last (splitList "/" $img) }}
{{- if contains ":" $last }}{{ $tag = last (splitList ":" $last) }}{{ end }}
{{- end }}
{{- if has $tag (include "firecell-cu.o1NetconfPreSecretTags" . | fromJsonArray) }}
{{- fail (printf "%s needs an image with accelleran/ocudu#724 (RC3 or later); image %s ignores it and keeps netconf/netconf with NACM off" $p $img) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
O1 NETCONF credential Secret mounted at /etc/ocudu/o1-netconf, or "" for none:
existingSecret, else <name>-o1-netconf when the chart makes it (username,
password or authorizedKeys set). Also runs firecell-cu.o1NetconfCheck.
*/}}
{{- define "firecell-cu.o1NetconfSecret" -}}
{{- include "firecell-cu.o1NetconfCheck" . -}}
{{- $n := .netconf | default dict -}}
{{- $p := .path -}}
{{- $own := or $n.username $n.password $n.authorizedKeys -}}
{{- $name := "" -}}
{{- if $n.existingSecret -}}
{{- if $own -}}
{{- fail (printf "%s: set existingSecret, or username/password/authorizedKeys for a chart-made Secret, not both" $p) -}}
{{- end -}}
{{- $name = $n.existingSecret -}}
{{- else if $own -}}
{{- if not (or $n.password $n.authorizedKeys) -}}
{{- fail (printf "%s: a chart-made Secret needs password or authorizedKeys (the element refuses a Secret with neither)" $p) -}}
{{- end -}}
{{- $name = printf "%s-o1-netconf" .name -}}
{{- end -}}
{{- $name -}}
{{- end }}

{{/*
"true" when the chart makes the O1 NETCONF Secret.
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
*/}}
{{- define "firecell-cu.o1NetconfChecksum" -}}
{{- if include "firecell-cu.o1NetconfOwnSecret" . }}
{{- $n := .netconf }}
# The element reads the NETCONF credential once at start; roll the pod when it changes.
checksum/o1-netconf-secret: {{ toJson (dict "name" (include "firecell-cu.o1NetconfSecret" .) "username" $n.username "password" $n.password "keys" (include "firecell-cu.o1NetconfKeys" $n.authorizedKeys)) | sha256sum }}
{{- end }}
{{- end }}

{{/*
O1 NETCONF env for the O1 container.
- O1_REQUIRE_SECRET: "true" when a Secret is mounted (a lost Secret then keeps
  NETCONF off), else requireSecret when set (true keeps NETCONF off without a
  Secret; false is the deliberate way back to the lab login), else not set, so
  the element's own mark (a Secret was used before) still keeps NETCONF off
  when the Secret is dropped from the values.
- NETCONF_LISTEN_ADDRESS: listenAddress, else the pod IP. Not the image's
  0.0.0.0: that would also open NETCONF on the Multus interfaces (DU mplane0
  and fronthaul, CU-UP N3), which a NetworkPolicy does not filter. Needs POD_IP
  earlier in the same env list.
- group, nacm, keepRsaHostKey: only when set.
*/}}
{{- define "firecell-cu.o1NetconfEnv" -}}
{{- $n := .netconf | default dict -}}
{{- $p := .path -}}
{{- $mounted := ne (include "firecell-cu.o1NetconfSecret" .) "" -}}
{{- $req := include "firecell-cu.o1NetconfBool" (dict "v" $n.requireSecret "key" (printf "%s.requireSecret" $p)) -}}
{{- if and $mounted (eq $req "false") -}}
{{- fail (printf "%s.requireSecret cannot be false while a NETCONF Secret is mounted" $p) -}}
{{- end -}}
{{- if $mounted -}}
{{- $req = "true" -}}
{{- end }}
{{- with $req }}
- name: O1_REQUIRE_SECRET
  value: {{ . | quote }}
{{- end }}
{{- with $n.group }}
- name: O1_NETCONF_GROUP
  value: {{ . | quote }}
{{- end }}
{{- with include "firecell-cu.o1NetconfBool" (dict "v" $n.nacm "key" (printf "%s.nacm" $p)) }}
- name: O1_NACM_ENABLED
  value: {{ . | quote }}
{{- end }}
{{- with include "firecell-cu.o1NetconfBool" (dict "v" $n.keepRsaHostKey "key" (printf "%s.keepRsaHostKey" $p)) }}
- name: O1_HOSTKEY_KEEP_RSA
  value: {{ . | quote }}
{{- end }}
- name: NETCONF_LISTEN_ADDRESS
  value: {{ $n.listenAddress | default "$(POD_IP)" | quote }}
{{- end }}

{{/*
O1 NETCONF Secret volume mount, or nothing.
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
*/}}
{{- define "firecell-cu.o1NetconfVolume" -}}
{{- with include "firecell-cu.o1NetconfSecret" . }}
- name: o1-netconf
  secret:
    secretName: {{ . | quote }}
    optional: true
    defaultMode: 0400
{{- end }}
{{- end }}

{{/*
Chart-made O1 NETCONF Secret, or nothing. The argument also carries
"namespace" <ns> and "labels" <labels YAML>.
*/}}
{{- define "firecell-cu.o1NetconfSecretObject" -}}
{{- if include "firecell-cu.o1NetconfOwnSecret" . }}
{{- $n := .netconf }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "firecell-cu.o1NetconfSecret" . | quote }}
  namespace: {{ .namespace }}
  labels:
    {{- .labels | nindent 4 }}
type: Opaque
stringData:
  {{- with $n.username }}
  username: {{ . | quote }}
  {{- end }}
  {{- with $n.password }}
  password: {{ . | quote }}
  {{- end }}
  {{- with $n.authorizedKeys }}
  authorized_keys: {{ include "firecell-cu.o1NetconfKeys" . | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
O1 state PersistentVolumeClaim name (a string), checked. Pass (dict "v" <stateClaim> "key" <values path>).
*/}}
{{- define "firecell-cu.o1StateClaim" -}}
{{- if not (kindIs "string" .v) -}}
{{- fail (printf "%s must be a string; quote it (got %v)" .key .v) -}}
{{- end -}}
{{- .v -}}
{{- end }}
