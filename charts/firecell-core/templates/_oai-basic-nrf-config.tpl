{{/*
  Shared OAI NRF-style YAML for firecell-common-config.
  dict keys: ctx (root Helm context), hostNet (bool) — true = hostNetwork UPF / host iface names.
  smfPodConfig (bool) — true only for basic_nrf_config_ebpf_smf_hostnet.yaml mounted by oai-smf.
  When smf.hostNetwork is on, the shared qos file keeps nfs.smf.sbi.interface_name eth0 so AMF can
  reach SMF; the SMF-only hostnet file sets cni0 + smf-n4-mac for the SMF pod.
  See docs/developer/oai-upf-ebpf-hostnet.md
*/}}
{{- define "firecell-5gc.basicNrfConfigEbpfQos" -}}
{{- $ctx := index . "ctx" }}
{{- $hostNet := index . "hostNet" }}
{{- $smfPodConfig := index . "smfPodConfig" | default false }}
{{- $v := $ctx.Values }}
{{- $oh := $v.upf.oaiHostNet | default dict }}
{{- $stub := "eth0" }}
{{- $smfN4 := $v.smf.n4Interface | default "eth0" }}
{{- $smfHostNet := and ($v.smf.hostNetwork | default false) $smfPodConfig }}
{{- $smfSbiIf := $v.smf.sbiInterface | default "cni0" }}
{{- $smfPfcpMac := $v.smf.hostPfcpMacvlan | default "smf-n4-mac" }}
{{- if $hostNet }}
{{- $stub = coalesce $oh.stubInterface $v.upf.sbiInterface "eno8303" }}
{{- $smfN4 = coalesce $oh.smfN4Interface $v.upf.hostPfcpMacvlan $v.upf.n4Interface "eth0" }}
{{- end }}
{{- if $smfHostNet }}
{{- $smfN4 = $smfPfcpMac }}
{{- end }}
{{- $useClusterDNS := or $hostNet $smfHostNet }}
{{- $ipv6On := include "firecell-5gc.ipv6UserPlane" $ctx }}
############# Common configuration

# Log level for all the NFs
log_level:
  general: {{ $v.coreConfig.logLevel }}

# If you enable registration, the other NFs will use the NRF discovery mechanism
register_nf:
  general: {{ $v.coreConfig.registerNf }}

{{/* TLS needs HTTP/2: the NFs refuse tls.enable_tls with http_version 1. */ -}}
http_version: {{ if $v.global.sbi.tls.enabled }}2{{ else }}{{ $v.coreConfig.httpVersion }}{{ end }}
http_request_timeout: {{ $v.coreConfig.httpRequestTimeoutMs }}
{{- if $v.global.sbi.tls.enabled }}

# SBI TLS (global.sbi.tls): the NF's own Secret, mounted at /etc/firecell/sbi-tls
tls:
  enable_tls: true
  cert_certificate_path: /etc/firecell/sbi-tls/tls.crt
  cert_key_path: /etc/firecell/sbi-tls/tls.key
  ca_path: /etc/firecell/sbi-tls/ca.crt
  require_client_cert: {{ $v.global.sbi.tls.requireClientCert }}
  verify_peer: {{ $v.global.sbi.tls.verifyPeer }}
{{- end }}
{{- if $v.global.sbi.oauth2.enabled }}

# SBI OAuth2 (global.sbi.oauth2): the NRF's ES256 public key, mounted in every NF
oauth2:
  enable: true
  nrf_public_key_path: /etc/firecell/sbi-oauth2/public-key.pem
  token_refresh_margin_s: {{ $v.global.sbi.oauth2.tokenRefreshMarginS }}
{{- end }}

