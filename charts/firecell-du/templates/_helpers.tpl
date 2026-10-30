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
Radio family from ru.split and ru.vendor: "ofh" (split 7.2), "aw2s" (Swallow RRH over CPRI), "uhd" (USB B210) or
"zmq" (split 8 without hardware). Pass the DU.
*/}}
{{- define "firecell-du.ruType" -}}
{{- $ru := .ru | default dict -}}
{{- $vendor := toString (dig "vendor" "benetel" $ru) -}}
{{- if eq (toString (dig "split" "7.2" $ru)) "8" -}}
{{- ternary "uhd" $vendor (eq $vendor "b210") -}}
{{- else -}}
ofh
{{- end -}}
{{- end }}

{{/*
Vendor of the radio: the ru.vendor of the DU, or the deprecated ofh.ruType on a 7.2 DU. Pass the DU.
*/}}
{{- define "firecell-du.ruVendor" -}}
{{- $vendor := toString (dig "vendor" "benetel" (.ru | default dict)) -}}
{{- if and (eq (include "firecell-du.ruType" .) "ofh") (dig "ruType" "" (.ofh | default dict)) -}}
{{- toString .ofh.ruType -}}
{{- else -}}
{{- $vendor -}}
{{- end -}}
{{- end }}

{{/*
"true" for a split 8 radio (ru_sdr). Pass the DU.
*/}}
{{- define "firecell-du.sdr" -}}
{{- if ne (include "firecell-du.ruType" .) "ofh" }}true{{ end -}}
{{- end }}

{{/*
"true" when the DU writes the Swallow file itself (ru.sdr.aw2s.generate). Pass the DU.
*/}}
{{- define "firecell-du.aw2sGenerate" -}}
{{- if and (eq (include "firecell-du.ruType" .) "aw2s") (dig "sdr" "aw2s" "generate" false (.ru | default dict)) }}true{{ end -}}
{{- end }}

{{/*
"true" when the DU sends fronthaul over DPDK (ru.split "7.2", ofh.mode dpdk: the default). Pass the DU.
*/}}
{{- define "firecell-du.dpdk" -}}
{{- if and (eq (include "firecell-du.ruType" .) "ofh") (ne (toString (.ofh.mode | default "dpdk")) "socket") }}true{{ end -}}
{{- end }}

{{/*
"true" for OFH over a kernel socket on a host netdev moved into the pod (ofh.mode socket). Pass the DU.
*/}}
{{- define "firecell-du.ofhSocket" -}}
{{- if and (eq (include "firecell-du.ruType" .) "ofh") (eq (toString (.ofh.mode | default "dpdk")) "socket") }}true{{ end -}}
{{- end }}

{{/*
"true" when the DU runs in the host network namespace (ru.vendor aw2s: the host Radio
Management Unit and the Swallow card netdevs stay on the host). Pass the DU.
*/}}
{{- define "firecell-du.hostNetwork" -}}
{{- if eq (include "firecell-du.ruType" .) "aw2s" }}true{{ end -}}
{{- end }}

{{/*
DU binary: `binary` when set, else odu_split_7_2 (split 7.2) or the dynamic odu (split 8). Pass the DU.
*/}}
{{- define "firecell-du.binary" -}}
{{- .binary | default (ternary "odu" "odu_split_7_2" (eq (include "firecell-du.sdr" .) "true")) -}}
{{- end }}

{{/*
All CPUs the DU uses (timing, txrx or ru, pool) as a comma list, for taskset and the clash check.
*/}}
{{- define "firecell-du.allCpus" -}}
{{- $c := .cpus -}}
{{- $all := list -}}
{{- range (list $c.timing $c.txrx $c.ru $c.pool) }}
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
"true" when two device claims name the same device. A B210 DU without a serial takes the first UHD device
(usb:any), so it clashes with every other B210 DU on the node. Pass (list claimA claimB).
*/}}
{{- define "firecell-du.deviceClash" -}}
{{- $a := toString (index . 0) -}}
{{- $b := toString (index . 1) -}}
{{- if or (eq $a $b) (and (hasPrefix "usb:" $a) (hasPrefix "usb:" $b) (or (eq $a "usb:any") (eq $b "usb:any"))) }}true{{ end -}}
{{- end }}

