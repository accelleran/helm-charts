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
{{- if $v.cuCp.o1.enabled }}
{{- $o1 := dict
  "enabled" true
  "yang_search_path" ($v.cuCp.o1.yangSearchPath | default "/usr/local/yang")
  "overlay_file_path" "/var/lib/ocudu/o1-overlay.yml"
  "restart_on_cold_commit" ($v.cuCp.o1.restartOnColdCommit | default false) -}}
{{- $ueCtx := $v.cuCp.o1.ueContext | default dict -}}
{{- if dig "enabled" false $ueCtx }}
{{- /* The CU-CP metrics report lists UEs only with RRC layer metrics on. */ -}}
{{- $maxUes := dig "maxUes" 256 $ueCtx | int -}}
{{- if or (lt $maxUes 1) (gt $maxUes 1024) }}
{{- fail (printf "cuCp.o1.ueContext.maxUes must be 1-1024 (got %v)" $maxUes) }}
{{- end }}
{{- $_ := set $o1 "ue_context" (dict "enabled" true "max_ues" $maxUes) -}}
{{- $_ := set $base "metrics" (dict "layers" (dict "enable_rrc" true)) -}}
{{- /* RSRP/RSRQ/SINR come only from UE measurement reports, which need a periodic report per serving cell. */ -}}
{{- $mr := dig "measReport" dict $ueCtx -}}
{{- $sectors := dig "sectorIds" list $mr -}}
{{- if $sectors }}
{{- if dig "cu_cp" "mobility" "" ($v.cuCp.extraConfig | default dict) }}
{{- fail "cuCp.o1.ueContext.measReport.sectorIds and cuCp.extraConfig.cu_cp.mobility are both set: lists do not merge, so one would silently replace the other. Put the periodic serving-cell report into extraConfig.cu_cp.mobility yourself, or drop that block" }}
{{- end }}
{{- $interval := dig "intervalMs" 1024 $mr | int -}}
{{- if not (has $interval (list 120 240 480 640 1024 2048)) }}
{{- fail (printf "cuCp.o1.ueContext.measReport.intervalMs must be one of 120, 240, 480, 640, 1024, 2048 (got %v)" $interval) }}
{{- end }}
{{- $bits := $v.gnb.gnbIdBitLength | int -}}
{{- $mult := 1 -}}
{{- range until (sub 36 $bits | int) }}{{ $mult = mul $mult 2 }}{{ end -}}
{{- $cells := list -}}
{{- $ncis := list -}}
{{- range $sectors }}
{{- $sid := . | int -}}
{{- if or (lt $sid 0) (ge $sid $mult) }}
{{- fail (printf "cuCp.o1.ueContext.measReport.sectorIds: %v does not fit the %v-bit cell id (gnbIdBitLength %v)" $sid (sub 36 $bits) $bits) }}
{{- end }}
{{- $nci := add (mul ($v.gnb.gnbId | int64) $mult) $sid -}}
{{- if has $nci $ncis }}
{{- fail (printf "cuCp.o1.ueContext.measReport.sectorIds: %v is listed twice" $sid) }}
{{- end }}
{{- $ncis = append $ncis $nci -}}
{{- $cells = append $cells (dict "nr_cell_id" $nci "periodic_report_cfg_id" 1) -}}
{{- end }}
{{- $_ := set $base.cu_cp "mobility" (dict
  "cells" $cells
  "report_configs" (list (dict "report_cfg_id" 1 "report_type" "periodical" "report_interval_ms" $interval))) -}}
{{- end }}
{{- end }}
{{- $_ := set $base "o1" $o1 -}}
{{- end }}
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
{{- $f1uBind := "__POD_IP__" -}}
{{- if dig "network" "enabled" false ($v.cuUp.f1u | default dict) }}
{{- $f1uBind = include "firecell-cu.ip" $v.cuUp.f1u.network.cidr -}}
{{- end }}
{{- $base := dict
  "cu_up" (dict
    "e1ap" (dict "addrs" (include "firecell-cu.cuCpAddress" .) "bind_addrs" "0.0.0.0")
    "ngu" (dict "socket" (list (dict "bind_addr" $nguBind)))
    "f1u" (dict "socket" (list (dict "bind_addr" $f1uBind)))) -}}
{{- $o1 := $v.cuUp.o1 | default dict -}}
{{- if $o1.enabled }}
{{- $_ := set $base "o1" (dict
  "enabled" true
  "yang_search_path" ($o1.yangSearchPath | default "/usr/local/yang")
  "overlay_file_path" "/var/lib/ocudu/o1-overlay.yml"
  "restart_on_cold_commit" ($o1.restartOnColdCommit | default false)) -}}
{{- end }}
{{- $exec := dict "threads" (dict "main_pool" (dict "nof_threads" $v.cuUp.nofThreads)) -}}
{{- if $v.cuUp.cpus }}
{{- $_ := set $exec "affinities" (dict "main_pool_cpus" (toString $v.cuUp.cpus) "main_pool_pinning" "mask") -}}
{{- end }}
{{- $_ := set $base "expert_execution" $exec -}}
{{- include "firecell-cu.merge" (dict "dst" $base "src" $v.cuUp.extraConfig) | fromJson | toYaml -}}
{{- end }}