############## SBI Interfaces
nfs:
  amf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-amf" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
    n2:
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
      port: 38412
  smf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-smf" "clusterDNS" (and $useClusterDNS (not $smfHostNet))) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $smfHostNet }}{{ $smfSbiIf }}{{ else if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
    n4:
      interface_name: {{ if $smfHostNet }}{{ $smfPfcpMac }}{{ else if $hostNet }}{{ $smfN4 }}{{ else }}{{ $v.smf.n4Interface | default "eth0" }}{{ end }}
      port: 8805
  udm:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-udm" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  udr:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-udr" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  ausf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-ausf" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  nrf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-nrf" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  {{- if $v.udsf.enabled }}
  udsf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" ($v.udsf.host | default $v.udsf.serviceName | default "oai-udsf") "clusterDNS" $useClusterDNS) }}
    sbi:
      port: {{ $v.udsf.sbiPort | default 8080 }}
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  {{- end }}
  {{- if $v.nssf.enabled }}
  {{- /* The AMF reads it with amf.support_features_options.enable_nssf (coreConfig.amf.enableNssf). */}}
  nssf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-nssf" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: {{ include "firecell-5gc.nssfAmfPort" $ctx }}
      api_version: {{ $v.nssf.config.apiVersion }}
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  {{- end }}
  pcf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-pcf" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  upf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-upf" "clusterDNS" (and $useClusterDNS (not $hostNet))) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
    n3:
      interface_name: {{ $v.upf.n3Interface | default "eth0" }}
      port: 2152
    n4:
      interface_name: {{ if $hostNet }}{{ coalesce $v.upf.hostPfcpMacvlan $v.upf.n4Interface "eth0" }}{{ else }}{{ $v.upf.hostPfcpMacvlan | default "eth0" }}{{ end }}
      port: 8805
    n6:
      interface_name: {{ coalesce $v.upf.n6Interface $v.upf.n3Interface "eth0" }}
    n9:
      interface_name: {{ coalesce $v.upf.n9Interface $v.upf.n3Interface "eth0" }}
      port: 2152

#### Common for UDR and AMF
database:
  host: {{ $v.coreConfig.database.host }}
  user: {{ $v.coreConfig.database.user }}
  type: {{ $v.coreConfig.database.type }}
  password: {{ include "firecell-5gc.databasePassword" $ctx | quote }}
  database_name: {{ $v.coreConfig.database.name }}
  generate_random: {{ $v.coreConfig.database.generateRandom }}
  connection_timeout: {{ $v.coreConfig.database.connectionTimeout }}

## general single_nssai configuration
snssais:
{{- range $v.coreConfig.nssai }}
  - sst: {{ .sst }}
    {{- if .sd }}
    sd: {{ .sd | quote }}
    {{- end }}
{{- end }}

