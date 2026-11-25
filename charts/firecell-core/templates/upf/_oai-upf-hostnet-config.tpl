{{- /*
  Per-instance OAI UPF hostNetwork config fragment (embedded in ConfigMap data).
  Params: root context $, instance dict $inst.
*/}}
{{- define "firecell-5gc.oaiUpfHostnetConfig" -}}
{{- $root := index . 0 -}}
{{- $inst := index . 1 -}}
{{- $v := $root.Values -}}
{{- $suffix := ($inst.suffix | default "" | toString) -}}
{{- $appName := printf "oai-upf%s" $suffix -}}
{{- $sbi := coalesce $inst.sbiInterface $v.upf.sbiInterface "cni0" -}}
{{- /* MnS/FCAPS bind interface — decoupled from SBI so multiple hostNetwork UPFs on one
       host don't collide on <sbi-ip>:9091. Falls back to SBI for back-compat with images
       that don't yet read nfs.upf.mns.interface_name. */ -}}
{{- $mns := coalesce $inst.mnsInterface $v.upf.mnsInterface $sbi -}}
{{- $n3 := coalesce $inst.n3Interface $v.upf.n3Interface "eth0" -}}
{{- $n6 := coalesce $inst.n6Interface $v.upf.n6Interface $n3 -}}
{{- $n4 := coalesce $inst.hostPfcpMacvlan $inst.n4Interface $v.upf.hostPfcpMacvlan $v.upf.n4Interface "eno1" -}}
{{- $n9 := coalesce $inst.n9Interface $v.upf.n9Interface $n3 -}}
{{- $n6gw := coalesce $inst.remoteN6Gw $v.upf.remoteN6Gw "" -}}
{{- /* Per-instance N9 (UL CL): instance key n9 {enabled, peers, failover}. Unset: the
       n9 block keeps only interface_name and port, so the UPF defaults apply
       (enabled false). */ -}}
{{- $n9cfg := $inst.n9 | default dict -}}
{{- if not (kindIs "map" $n9cfg) -}}
{{- fail (printf "%s: n9 must be a map {enabled, peers, failover} (got %v)" $appName $n9cfg) -}}
{{- end -}}
{{- range $k, $_ := $n9cfg -}}
{{- if not (has $k (list "enabled" "peers" "failover")) -}}
{{- fail (printf "%s: unknown key n9.%s (allowed: enabled, peers, failover)" $appName $k) -}}
{{- end -}}
{{- end -}}
{{- range $k, $_ := ($n9cfg.failover | default dict) -}}
{{- if not (has $k (list "enableFastPath" "requireFallbackFar" "ulclForceLocalOnGap")) -}}
{{- fail (printf "%s: unknown key n9.failover.%s (allowed: enableFastPath, requireFallbackFar, ulclForceLocalOnGap)" $appName $k) -}}
{{- end -}}
{{- end -}}
{{- $n9On := eq (include "firecell-5gc.flag" (list (get $n9cfg "enabled") false)) "true" -}}
{{- $n9Peers := list -}}
{{- range ($n9cfg.peers | default list) -}}
{{- $peer := . -}}
{{- if kindIs "map" . }}{{ $peer = .addr4 }}{{ end -}}
{{- $peer = $peer | default "" | toString | trim -}}
{{- if not (regexMatch "^[0-9]{1,3}([.][0-9]{1,3}){3}$" $peer) -}}
{{- fail (printf "%s: n9.peers entries must be IPv4 addresses (the peer UPFs' N3/N9 GTP-U addresses), got %q" $appName $peer) -}}
{{- end -}}
{{- $n9Peers = append $n9Peers $peer -}}
{{- end -}}
{{- if $n9On -}}
{{- /* Mirrors cn5g-upf validate_n9: N9 needs its own netdev (XDP attaches one program
       per netdev) with its own IPv4 address; the address is not visible here. */ -}}
{{- range $other := list (list "n3" $n3) (list "n6" $n6) (list "n4" $n4) (list "sbi" $sbi) -}}
{{- if eq $n9 (index $other 1) -}}
{{- fail (printf "%s: n9.enabled needs N9 on its own netdev, but the N9 interface %q is the %s interface; set n9Interface (or upf.n9Interface) to a dedicated netdev with its own IPv4 address" $appName $n9 (index $other 0)) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $instSliceSd := "" -}}
{{- if $inst.nssai }}
{{- $instSliceSd = $inst.nssai.sd | default "" | toString -}}
{{- end }}
{{- $nwi := (index $v.coreConfig.dnns 0).dnn -}}
{{- if $inst.dnns }}
{{- $nwi = $inst.dnns | first -}}
{{- end }}
{{- $bpfRaw := dig "enableBpfDatapath" true $v.upf -}}
{{- $schema := $v.upf.configSchema | default "mr97" | toString | lower -}}
log_level:
  general: {{ $v.coreConfig.logLevel }}
register_nf:
  general: {{ $v.coreConfig.registerNf }}
