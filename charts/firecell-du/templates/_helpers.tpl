{{/*
Namespace for every object.
*/}}
{{- define "firecell-du.namespace" -}}
{{- .Values.global.namespace | default .Release.Namespace -}}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "firecell-du.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: firecell-ran
app.kubernetes.io/component: du
{{- end }}

{{/*
The DU: .Values with name defaulted to the release name. Returns JSON.
*/}}
{{- define "firecell-du.inst" -}}
{{- $i := omit .Values "global" "gnb" "preflight" "cuCpAddress" -}}
{{- $_ := set $i "name" (.Values.name | default .Release.Name | toString) -}}
{{- toJson $i -}}
{{- end }}

{{/*
Image. Pass (dict "root" $ "image" <override>).
*/}}
{{- define "firecell-du.image" -}}
{{- $img := .image | default .root.Values.global.image -}}
{{- if not $img }}
{{- fail "global.image (or image) is required" }}
{{- end }}
{{- $img -}}
{{- end }}

{{/*
F1-C target address.
*/}}
{{- define "firecell-du.cuCpAddress" -}}
{{- .Values.cuCpAddress | default (printf "cu-cp.%s.svc.cluster.local" (include "firecell-du.namespace" .)) -}}
{{- end }}

{{/*
Pod scheduling block. Pass (dict "root" $ "nodeSelector" <map> "tolerations" <list>).
*/}}
{{- define "firecell-du.scheduling" -}}
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
{{- define "firecell-du.merge" -}}
{{- $out := deepCopy (.dst | default dict) -}}
{{- range $k, $v := (.src | default dict) }}
{{- $cur := get $out $k }}
{{- if and (kindIs "map" $v) (kindIs "map" $cur) }}
{{- $_ := set $out $k (include "firecell-du.merge" (dict "dst" $cur "src" $v) | fromJson) }}
{{- else }}
{{- $_ := set $out $k $v }}
{{- end }}
{{- end }}
{{- toJson $out -}}
{{- end }}

{{/*
Expand a CPU list string ("3,4,19-22") to a JSON list of ints.
*/}}
{{- define "firecell-du.cpuList" -}}
{{- $out := list -}}
{{- range (splitList "," (toString .)) }}
{{- $item := trim . }}
{{- if contains "-" $item }}
{{- $r := splitList "-" $item }}
{{- range (untilStep (atoi (first $r)) (add1 (atoi (last $r)) | int) 1) }}
{{- $out = append $out . }}
{{- end }}
{{- else if $item }}
{{- $out = append $out (atoi $item) }}
{{- end }}
{{- end }}
{{- toJson $out -}}
{{- end }}

{{/*
All CPUs the DU uses (timing, txrx, pool) as a comma list, for taskset.
*/}}
{{- define "firecell-du.allCpus" -}}
{{- $c := .cpus -}}
{{- $all := list -}}
{{- range (list $c.timing $c.txrx $c.pool) }}
{{- $all = concat $all (include "firecell-du.cpuList" . | fromJsonArray) }}
{{- end }}
{{- $strs := list -}}
{{- range (uniq $all) }}
{{- $strs = append $strs (toString (int .)) }}
{{- end }}
{{- join "," $strs -}}
{{- end }}

{{/*
2 MiB pages in a quantity like "2Gi" or "512Mi".
*/}}
{{- define "firecell-du.hugepages2MiCount" -}}
{{- $q := toString . -}}
{{- if hasSuffix "Gi" $q -}}
{{- mul (atoi (trimSuffix "Gi" $q)) 512 -}}
{{- else if hasSuffix "Mi" $q -}}
{{- div (atoi (trimSuffix "Mi" $q)) 2 -}}
{{- else -}}
{{- fail (printf "hugepages2Mi must end in Gi or Mi, got %q" $q) -}}
{{- end -}}
{{- end }}

{{/*
IP part of an address/prefix.
*/}}
{{- define "firecell-du.ip" -}}
{{- first (splitList "/" (toString .)) -}}
{{- end }}

{{/*
O1 state directory on the host. Pass the DU.
*/}}
{{- define "firecell-du.o1StatePath" -}}
{{- .o1.statePath | default (printf "/var/lib/firecell/ocudu/%s" .name) -}}
{{- end }}

{{/*
Name of the Secret holding the M-plane SSH password. Pass the DU.
*/}}
{{- define "firecell-du.mplaneSecretName" -}}
{{- .mplane.existingSecret | default (printf "%s-mplane" .name) -}}
{{- end }}

{{/*
Node the DU is pinned to (kubernetes.io/hostname in its nodeSelector), or "".
Only two DUs pinned to the same hostname are known to share a node; any other
selector may match several nodes, so it gives no key.
*/}}
{{- define "firecell-du.nodeKey" -}}
{{- $sel := .Values.nodeSelector | default .Values.global.nodeSelector | default dict -}}
{{- get $sel "kubernetes.io/hostname" | default "" | toString -}}
{{- end }}

{{/*
True ("true") unless the value is null or empty. 0 counts as set.
*/}}
{{- define "firecell-du.isSet" -}}
{{- if not (or (kindIs "invalid" .) (eq (toString .) "")) }}true{{ end -}}
{{- end }}

{{/*
Annotations on the Deployment that let the next DU release check for clashes.
*/}}
{{- define "firecell-du.claims" -}}
{{- $i := include "firecell-du.inst" . | fromJson -}}
firecell.io/du-id: {{ toString $i.duId | quote }}
firecell.io/node: {{ include "firecell-du.nodeKey" . | quote }}
firecell.io/cpus: {{ include "firecell-du.allCpus" $i | quote }}
firecell.io/vf: {{ toString $i.ofh.vfPciAddr | quote }}
{{- if and $i.mplane.enabled $i.mplane.dhcp.enabled }}
firecell.io/mplane-dhcp: {{ toString $i.mplane.parentInterface | quote }}
{{- end }}
{{- end }}