############## NF-specific configuration
{{- if and (has (lower (toString $v.coreConfig.amf.enableNssf)) (list "yes" "true" "on")) (not $v.nssf.enabled) }}
{{- fail "coreConfig.amf.enableNssf needs nssf.enabled true: the chart gives the AMF the NSSF peer (shared config nfs.nssf) only with the NSSF block, else the AMF calls its built-in default oai-nssf:80 with API v1" }}
{{- end }}
amf:
  amf_name: {{ $v.coreConfig.amf.name | quote }}
  support_features_options:
    enable_simple_scenario: {{ $v.coreConfig.amf.enableSimpleScenario }}
    enable_nssf: {{ $v.coreConfig.amf.enableNssf }}
    enable_smf_selection: {{ $v.coreConfig.amf.enableSmfSelection }}
    release_all_pdu_sessions: {{ $v.coreConfig.amf.releaseAllPduSessions }}
    enable_ims: {{ $v.coreConfig.amf.enableIms }}
    enable_udsf: {{ $v.coreConfig.amf.enableUdsf | default "no" }}
  relative_capacity: {{ $v.coreConfig.amf.relativeCapacity }}
  statistics_timer_interval: {{ $v.coreConfig.amf.statisticsTimerInterval }}
  emergency_support: {{ $v.coreConfig.amf.emergencySupport }}
  {{- with $v.coreConfig.amf.paging }}
  {{- if hasKey . "fanoutMultiGnb" }}
  paging:
    fanout_multi_gnb: {{ .fanoutMultiGnb }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.npn }}
  {{- if or (hasKey . "cagEnforcement") (hasKey . "nonCagUeRejectCause") }}
  npn:
    {{- if hasKey . "cagEnforcement" }}
    cag_enforcement: {{ .cagEnforcement }}
    {{- end }}
    {{- if hasKey . "nonCagUeRejectCause" }}
    non_cag_ue_reject_cause: {{ .nonCagUeRejectCause }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.redcap }}
  {{- if hasKey . "enabled" }}
  redcap:
    enabled: {{ .enabled }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.edrx }}
  {{- if hasKey . "maxCycleMs" }}
  {{- if not (has (toString .maxCycleMs) (list "2560" "5120" "10240")) }}
  {{- fail (printf "coreConfig.amf.edrx.maxCycleMs must be 2560, 5120 or 10240 (got %v)" .maxCycleMs) }}
  {{- end }}
  {{- end }}
  {{- if or (hasKey . "enabled") (hasKey . "redcapOnly") (hasKey . "maxCycleMs") }}
  edrx:
    {{- if hasKey . "enabled" }}
    enabled: {{ .enabled }}
    {{- end }}
    {{- if hasKey . "redcapOnly" }}
    redcap_only: {{ .redcapOnly }}
    {{- end }}
    {{- if hasKey . "maxCycleMs" }}
    max_cycle_ms: {{ int .maxCycleMs }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.ueAmbrDefault }}
  {{- if or .uplink .downlink }}
  ue_ambr_default:
    {{- if .uplink }}
    uplink: {{ .uplink | quote }}
    {{- end }}
    {{- if .downlink }}
    downlink: {{ .downlink | quote }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.handover }}
  {{- if hasKey . "sourceReleaseDelayMs" }}
  {{- $d := toString .sourceReleaseDelayMs }}
  {{- if or (not (regexMatch "^[0-9]{1,4}$" $d)) (gt (int $d) 5000) }}
  {{- fail (printf "coreConfig.amf.handover.sourceReleaseDelayMs must be 0 to 5000 (got %v)" .sourceReleaseDelayMs) }}
  {{- end }}
  handover:
    source_release_delay_ms: {{ .sourceReleaseDelayMs }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.nasTimers }}
  {{- if and (hasKey . "t3512Min") (not (kindIs "invalid" .t3512Min)) }}
  {{- /* Only values exact in GPRS Timer 3 (TS 24.008 10.5.7.4a): n x 1 min, 10 min, 1 h or
         10 h with n 1..31, as cn5g-amf encode_t3512_minutes; the AMF refuses others at start. */}}
  {{- $t := toString .t3512Min }}
  {{- $ok := false }}
  {{- if regexMatch "^[0-9]{1,5}$" $t }}
  {{- range $u := list 1 10 60 600 }}
  {{- if and (gt (int $t) 0) (eq (mod (int $t) $u) 0) (le (div (int $t) $u) 31) }}{{ $ok = true }}{{ end }}
  {{- end }}
  {{- end }}
  {{- if not $ok }}
  {{- fail (printf "coreConfig.amf.nasTimers.t3512Min must be exact in GPRS Timer 3: 1..31, or n x 10 / 60 / 600 minutes with n 1..31 (got %v)" .t3512Min) }}
  {{- end }}
  nas_timers:
    t3512_min: {{ $t }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.eir }}
  {{- if or (hasKey . "enabled") .enforcementMode }}
  eir:
    {{- if hasKey . "enabled" }}
    enabled: {{ .enabled }}
    {{- end }}
    {{- if .enforcementMode }}
    {{- if not (has .enforcementMode (list "permissive" "strict")) }}
    {{- fail (printf "coreConfig.amf.eir.enforcementMode must be permissive or strict (got %q)" (toString .enforcementMode)) }}
    {{- end }}
    enforcement_mode: {{ .enforcementMode }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.amPolicy }}
  {{- if hasKey . "enabled" }}
  am_policy:
    enabled: {{ .enabled }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.amf.callTrace }}
  {{- $prof := or .ngranTraceId .tceIpv4 .interfacesToTrace .traceDepth }}
  {{- if or $prof .autoStartSupi (hasKey . "enabled") }}
  call_trace:
    {{- if hasKey . "enabled" }}
    enabled: {{ .enabled }}
    {{- end }}
    {{- if $prof }}
    profile:
      {{- with .ngranTraceId }}
      ngran_trace_id: {{ . | quote }}
      {{- end }}
      {{- with .tceIpv4 }}
      tce_ipv4: {{ . | quote }}
      {{- end }}
      {{- with .interfacesToTrace }}
      interfaces_to_trace: {{ . }}
      {{- end }}
      {{- with .traceDepth }}
      trace_depth: {{ . | quote }}
      {{- end }}
    {{- end }}
    {{- with .autoStartSupi }}
    admin:
      auto_start_supi: {{ . | quote }}
    {{- end }}
  {{- end }}
  {{- end }}
  served_guami_list:
  {{- if eq ($v.amf.kind | default "Deployment") "StatefulSet" }}
    # [active-active] Per-ordinal amf_pointer; STS init substitutes __AMF_POINTER__.
    - mcc: {{ $v.coreConfig.mcc }}
      mnc: {{ $v.coreConfig.mnc }}
      amf_region_id: {{ $v.coreConfig.amf.amfRegionId | quote }}
      amf_set_id: {{ $v.coreConfig.amf.amfSetId | quote }}
      amf_pointer: "__AMF_POINTER__"
  {{- else }}
    - mcc: {{ $v.coreConfig.mcc }}
      mnc: {{ $v.coreConfig.mnc }}
      amf_region_id: {{ $v.coreConfig.amf.amfRegionId | quote }}
      amf_set_id: {{ $v.coreConfig.amf.amfSetId | quote }}
      amf_pointer: {{ $v.coreConfig.amf.amfPointer | quote }}
  {{- end }}
  plmn_support_list:
    - mcc: {{ $v.coreConfig.mcc }}
      mnc: {{ $v.coreConfig.mnc }}
      tac: {{ $v.coreConfig.tac }}
      {{- with $v.coreConfig.amf.nid }}
      nid: {{ . | quote }}
      {{- end }}
      nssai:
      {{- range $v.coreConfig.nssai }}
        - sst: {{ .sst }}
          {{- if .sd }}
          sd: {{ .sd | quote }}
          {{- end }}
      {{- end }}
  supported_integrity_algorithms:
  {{- range $v.coreConfig.amf.supportedIntegrityAlgorithms }}
    - {{ . | quote }}
  {{- end }}
  supported_encryption_algorithms:
  {{- range $v.coreConfig.amf.supportedEncryptionAlgorithms }}
    - {{ . | quote }}
  {{- end }}

