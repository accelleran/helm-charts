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
############# Common configuration

# Log level for all the NFs
log_level:
  general: {{ $v.coreConfig.logLevel }}

# If you enable registration, the other NFs will use the NRF discovery mechanism
register_nf:
  general: {{ $v.coreConfig.registerNf }}

http_version: {{ $v.coreConfig.httpVersion }}
http_request_timeout: {{ $v.coreConfig.httpRequestTimeoutMs }}

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
  pcf:
    host: {{ include "firecell-5gc.oaiSbiHost" (dict "ctx" $ctx "name" "oai-pcf" "clusterDNS" $useClusterDNS) }}
    sbi:
      port: 8080
      api_version: v1
      interface_name: {{ if $hostNet }}{{ $stub }}{{ else }}eth0{{ end }}
  {{- if eq $v.upf.type "oai" }}
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
  {{- end }}

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
  served_guami_list:
    - mcc: {{ $v.coreConfig.mcc }}
      mnc: {{ $v.coreConfig.mnc }}
      amf_region_id: {{ $v.coreConfig.amf.amfRegionId | quote }}
      amf_set_id: {{ $v.coreConfig.amf.amfSetId | quote }}
      amf_pointer: {{ $v.coreConfig.amf.amfPointer | quote }}
  plmn_support_list:
    - mcc: {{ $v.coreConfig.mcc }}
      mnc: {{ $v.coreConfig.mnc }}
      tac: {{ $v.coreConfig.tac }}
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
  support_features:
    use_local_subscription_info: {{ $v.coreConfig.smf.useLocalSubscriptionInfo }}
    use_local_pcc_rules: {{ $v.coreConfig.smf.useLocalPccRules }}
    enable_qer: {{ $v.coreConfig.smf.enableQer }}
    enable_udsf: {{ $v.coreConfig.smf.enableUdsf | default "no" }}
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
    - host: {{ if $v.upf.pfcpHost }}{{ $v.upf.pfcpHost }}{{ else if eq $v.upf.type "oai" }}oai-upf{{ else }}o5gs-upf{{ end }}
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
    - host: {{ if $v.upf.pfcpHost }}{{ $v.upf.pfcpHost }}{{ else if eq $v.upf.type "oai" }}oai-upf{{ else }}o5gs-upf{{ end }}
      port: 8805
      config:
        enable_upf_wo_nf_discovery: {{ $v.coreConfig.smf.enableUpfWoNfDiscovery | default "yes" }}
        enable_usage_reporting: {{ $v.coreConfig.smf.enableUsageReporting }}
        enable_dl_pdr_in_pfcp_session_establishment: {{ $v.coreConfig.smf.enableDlPdrInPfcpSessionEstablishment | default "yes" }}
        {{- if $v.upf.n3IP }}
        n3_local_ipv4: {{ $v.upf.n3IP }}
        {{- end }}
  {{- end }}
  ue_dns:
    primary_ipv4: {{ $v.coreConfig.dns.primaryIpv4 | quote }}
    secondary_ipv4: {{ $v.coreConfig.dns.secondaryIpv4 | quote }}
  ims:
    pcscf_ipv4: {{ $v.coreConfig.ims.pcscfIpv4 | quote }}
    pcscf_ipv6: {{ $v.coreConfig.ims.pcscfIpv6 | quote }}
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
    ipv4_subnet: {{ .ipv4Subnet | quote }}
{{- end }}

nrf:
  heartbeat: {{ $v.coreConfig.nrf.heartbeat }}
  suspended_nf_interval: {{ $v.coreConfig.nrf.suspendedNfInterval }}

pcf:
  enable_policy_provisioning_api: {{ $v.coreConfig.pcf.enablePolicyProvisioningApi }}

upf:
  {{- if eq $v.upf.type "oai" }}
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
  {{- end }}
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
{{- end }}