{{/*
Template-time validation. Rendered from validate.yaml (emits nothing).
The clash checks read the other firecell-du Deployments in the namespace, so
they run on install/upgrade against a cluster and are skipped by helm template.
*/}}
{{- define "firecell-du.validate" -}}
{{- $i := include "firecell-du.inst" . | fromJson }}
{{- $n := $i.name }}
{{- if not (regexMatch "^[a-z]([-a-z0-9]*[a-z0-9])?$" $n) }}
{{- fail (printf "name %q is not a DNS-1123 label" $n) }}
{{- end }}
{{- if not (include "firecell-du.isSet" $i.duId) }}{{ fail (printf "%s: duId is required" $n) }}{{ end }}
{{- if not $i.ofh.vfPciAddr }}{{ fail (printf "%s: ofh.vfPciAddr is required" $n) }}{{ end }}
{{- range (list $i.cpus.timing $i.cpus.txrx $i.cpus.pool $i.cpus.ealLcores) }}
{{- if not (include "firecell-du.isSet" .) }}
{{- fail (printf "%s: cpus.timing, cpus.txrx, cpus.pool and cpus.ealLcores are required" $n) }}
{{- end }}
{{- end }}
{{- if $i.mplane.enabled }}
{{- if or (not $i.mplane.parentInterface) (not $i.mplane.duCidr) }}
{{- fail (printf "%s: mplane.parentInterface and mplane.duCidr are required" $n) }}
{{- end }}
{{- if not (contains "/" (toString $i.mplane.duCidr)) }}
{{- fail (printf "%s: mplane.duCidr needs a prefix (e.g. 10.10.0.24/24)" $n) }}
{{- end }}
{{- if and (not $i.mplane.existingSecret) (not $i.mplane.sshPassword) }}
{{- fail (printf "%s: mplane needs sshPassword or existingSecret" $n) }}
{{- end }}
{{- if and $i.mplane.dhcp.enabled (or (not $i.mplane.dhcp.ruIp) (not $i.ofh.ruMac)) }}
{{- fail (printf "%s: mplane.dhcp needs mplane.dhcp.ruIp and ofh.ruMac" $n) }}
{{- end }}
{{- end }}
{{- $f1uNet := dig "network" dict ($i.f1u | default dict) }}
{{- if dig "enabled" false $f1uNet }}
{{- if or (not $f1uNet.master) (not (contains "/" (toString $f1uNet.cidr))) }}
{{- fail (printf "%s: f1u.network needs master and cidr with a prefix (e.g. 10.6.0.1/24)" $n) }}
{{- end }}
{{- end }}
{{- $uePm := $i.o1.ueMetrics | default dict }}
{{- if and $i.o1.enabled (dig "enabled" false $uePm) }}
{{- $hw := dig "historyWindows" 40 $uePm | int }}
{{- if or (lt $hw 1) (gt $hw 60) }}
{{- fail (printf "%s: o1.ueMetrics.historyWindows must be 1-60 (got %v)" $n $hw) }}
{{- end }}
{{- $mu := dig "maxUes" 256 $uePm | int }}
{{- if or (lt $mu 1) (gt $mu 1024) }}
{{- fail (printf "%s: o1.ueMetrics.maxUes must be 1-1024 (got %v)" $n $mu) }}
{{- end }}
{{- end }}
{{- $mine := include "firecell-du.claims" . | fromYaml }}
{{- $myCpus := splitList "," (get $mine "firecell.io/cpus") }}
{{- $existing := lookup "apps/v1" "Deployment" (include "firecell-du.namespace" .) "" }}
{{- range ($existing.items | default list) }}
{{- $other := .metadata.name }}
{{- $a := .metadata.annotations | default dict }}
{{- if and (ne $other $n) (eq (index (.metadata.labels | default dict) "app.kubernetes.io/name" | default "") "firecell-du") }}
{{- if eq (get $a "firecell.io/du-id") (get $mine "firecell.io/du-id") }}
{{- fail (printf "%s: duId %s is already used by DU %s" $n (get $mine "firecell.io/du-id") $other) }}
{{- end }}
{{- $node := get $mine "firecell.io/node" }}
{{- if and $node (eq (get $a "firecell.io/node" | default "") $node) }}
{{- if eq (get $a "firecell.io/vf") (get $mine "firecell.io/vf") }}
{{- fail (printf "%s: VF %s is already used by DU %s" $n (get $mine "firecell.io/vf") $other) }}
{{- end }}
{{- $theirs := splitList "," (get $a "firecell.io/cpus" | default "") }}
{{- range $myCpus }}
{{- if has . $theirs }}{{ fail (printf "%s: CPU %s is already used by DU %s" $n . $other) }}{{ end }}
{{- end }}
{{- with (get $mine "firecell.io/mplane-dhcp") }}
{{- if eq (get $a "firecell.io/mplane-dhcp" | default "") . }}
{{- fail (printf "%s: M-plane parent %s already has a DHCP server (DU %s); one O-RU per M-plane segment" $n . $other) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
netopeer2 log level for NETCONF_VERBOSITY: error, warning, info, debug or 0-3. Pass the value.
*/}}
{{- define "firecell-du.netconfVerbosity" -}}
{{- $v := toString . | lower -}}
{{- if not (has $v (list "error" "warning" "info" "debug" "0" "1" "2" "3")) -}}
{{- fail (printf "netconfVerbosity %q: use error, warning, info, debug or 0-3" $v) -}}
{{- end -}}
{{- $v -}}
{{- end }}