smf:
  ue_mtu: {{ $v.coreConfig.smf.ueMtu }}
  {{- with $v.coreConfig.smf.locationApiRoot }}
  {{- if and $v.global.sbi.tls.enabled (not (hasPrefix "https://" .)) }}
  {{- fail (printf "coreConfig.smf.locationApiRoot must start with https:// with global.sbi.tls.enabled: the AMF calls it over TLS (got %q)" .) }}
  {{- end }}
  location_api_root: {{ . | quote }}
  {{- end }}
  {{- with $v.coreConfig.smf.mbs }}
  mbs:
    enabled: {{ .enabled | default false }}
    {{- with .sessions }}
    sessions:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- with $v.coreConfig.smf.handover }}
  {{- /* dataForwarding: an unquoted off in a values file is the YAML 1.1 boolean false, read
         here as "off"; other values must be one of the SMF's three (smf_config_types.cpp
         validation regex). indirectForwardingTimerMs: 100..10000 (the SMF refuses others). */}}
  {{- $df := "" }}
  {{- if hasKey . "dataForwarding" }}
  {{- if kindIs "bool" .dataForwarding }}
  {{- if .dataForwarding }}
  {{- fail "coreConfig.smf.handover.dataForwarding must be off, direct_only or direct_and_indirect (got true)" }}
  {{- end }}
  {{- $df = "off" }}
  {{- else if not (kindIs "invalid" .dataForwarding) }}
  {{- $df = toString .dataForwarding }}
  {{- end }}
  {{- if and $df (not (has $df (list "off" "direct_only" "direct_and_indirect"))) }}
  {{- fail (printf "coreConfig.smf.handover.dataForwarding must be off, direct_only or direct_and_indirect (got %q)" $df) }}
  {{- end }}
  {{- end }}
  {{- $tm := "" }}
  {{- if and (hasKey . "indirectForwardingTimerMs") (not (kindIs "invalid" .indirectForwardingTimerMs)) }}
  {{- $tm = toString .indirectForwardingTimerMs }}
  {{- if and $tm (or (not (regexMatch "^[0-9]{1,5}$" $tm)) (lt (int $tm) 100) (gt (int $tm) 10000)) }}
  {{- fail (printf "coreConfig.smf.handover.indirectForwardingTimerMs must be 100 to 10000 (got %v)" .indirectForwardingTimerMs) }}
  {{- end }}
  {{- end }}
  {{- if or (hasKey . "endMarker") $df $tm }}
  handover:
    {{- if hasKey . "endMarker" }}
    end_marker: {{ .endMarker }}
    {{- end }}
    {{- if $df }}
    {{- /* unquoted as before: the SMF reads it with yaml-cpp as<std::string>, "off" stays a string */}}
    data_forwarding: {{ $df }}
    {{- end }}
    {{- if $tm }}
    indirect_forwarding_timer_ms: {{ $tm }}
    {{- end }}
  {{- end }}
  {{- end }}
  support_features:
    use_local_subscription_info: {{ $v.coreConfig.smf.useLocalSubscriptionInfo }}
    use_local_pcc_rules: {{ $v.coreConfig.smf.useLocalPccRules }}
    enable_qer: {{ $v.coreConfig.smf.enableQer }}
    enable_udsf: {{ $v.coreConfig.smf.enableUdsf | default "no" }}
    {{- if hasKey $v.coreConfig.smf "enableIpv6Pdu" }}
    enable_ipv6_pdu: {{ $v.coreConfig.smf.enableIpv6Pdu }}
    {{- end }}
    {{- if hasKey $v.coreConfig.smf "enableEthernetPdu" }}
    enable_ethernet_pdu: {{ $v.coreConfig.smf.enableEthernetPdu }}
    {{- end }}
  upf_pool:
  {{- if $v.upf.instances }}
  {{- range $v.upf.instances }}
  {{- $upfInst := . }}
  {{- if dig "inSmfPool" true $upfInst }}
    - host: {{ $upfInst.pfcpHost | default $upfInst.hostPfcpIP }}
      port: 8805
      state: {{ dig "poolState" "ACTIVE" $upfInst | upper | quote }}
      n3_interface: {{ $upfInst.n3Interface | default $v.upf.n3Interface | quote }}
      n6_interface: {{ $upfInst.n6Interface | default $v.upf.n6Interface | quote }}
      {{- if $upfInst.dnns }}
      dnns:
      {{- range $upfInst.dnns }}
        - {{ . | quote }}
      {{- end }}
      {{- end }}
      {{- if $upfInst.nssai }}
      nssai:
        sst: {{ $upfInst.nssai.sst }}
        {{- if $upfInst.nssai.sd }}
        sd: {{ $upfInst.nssai.sd | quote }}
        {{- end }}
      {{- end }}
  {{- end }}
  {{- end }}
  {{- else }}
    - host: {{ if $v.upf.pfcpHost }}{{ $v.upf.pfcpHost }}{{ else }}oai-upf{{ end }}
      port: 8805
      state: "ACTIVE"
      n3_interface: {{ $v.upf.n3Interface | default "eth0" | quote }}
      n6_interface: {{ $v.upf.n6Interface | default "eth0" | quote }}
  {{- end }}
  upfs:
  {{- if $v.upf.instances }}
  {{- range $v.upf.instances }}
  {{- $upfInst := . }}
  {{- if dig "inSmfPool" true $upfInst }}
    - host: {{ $upfInst.pfcpHost | default $upfInst.hostPfcpIP }}
      port: 8805
      config:
        enable_upf_wo_nf_discovery: {{ $v.coreConfig.smf.enableUpfWoNfDiscovery | default "yes" }}
        enable_usage_reporting: {{ $v.coreConfig.smf.enableUsageReporting }}
        enable_dl_pdr_in_pfcp_session_establishment: {{ $v.coreConfig.smf.enableDlPdrInPfcpSessionEstablishment | default "yes" }}
        {{- if $upfInst.n3IP }}
        n3_local_ipv4: {{ $upfInst.n3IP }}
        {{- end }}
        {{- if $ipv6On }}
        enable_cp_relay: {{ if include "firecell-5gc.upfCpRelay" (dict "ctx" $ctx "inst" $upfInst) }}yes{{ else }}no{{ end }}
        {{- end }}
      {{- /* Per-UPF dnnUpfInfoList on static pool entry (OAI-SMF DNN match; top-level nssai breaks fcdevelop). */}}
      {{- if $upfInst.dnns }}
      upf_info:
        sNssaiUpfInfoList:
          {{- if $upfInst.nssai }}
          - sNssai:
              sst: {{ $upfInst.nssai.sst }}
              {{- if $upfInst.nssai.sd }}
              sd: {{ $upfInst.nssai.sd | quote }}
              {{- end }}
            dnnUpfInfoList:
            {{- range $upfInst.dnns }}
              - dnn: {{ . | quote }}
            {{- end }}
          {{- else }}
          {{- range $v.coreConfig.nssai }}
          - sNssai:
              sst: {{ .sst }}
              {{- if .sd }}
              sd: {{ .sd | quote }}
              {{- end }}
            dnnUpfInfoList:
            {{- range $upfInst.dnns }}
              - dnn: {{ . | quote }}
            {{- end }}
          {{- end }}
          {{- end }}
      {{- end }}
  {{- end }}
  {{- end }}
  {{- else }}
    - host: {{ if $v.upf.pfcpHost }}{{ $v.upf.pfcpHost }}{{ else }}oai-upf{{ end }}
      port: 8805
      config:
        enable_upf_wo_nf_discovery: {{ $v.coreConfig.smf.enableUpfWoNfDiscovery | default "yes" }}
        enable_usage_reporting: {{ $v.coreConfig.smf.enableUsageReporting }}
        enable_dl_pdr_in_pfcp_session_establishment: {{ $v.coreConfig.smf.enableDlPdrInPfcpSessionEstablishment | default "yes" }}
        {{- if $v.upf.n3IP }}
        n3_local_ipv4: {{ $v.upf.n3IP }}
        {{- end }}
        {{- if $ipv6On }}
        enable_cp_relay: yes
        {{- end }}
  {{- end }}
  ue_dns:
    primary_ipv4: {{ $v.coreConfig.dns.primaryIpv4 | quote }}
    secondary_ipv4: {{ $v.coreConfig.dns.secondaryIpv4 | quote }}
    {{- include "firecell-5gc.optionalKeys" (dict "indent" 4 "pairs" (list (list "primary_ipv6" $v.coreConfig.dns.primaryIpv6) (list "secondary_ipv6" $v.coreConfig.dns.secondaryIpv6))) }}
  ims:
    pcscf_ipv4: {{ $v.coreConfig.ims.pcscfIpv4 | quote }}
    pcscf_ipv6: {{ $v.coreConfig.ims.pcscfIpv6 | quote }}
  {{- if $ipv6On }}
  {{- /* cn5g-smf smf_ipv6_options (P23-c, P23-g): only the keys set in
         coreConfig.smf.ipv6 are written; the SMF defaults the rest. */}}
  {{- $i6 := $v.coreConfig.smf.ipv6 | default dict }}
  {{- $n4u := $i6.n4u | default dict }}
  {{- $ra := $i6.ra | default dict }}
  {{- $d6 := $i6.dhcpv6 | default dict }}
  {{- $n4uKeys := include "firecell-5gc.optionalKeys" (dict "indent" 6 "pairs" (list (list "address" $n4u.address) (list "port" $n4u.port))) }}
  {{- $raKeys := include "firecell-5gc.optionalKeys" (dict "indent" 6 "pairs" (list (list "max_rtr_adv_interval_s" $ra.maxRtrAdvIntervalS) (list "router_lifetime_s" $ra.routerLifetimeS) (list "initial_count" $ra.initialCount) (list "initial_interval_s" $ra.initialIntervalS) (list "mtu" $ra.mtu) (list "rdnss" $ra.rdnss))) }}
  {{- $d6Keys := include "firecell-5gc.optionalKeys" (dict "indent" 6 "pairs" (list (list "primary_server" $d6.primaryServer) (list "secondary_server" $d6.secondaryServer) (list "link_address" $d6.linkAddress) (list "allocate_timeout_s" $d6.allocateTimeoutS) (list "send_release" $d6.sendRelease))) }}
  {{- $llKeys := include "firecell-5gc.optionalKeys" (dict "indent" 4 "pairs" (list (list "smf_link_local" $i6.smfLinkLocal))) }}
  {{- if or $llKeys $n4uKeys $raKeys $d6Keys }}
  ipv6:{{ $llKeys }}
    {{- if $n4uKeys }}
    n4u:{{ $n4uKeys }}
    {{- end }}
    {{- if $raKeys }}
    ra:{{ $raKeys }}
    {{- end }}
    {{- if $d6Keys }}
    dhcpv6:{{ $d6Keys }}
    {{- end }}
  {{- end }}
  {{- end }}
  smf_info:
    sNssaiSmfInfoList:
    {{- range $v.coreConfig.nssai }}
      - sNssai:
          sst: {{ .sst }}
          {{- if .sd }}
          sd: {{ .sd | quote }}
          {{- end }}
        dnnSmfInfoList:
        {{- if .dnn }}
          - dnn: {{ .dnn | quote }}
        {{- else }}
        {{- range $v.coreConfig.dnns }}
          - dnn: {{ .dnn | quote }}
        {{- end }}
        {{- end }}
    {{- end }}
  local_subscription_infos:
  {{- range $v.coreConfig.nssai }}
    - single_nssai:
        sst: {{ .sst }}
        {{- if .sd }}
        sd: {{ .sd | quote }}
        {{- end }}
      dnn: {{ .dnn | default (index $v.coreConfig.dnns 0).dnn | quote }}
      qos_profile:
        5qi: 9
        session_ambr_ul: "200Mbps"
        session_ambr_dl: "400Mbps"
  {{- end }}