{{/*
Annotations on the Deployment that let the next DU release check for clashes.
*/}}
{{- define "firecell-du.claims" -}}
{{- $i := include "firecell-du.inst" . | fromJson -}}
firecell.io/du-id: {{ toString $i.duId | quote }}
firecell.io/node: {{ include "firecell-du.nodeKey" . | quote }}
firecell.io/cpus: {{ include "firecell-du.allCpus" $i | quote }}
{{- $dev := printf "netdev:%s" $i.ofh.interface }}
{{- if eq (include "firecell-du.ruType" $i) "aw2s" }}
{{- $dev = printf "aw2s:%s/%s" $i.ru.sdr.aw2s.configDir $i.ru.sdr.aw2s.rfConfigFile }}
{{- else if eq (include "firecell-du.ruType" $i) "uhd" }}
{{- $dev = printf "usb:%s" (default "any" $i.ru.sdr.b210.serial) }}
{{- else if eq (include "firecell-du.ruType" $i) "zmq" }}
{{- /* No shared hardware: each DU has its own pod network and ports. Claim a name only this DU has, so that two
       ZMQ DUs on one node do not clash on the device; the CPU check still applies. */ -}}
{{- $dev = printf "zmq:%s" $i.name }}
{{- else if eq (include "firecell-du.dpdk" $i) "true" }}
{{- $dev = toString $i.ofh.vfPciAddr }}
{{- end }}
firecell.io/vf: {{ $dev | quote }}
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
{{- $ru := $i.ru | default dict }}
{{- $split := toString (dig "split" "7.2" $ru) }}
{{- $vendor := toString (dig "vendor" "benetel" $ru) }}
{{- if not (has $split (list "7.2" "8")) }}
{{- fail (printf "%s: ru.split must be \"7.2\" or \"8\" (got %q)" $n $split) }}
{{- end }}
{{- if and (eq $split "7.2") (not (has $vendor (list "benetel" "comba" "eridan"))) }}
{{- fail (printf "%s: ru.vendor %q needs ru.split \"8\"; with ru.split \"7.2\" use benetel, comba or eridan" $n $vendor) }}
{{- end }}
{{- if and (eq $split "8") (not (has $vendor (list "aw2s" "b210" "zmq"))) }}
{{- fail (printf "%s: ru.vendor %q needs ru.split \"7.2\"; with ru.split \"8\" use aw2s, b210 or zmq" $n $vendor) }}
{{- end }}
{{- $ruType := include "firecell-du.ruType" $i }}
{{- if and (eq $ruType "ofh") (dig "ruType" "" ($i.ofh | default dict)) (not (has (toString $i.ofh.ruType) (list "benetel" "comba" "eridan"))) }}
{{- fail (printf "%s: ofh.ruType must be benetel, comba or eridan (got %q)" $n (toString $i.ofh.ruType)) }}
{{- end }}
{{- $tx := $i.txPower | default dict }}
{{- if and (kindIs "invalid" (dig "dbm" nil $tx) | not) (ne (include "firecell-du.aw2sGenerate" $i) "true") }}
{{- fail (printf "%s: txPower.dbm needs ru.vendor aw2s with ru.sdr.aw2s.generate true (the DU writes it into the Swallow file)" $n) }}
{{- end }}
{{- $mode := toString ($i.ofh.mode | default "dpdk") }}
{{- if ne $ruType "ofh" }}
{{- if eq $ruType "aw2s" }}
{{- $a := dig "sdr" "aw2s" dict $ru }}
{{- range (list "configDir" "rfConfigFile" "hostLibDir" "lib") }}
{{- if not (get $a .) }}{{ fail (printf "%s: ru.sdr.aw2s.%s is required with ru.vendor aw2s" $n .) }}{{ end }}
{{- end }}
{{- if eq (include "firecell-du.aw2sGenerate" $i) "true" }}
{{- if not (get $a "antennas") }}{{ fail (printf "%s: ru.sdr.aw2s.antennas is required with ru.sdr.aw2s.generate (one entry per antenna of the cell)" $n) }}{{ end }}
{{- if not (has (toString $a.sku) (list "panther" "jaguar" "neo")) }}{{ fail (printf "%s: ru.sdr.aw2s.sku must be panther, jaguar or neo (got %q)" $n (toString $a.sku)) }}{{ end }}
{{- end }}
{{- end }}
{{- range (list $i.cpus.ru $i.cpus.pool) }}
{{- if not (include "firecell-du.isSet" .) }}
{{- fail (printf "%s: cpus.ru and cpus.pool are required with ru.split \"8\"" $n) }}
{{- end }}
{{- end }}
{{- if or (include "firecell-du.isSet" $i.cpus.timing) (include "firecell-du.isSet" $i.cpus.txrx) }}
{{- fail (printf "%s: cpus.timing/cpus.txrx are OFH threads; ru.split \"8\" uses cpus.ru for the radio threads" $n) }}
{{- end }}
{{- if $i.mplane.enabled }}{{ fail (printf "%s: mplane is for O-RAN 7.2 O-RUs (ru.split \"7.2\"), not %s" $n $vendor) }}{{ end }}
{{- if and (eq $ruType "aw2s") (dig "network" "enabled" false ($i.f1u | default dict)) }}
{{- fail (printf "%s: f1u.network needs a pod network namespace; ru.vendor aw2s runs in the host network. Use f1u.bindAddress (a host address, e.g. on br-f1u) instead" $n) }}
{{- end }}
{{- else if not (has $mode (list "dpdk" "socket")) }}
{{- fail (printf "%s: ofh.mode must be dpdk or socket (got %q)" $n $mode) }}
{{- else if eq $mode "dpdk" }}
{{- if not $i.ofh.vfPciAddr }}{{ fail (printf "%s: ofh.vfPciAddr is required with ofh.mode dpdk" $n) }}{{ end }}
{{- range (list $i.cpus.timing $i.cpus.txrx $i.cpus.pool $i.cpus.ealLcores) }}
{{- if not (include "firecell-du.isSet" .) }}
{{- fail (printf "%s: cpus.timing, cpus.txrx, cpus.pool and cpus.ealLcores are required" $n) }}
{{- end }}
{{- end }}
{{- else }}
{{- if not $i.ofh.interface }}{{ fail (printf "%s: ofh.interface (host netdev, e.g. veth-du1) is required with ofh.mode socket" $n) }}{{ end }}
{{- if not (regexMatch "^[A-Za-z0-9_.-]{1,15}$" (toString $i.ofh.interface)) }}
{{- fail (printf "%s: ofh.interface %q is not a valid netdev name" $n (toString $i.ofh.interface)) }}
{{- end }}
{{- if has (toString $i.ofh.interface) (list "eth0" "f1u0" "mplane0") }}
{{- fail (printf "%s: ofh.interface %q clashes with an interface the chart creates in the pod" $n (toString $i.ofh.interface)) }}
{{- end }}
{{- range (list $i.cpus.timing $i.cpus.txrx $i.cpus.pool) }}
{{- if not (include "firecell-du.isSet" .) }}
{{- fail (printf "%s: cpus.timing, cpus.txrx and cpus.pool are required" $n) }}
{{- end }}
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
{{- $grace := $i.terminationGracePeriodSeconds }}
{{- if or (not (kindIs "float64" $grace)) (lt $grace 0.0) (ne (floor $grace) $grace) }}
{{- fail (printf "%s: terminationGracePeriodSeconds must be a whole number of seconds >= 0 (got %v)" $n $grace) }}
{{- end }}
{{- /* The carrier ready timeout is only known to the chart when it is set; extraConfig.mplane wins over mplane.extra. */}}
{{- $crt := dig "mplane" "carrier_ready_timeout_ms" (dig "carrier_ready_timeout_ms" nil ($i.mplane.extra | default dict)) ($i.extraConfig | default dict) }}
{{- if and $i.mplane.enabled $crt }}
{{- $stopS := add (divf ($crt | float64) 1000 | ceil | int) 10 }}
{{- if le ($grace | int) $stopS }}
{{- fail (printf "%s: terminationGracePeriodSeconds %v must exceed %v s (carrier_ready_timeout_ms + 10 s to switch the carriers off at stop, without CBRS; with CBRS the stop takes longer)" $n $grace $stopS) }}
{{- end }}
{{- end }}
{{- $f1uNet := dig "network" dict ($i.f1u | default dict) }}
{{- if dig "enabled" false $f1uNet }}
{{- if or (not $f1uNet.master) (not (contains "/" (toString $f1uNet.cidr))) }}
{{- fail (printf "%s: f1u.network needs master and cidr with a prefix (e.g. 10.6.0.1/24)" $n) }}
{{- end }}
{{- $f1uType := toString ($f1uNet.cniType | default "macvlan") }}
{{- if not (has $f1uType (list "macvlan" "bridge")) }}
{{- fail (printf "%s: f1u.network.cniType must be macvlan or bridge (got %q)" $n $f1uType) }}
{{- end }}
{{- with $f1uNet.rpsCpus }}
{{- if not (kindIs "string" .) }}
{{- fail (printf "%s: f1u.network.rpsCpus must be a quoted hex CPU mask such as \"c00000\" (got %v, a %s: YAML reads unquoted digits and 0x values as numbers)" $n . (kindOf .)) }}
{{- end }}
{{- if not (regexMatch "^[0-9a-fA-F,]+$" .) }}
{{- fail (printf "%s: f1u.network.rpsCpus must be a hex CPU mask like c00000 (got %q)" $n .) }}
{{- end }}
{{- if ne $f1uType "bridge" }}
{{- fail (printf "%s: f1u.network.rpsCpus needs f1u.network.cniType bridge: RPS has no effect on a macvlan, whose receive runs in the parent NIC's softirq (pin that NIC's IRQs on the host)" $n) }}
{{- end }}
{{- end }}
{{- else if dig "rpsCpus" "" $f1uNet }}
{{- fail (printf "%s: f1u.network.rpsCpus needs f1u.network.enabled" $n) }}
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
{{- if eq (include "firecell-du.deviceClash" (list (get $a "firecell.io/vf") (get $mine "firecell.io/vf"))) "true" }}
{{- fail (printf "%s: device %s is already used by DU %s (%s)" $n (get $mine "firecell.io/vf") $other (get $a "firecell.io/vf")) }}
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
