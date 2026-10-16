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
http_version: {{ $v.coreConfig.httpVersion }}

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
      interface_name: {{ $n9 | quote }}
      port: 2152

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

ims:
  pcscf_ipv4: {{ $v.coreConfig.ims.pcscfIpv4 | quote }}
  pcscf_ipv6: {{ $v.coreConfig.ims.pcscfIpv6 | quote }}

dnns:
{{- range $v.coreConfig.dnns }}
  - dnn: {{ .dnn | quote }}
    pdu_session_type: {{ .pduSessionType | quote }}
    ipv4_subnet: {{ .ipv4Subnet | quote }}
{{- end }}

upf:
  support_features:
    enable_bpf_datapath: {{ if kindIs "bool" $bpfRaw }}{{ if $bpfRaw }}yes{{ else }}no{{ end }}{{ else if or (eq ($bpfRaw | toString | lower) "false") (eq ($bpfRaw | toString | lower) "no") (eq ($bpfRaw | toString) "0") }}no{{ else }}yes{{ end }}
    enable_qos: yes
    enable_urr: {{ $v.coreConfig.smf.enableQer }}
    enable_bar: no
    enable_mar: no
    enable_snat: {{ if ($inst.enableSnat | default $v.upf.enableSnat | default true) }}yes{{ else }}no{{ end }}
    enable_fr: no
    enable_eth_pdu: {{ if $v.upf.oaiEnableEthPdu }}yes{{ else }}no{{ end }}
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