## DNN configuration
dnns:
{{- range $v.coreConfig.dnns }}
  - dnn: {{ .dnn | quote }}
    pdu_session_type: {{ .pduSessionType | quote }}
    {{- with .ipv4Subnet }}
    ipv4_subnet: {{ . | quote }}
    {{- end }}
    {{- include "firecell-5gc.dnnIpv6Keys" . }}
{{- end }}

nrf:
  heartbeat: {{ $v.coreConfig.nrf.heartbeat }}
  suspended_nf_interval: {{ $v.coreConfig.nrf.suspendedNfInterval }}
  {{- if $v.global.sbi.oauth2.enabled }}
  # Only the NRF reads these (cn5g-nrf L3-05-10): the ES256 private key and the token lifetime.
  oauth2_signing_key_path: /etc/firecell/sbi-oauth2-signing/signing-key.pem
  oauth2_token_validity: {{ $v.global.sbi.oauth2.tokenValiditySeconds }}
  {{- end }}

pcf:
  enable_policy_provisioning_api: {{ $v.coreConfig.pcf.enablePolicyProvisioningApi }}
  {{- with $v.coreConfig.pcf.amPolicy }}
  am_policy:
    {{- if .rfspIndex }}
    rfsp_index: {{ .rfspIndex }}
    {{- end }}
    {{- with .ueAmbr }}
    ue_ambr:
      uplink: {{ .uplink | quote }}
      downlink: {{ .downlink | quote }}
    {{- end }}
    {{- with .servAreaRes }}
    serv_area_res:
      {{- include "firecell-5gc.pcfServAreaRes" (dict "d" . "where" "coreConfig.pcf.amPolicy.servAreaRes") | nindent 6 }}
    {{- end }}
    {{- with .supi }}
    supi:
      {{- range $supi, $d := . }}
      {{ $supi | quote }}:
        {{- if $d.rfspIndex }}
        rfsp_index: {{ $d.rfspIndex }}
        {{- end }}
        {{- with $d.ueAmbr }}
        ue_ambr:
          uplink: {{ .uplink | quote }}
          downlink: {{ .downlink | quote }}
        {{- end }}
        {{- with $d.servAreaRes }}
        serv_area_res:
          {{- include "firecell-5gc.pcfServAreaRes" (dict "d" . "where" (printf "coreConfig.pcf.amPolicy.supi.%s.servAreaRes" $supi)) | nindent 10 }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- with $v.coreConfig.pcf.policyAuthorization }}
  {{- if or (hasKey . "afEvents") (hasKey . "pcscfRestoration") }}
  policy_authorization:
    {{- if hasKey . "afEvents" }}
    af_events: {{ .afEvents }}
    {{- end }}
    {{- if hasKey . "pcscfRestoration" }}
    pcscf_restoration: {{ .pcscfRestoration }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with $v.coreConfig.pcf.trace }}
  trace:
    dir: {{ include "firecell-5gc.pcfTraceDir" . | quote }}
    {{- if hasKey . "maxSessions" }}
    {{- if lt (int .maxSessions) 1 }}
    {{- fail (printf "coreConfig.pcf.trace.maxSessions must be 1 or more (got %v)" .maxSessions) }}
    {{- end }}
    max_sessions: {{ int .maxSessions }}
    {{- end }}
  {{- end }}

