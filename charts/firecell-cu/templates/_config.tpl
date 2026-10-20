{{/*
CU-CP Ocudu config (YAML).
*/}}
{{- define "firecell-cu.cuCpConfig" -}}
{{- $v := .Values -}}
{{- $slices := list -}}
{{- range $v.gnb.slices }}
{{- $s := dict "sst" .sst -}}
{{- if hasKey . "sd" }}{{ $_ := set $s "sd" .sd }}{{ end }}
{{- $slices = append $slices $s -}}
{{- end }}
{{- $amf := dict
  "addrs" $v.amf.addr
  "port" $v.amf.port
  "bind_addrs" "0.0.0.0"
  "procedure_timeout" $v.amf.procedureTimeoutMs
  "supported_tracking_areas" (list (dict
    "tac" $v.gnb.tac
    "plmn_list" (list (dict "plmn" (toString $v.gnb.plmn) "tai_slice_support_list" $slices)))) -}}
{{- $base := dict
  "gnb_id" $v.gnb.gnbId
  "gnb_id_bit_length" $v.gnb.gnbIdBitLength
  "cu_cp" (dict
    "request_pdu_session_timeout" $v.cuCp.requestPduSessionTimeout
    "amf" $amf
    "e1ap" (dict "bind_addrs" "0.0.0.0")
    "f1ap" (dict "bind_addrs" "0.0.0.0")) -}}
{{- include "firecell-cu.merge" (dict "dst" $base "src" $v.cuCp.extraConfig) | fromJson | toYaml -}}
{{- end }}

{{/*
CU-UP Ocudu config (YAML). __POD_IP__ is filled in at container start.
*/}}
{{- define "firecell-cu.cuUpConfig" -}}
{{- $v := .Values -}}
{{- $nguBind := "__POD_IP__" -}}
{{- if $v.cuUp.n3.enabled }}
{{- $nguBind = include "firecell-cu.ip" $v.cuUp.n3.cidr -}}
{{- end }}
{{- $base := dict
  "cu_up" (dict
    "e1ap" (dict "addrs" (include "firecell-cu.cuCpAddress" .) "bind_addrs" "0.0.0.0")
    "ngu" (dict "socket" (list (dict "bind_addr" $nguBind)))
    "f1u" (dict "socket" (list (dict "bind_addr" "__POD_IP__")))) -}}
{{- $exec := dict "threads" (dict "main_pool" (dict "nof_threads" $v.cuUp.nofThreads)) -}}
{{- if $v.cuUp.cpus }}
{{- $_ := set $exec "affinities" (dict "main_pool_cpus" (toString $v.cuUp.cpus) "main_pool_pinning" "mask") -}}
{{- end }}
{{- $_ := set $base "expert_execution" $exec -}}
{{- include "firecell-cu.merge" (dict "dst" $base "src" $v.cuUp.extraConfig) | fromJson | toYaml -}}
{{- end }}