http_version: {{ if $v.global.sbi.tls.enabled }}2{{ else }}{{ $v.coreConfig.httpVersion }}{{ end }}
{{- if $v.global.sbi.tls.enabled }}
# SBI TLS (global.sbi.tls): the UPF is a client of the NRF only
tls:
  enable_tls: true
  cert_certificate_path: /etc/firecell/sbi-tls/tls.crt
  cert_key_path: /etc/firecell/sbi-tls/tls.key
  ca_path: /etc/firecell/sbi-tls/ca.crt
  require_client_cert: {{ $v.global.sbi.tls.requireClientCert }}
  verify_peer: {{ $v.global.sbi.tls.verifyPeer }}
{{- end }}
{{- if $v.global.sbi.oauth2.enabled }}
oauth2:
  enable: true
  nrf_public_key_path: /etc/firecell/sbi-oauth2/public-key.pem
  token_refresh_margin_s: {{ $v.global.sbi.oauth2.tokenRefreshMarginS }}
{{- end }}

nfs:
  nrf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $root "name" "oai-nrf" "clusterDNS" true) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ $sbi | quote }}
  smf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $root "name" "oai-smf" "clusterDNS" true) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ $sbi | quote }}
    n4:
      interface_name: {{ $n4 | quote }}
      port: 8805
  upf:
    host: {{ $appName | quote }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ $sbi | quote }}
    # MnS/FCAPS management server bind (Firecell). Decoupled from SBI so N hostNetwork UPFs
    # on one host bind unique <mns-ip>:9091 instead of colliding on the shared SBI IP.
    # FCAPS code should read nfs.upf.mns.interface_name (fallback: sbi.interface_name).
    mns:
      port: 9091
      interface_name: {{ $mns | quote }}
    n3:
      interface_name: {{ $n3 | quote }}
      port: 2152
      nwi: {{ $nwi | quote }}
    n4:
      interface_name: {{ $n4 | quote }}
      port: 8805
    n6:
      interface_name: {{ $n6 | quote }}
      nwi: {{ $nwi | quote }}
    n9:
      {{- if $inst.n9 }}
      enabled: {{ $n9On }}
      {{- end }}
      interface_name: {{ $n9 | quote }}
      port: 2152
      {{- if $n9Peers }}
      # GTP-U addresses of the peer UPFs: a FAR whose outer header creation
      # address is one of them leaves on N9, any other on local N6.
      peers:
      {{- range $n9Peers }}
        - addr4: {{ . | quote }}
      {{- end }}
      {{- end }}
      {{- with ($n9cfg.failover | default dict) }}
      {{- $fo := . }}
      {{- $foKeys := list (list "enableFastPath" "enable_fast_path") (list "requireFallbackFar" "require_fallback_far") (list "ulclForceLocalOnGap" "ulcl_force_local_on_gap") }}
      failover:
      {{- range $foKeys }}
      {{- if hasKey $fo (index . 0) }}
        {{ index . 1 }}: {{ include "firecell-5gc.flag" (list (get $fo (index . 0)) false) }}
      {{- end }}
      {{- end }}
      {{- end }}

snssais:
{{- range $v.coreConfig.nssai }}
  - &embb_slice_sst{{ .sst }}_sd{{ .sd | default "none" }}
    sst: {{ .sst }}
    {{- if .sd }}
    sd: {{ .sd }}
    {{- end }}
{{- end }}

ue_dns:
  primary_ipv4: {{ $v.coreConfig.dns.primaryIpv4 | quote }}
  secondary_ipv4: {{ $v.coreConfig.dns.secondaryIpv4 | quote }}
  {{- include "firecell-5gc.optionalKeys" (dict "indent" 2 "pairs" (list (list "primary_ipv6" $v.coreConfig.dns.primaryIpv6) (list "secondary_ipv6" $v.coreConfig.dns.secondaryIpv6))) }}

ims:
  pcscf_ipv4: {{ include "firecell-5gc.pcscfIpv4" $root | quote }}
  pcscf_ipv6: {{ $v.coreConfig.ims.pcscfIpv6 | quote }}

dnns:
{{- range $v.coreConfig.dnns }}
  - dnn: {{ .dnn | quote }}
    pdu_session_type: {{ .pduSessionType | quote }}
    {{- with .ipv4Subnet }}
    ipv4_subnet: {{ . | quote }}
    {{- end }}
    {{- include "firecell-5gc.dnnIpv6Keys" . }}
{{- end }}