upf:
  {{- /* Multus macvlan: XDP_REDIRECT net1→net2 drops UL in the pod netns. Use
       upf.multus.enableBpfDatapath (default false). hostNetwork uses upf.enableBpfDatapath. */}}
  {{- $upfMultus := and (not ($v.upf.hostNetwork | default false)) (($v.upf.multus).enabled | default false) }}
  {{- $bpfRaw := ternary (dig "enableBpfDatapath" false ($v.upf.multus | default dict)) ($v.upf.enableBpfDatapath | default true) $upfMultus }}
  {{- $bpfOn := false }}
  {{- if kindIs "bool" $bpfRaw }}{{ $bpfOn = $bpfRaw }}{{ else if or (eq ($bpfRaw | toString | lower) "false") (eq ($bpfRaw | toString | lower) "no") (eq ($bpfRaw | toString) "0") }}{{ $bpfOn = false }}{{ else }}{{ $bpfOn = true }}{{ end }}
  support_features:
    enable_bpf_datapath: {{ if $bpfOn }}yes{{ else }}no{{ end }}
    enable_qos: {{ if $bpfOn }}yes{{ else }}no{{ end }}
    enable_snat: yes
    enable_eth_pdu: {{ if ($v.upf.oaiEnableEthPdu | default false) }}yes{{ else }}no{{ end }}
    {{- if $v.upf.oaiEnableEthPdu }}
    eth_dl_broadcast_enabled: {{ if $v.upf.ethDlBroadcastEnabled }}yes{{ else }}no{{ end }}
    eth_dl_flood_max_copies: {{ $v.upf.ethDlFloodMaxCopies | default 50 }}
    {{- end }}
    enable_fr: {{ if ($v.upf.enableFramedRouting | default false) }}yes{{ else }}no{{ end }}
    {{- if $ipv6On }}
    enable_cp_relay: yes
    {{- end }}
    {{- include "firecell-5gc.upfDeleteSessionsOnSmfRestart" $v.upf }}
  upf_info:
    sNssaiUpfInfoList:
    {{- range $v.coreConfig.nssai }}
      - sNssai:
          sst: {{ .sst }}
          {{- if .sd }}
          sd: {{ .sd | quote }}
          {{- end }}
        dnnUpfInfoList:
        {{- range $v.coreConfig.dnns }}
          - dnn: {{ .dnn | quote }}
        {{- end }}
    {{- end }}
  remote_n6_gw: {{ $v.upf.remoteN6Gw | default "127.0.0.1" | quote }}
  upf_slice_list:
  {{- range $v.coreConfig.nssai }}
    - nssai:
        sst: {{ .sst }}
        {{- if .sd }}
        sd: {{ .sd | quote }}
        {{- end }}
      dnn_list:
      {{- range $v.coreConfig.dnns }}
        - dnn: {{ .dnn | quote }}
          full_path: false
      {{- end }}
  {{- end }}

udm:
  suci_profiles:
    - id: {{ $v.coreConfig.udm.suciProfileId }}
      key_file: {{ $v.coreConfig.udm.suciKeyFile }}
      scheme: {{ $v.coreConfig.udm.suciScheme }}
  {{- range $v.udm.extraSuciProfiles }}
    - id: {{ required "udm.extraSuciProfiles[].id is required" .id }}
      key_file: /openair-udm/etc/suci-{{ .id }}.pem
      scheme: {{ required "udm.extraSuciProfiles[].scheme is required" .scheme }}
  {{- end }}
{{- end }}