upf:
  support_features:
    enable_bpf_datapath: {{ if kindIs "bool" $bpfRaw }}{{ if $bpfRaw }}yes{{ else }}no{{ end }}{{ else if or (eq ($bpfRaw | toString | lower) "false") (eq ($bpfRaw | toString | lower) "no") (eq ($bpfRaw | toString) "0") }}no{{ else }}yes{{ end }}
    enable_qos: yes
    enable_urr: {{ $v.coreConfig.smf.enableQer }}
    enable_bar: no
    enable_mar: no
    enable_snat: {{ if eq (include "firecell-5gc.flag" (list (ternary $inst.enableSnat $v.upf.enableSnat (hasKey ($inst | default dict) "enableSnat")) true)) "true" }}yes{{ else }}no{{ end }}
    enable_fr: {{ if hasKey ($inst | default dict) "enableFramedRouting" }}{{ if eq (include "firecell-5gc.flag" (list $inst.enableFramedRouting false)) "true" }}yes{{ else }}no{{ end }}{{ else if $v.upf.enableFramedRouting }}yes{{ else }}no{{ end }}
    enable_eth_pdu: {{ if $v.upf.oaiEnableEthPdu }}yes{{ else }}no{{ end }}
    {{- if $v.upf.oaiEnableEthPdu }}
    eth_dl_broadcast_enabled: {{ if $v.upf.ethDlBroadcastEnabled }}yes{{ else }}no{{ end }}
    eth_dl_flood_max_copies: {{ $v.upf.ethDlFloodMaxCopies | default 50 }}
    {{- end }}
{{- if include "firecell-5gc.ipv6UserPlane" $root }}
    # IPv6 RS/NS and RA/NA relayed between the UE and the SMF over N4-u (UDP 2152 on
    # the N4 address, which must differ from N3 and N9).
    enable_cp_relay: {{ if include "firecell-5gc.upfCpRelay" (dict "ctx" $root "inst" $inst) }}yes{{ else }}no{{ end }}
{{- end }}
    {{- include "firecell-5gc.upfDeleteSessionsOnSmfRestart" $v.upf }}
    # cn5g-upf v5.1.0.x sizes m_arp_table from support_features (not datapath_configuration).
    max_arp_entries: 256
{{- if eq $schema "legacy" }}
    # Legacy cn5g-upf v5.1.0.x reads BPF map sizes from support_features.
    max_upf_interfaces: 4
    max_upf_redirect_interfaces: 2
    max_pdu_session: 100
    max_pdrs_per_pdu_session: 8
    max_qos_flows_per_pdu_session: 8
    max_sdf_filters_per_pdu_session: 8
{{- end }}
  remote_n6_gw: {{ $n6gw | quote }}
  {{- include "firecell-5gc.upfGtpuEiRestartHoldoff" $v.upf }}
  {{- with include "firecell-5gc.upfPfcpNodeIdFqdn" $v }}
  pfcp_node_id_fqdn: {{ . | quote }}
  {{- end }}
  upf_info:
    sNssaiUpfInfoList:
    {{- range $v.coreConfig.nssai }}
    {{- if or (not $instSliceSd) (eq ($instSliceSd) (.sd | default "" | toString)) }}
      - sNssai: *embb_slice_sst{{ .sst }}_sd{{ .sd | default "none" }}
        dnnUpfInfoList:
        {{- if $inst.dnns }}
        {{- range $inst.dnns }}
          - dnn: {{ . | quote }}
        {{- end }}
        {{- else }}
        {{- range $v.coreConfig.dnns }}
          - dnn: {{ .dnn | quote }}
        {{- end }}
        {{- end }}
    {{- end }}
    {{- end }}
  upf_slice_list:
  {{- range $v.coreConfig.nssai }}
  {{- if or (not $instSliceSd) (eq ($instSliceSd) (.sd | default "" | toString)) }}
    - nssai:
        sst: {{ .sst }}
        {{- if .sd }}
        sd: {{ .sd | quote }}
        {{- end }}
      dnn_list:
      {{- if $inst.dnns }}
      {{- range $inst.dnns }}
        - dnn: {{ . | quote }}
          full_path: false
      {{- end }}
      {{- else }}
      {{- range $v.coreConfig.dnns }}
        - dnn: {{ .dnn | quote }}
          full_path: false
      {{- end }}
      {{- end }}
  {{- end }}
  {{- end }}
  datapath_configuration:
{{- if eq $schema "legacy" }}
    max_fars_per_pdu_session: 8
    max_qers_per_pdu_session: 8
    max_urrs_per_pdu_session: 4
    max_bars_per_pdu_session: 2
    max_sdf_filter_string_length: 512
    max_application_ids_per_session: 8
    max_traffic_endpoints_per_session: 2
    max_ethernet_packet_filters_per_session: 4
    max_redundant_transmission_params_per_session: 0
{{- else }}
    max_pdu_sessions: 100
    max_pdrs_per_pdu_session: 8
    max_fars_per_pdu_session: 8
    max_qers_per_pdu_session: 8
    max_urrs_per_pdu_session: 4
    max_bars_per_pdu_session: 2
    max_sdf_filters_per_pdu_session: 8
    max_sdf_filter_string_length: 512
    max_upf_interfaces: 4
    max_upf_redirect_interfaces: 2
    max_arp_entries: 256
    max_application_ids_per_session: 8
    max_traffic_endpoints_per_session: 2
    max_ethernet_packet_filters_per_session: 4
    max_redundant_transmission_params_per_session: 0
{{- end }}
{{- end }}
