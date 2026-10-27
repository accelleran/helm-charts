{{/*
DU Ocudu config (YAML). Pass (dict "root" $ "inst" <merged instance>).
__POD_IP__ and __MPLANE_SSH_PASSWORD__ are filled in by du-launcher.sh.
*/}}
{{- define "firecell-du.duConfig" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $i := .inst -}}
{{- $ofh := $i.ofh -}}
{{- $socket := eq (include "firecell-du.ofhSocket" $i) "true" -}}

{{- $cell := dict
  "network_interface" (ternary (toString $ofh.interface) (toString $ofh.vfPciAddr) $socket)
  "enable_promiscuous" $ofh.promiscuous
  "du_mac_addr" (toString $ofh.duMac)
  "ru_mac_addr" (toString $ofh.ruMac)
  "dl_port_id" $ofh.dlPorts
  "ul_port_id" $ofh.ulPorts
  "prach_port_id" $ofh.prachPorts -}}
{{- if $ofh.vlanCp }}{{ $_ := set $cell "vlan_tag_cp" $ofh.vlanCp }}{{ end }}
{{- if $ofh.vlanUp }}{{ $_ := set $cell "vlan_tag_up" $ofh.vlanUp }}{{ end }}
{{- if $i.mplane.enabled }}
{{- $_ := set $cell "ru_type" $ofh.ruType -}}
{{- $_ := set $cell "carrier_admin" "unlocked" -}}
{{- $_ := set $cell "enabled" true -}}
{{- end }}
{{- $ruOfh := include "firecell-du.merge" (dict "dst" $ofh.ruOfh "src" (dict "cells" (list $cell))) | fromJson -}}

{{- $slicing := list -}}
{{- range $v.gnb.slices }}
{{- $s := dict "sst" .sst -}}
{{- if hasKey . "sd" }}{{ $_ := set $s "sd" .sd }}{{ end }}
{{- with .schedCfg }}{{ $_ := set $s "sched_cfg" . }}{{ end }}
{{- $slicing = append $slicing $s -}}
{{- end }}

{{- $c := $i.cell -}}
{{- $cellCfg := dict
  "sector_id" $c.sectorId
  "dl_arfcn" $c.dlArfcn
  "band" $c.band
  "channel_bandwidth_MHz" $c.bandwidthMHz
  "common_scs" $c.commonScs
  "plmn" (toString $v.gnb.plmn)
  "tac" $v.gnb.tac
  "pci" $c.pci
  "nof_antennas_dl" $c.antennasDl
  "nof_antennas_ul" $c.antennasUl
  "slicing" $slicing -}}

{{- $cpu := $i.cpus -}}
{{- $txrx := list -}}
{{- range (include "firecell-du.cpuList" $cpu.txrx | fromJsonArray) }}
{{- $txrx = append $txrx (toString (int .)) -}}
{{- end }}
{{- $exec := dict
  "affinities" (dict
    "main_pool_cpus" (toString $cpu.pool)
    "main_pool_pinning" "mask"
    "ofh" (dict "timing_cpu" (toString $cpu.timing) "txrx_cpus" $txrx))
  "threads" (dict "main_pool" (dict "nof_threads" $cpu.nofThreads))
  "cell_affinities" (list (dict "ru_cpus" (printf "%v,%v" $cpu.timing (join "," $txrx)) "ru_pinning" "mask")) -}}

{{- $f1uBind := "__POD_IP__" -}}
{{- if dig "network" "enabled" false ($i.f1u | default dict) }}
{{- $f1uBind = include "firecell-du.ip" $i.f1u.network.cidr -}}
{{- end }}

{{- $base := dict
  "f1ap" (dict "addrs" (include "firecell-du.cuCpAddress" $root) "bind_addrs" "0.0.0.0")
  "f1u" (dict "socket" (list (dict "bind_addr" $f1uBind)))
  "gnb_id" $v.gnb.gnbId
  "gnb_id_bit_length" $v.gnb.gnbIdBitLength
  "gnb_du_id" $i.duId
  "ru_ofh" $ruOfh
  "cell_cfg" $cellCfg
  "expert_execution" $exec -}}
{{- /* No hal section: Ocudu then sends OFH over a kernel socket instead of DPDK. */ -}}
{{- if not $socket }}
{{- $_ := set $base "hal" (dict "eal_args" (printf "--lcores (0-1)@(%v) --proc-type auto --file-prefix %s -a %v" $cpu.ealLcores $i.name $ofh.vfPciAddr)) -}}
{{- end }}

{{- if $i.mplane.enabled }}
{{- $mp := dict
  "enabled" true
  "call_home_enabled" true
  "call_home_port" $i.mplane.callHomePort
  "ssh_username" $i.mplane.sshUser
  "ssh_password" "__MPLANE_SSH_PASSWORD__"
  "tx_array_gain_db" $i.mplane.txArrayGainDb -}}
{{- $_ := set $base "mplane" (include "firecell-du.merge" (dict "dst" $mp "src" $i.mplane.extra) | fromJson) -}}
{{- end }}

{{- /* Per-UE PM needs O1 and the scheduler metrics that feed ue-metrics. */ -}}
{{- $uePm := $i.o1.ueMetrics | default dict -}}
{{- $uePmOn := and $i.o1.enabled (dig "enabled" false $uePm) -}}
{{- if and $uePmOn (eq (toString (dig "metrics" "layers" "enable_sched" "" ($i.extraConfig | default dict))) "false") }}
{{- fail (printf "%s: o1.ueMetrics is on but extraConfig.metrics.layers.enable_sched is false: ue-metrics come from the scheduler metrics. Drop that override (the chart sets enable_sched itself) or set o1.ueMetrics.enabled false" $i.name) }}
{{- end }}
{{- $_ := set $base "metrics" (dict "layers" (dict "enable_sched" $uePmOn)) -}}

{{- if $i.o1.enabled }}
{{- $o1 := dict
  "enabled" true
  "yang_search_path" $i.o1.yangSearchPath
  "overlay_file_path" "/var/lib/ocudu/o1-overlay.yml"
  "restart_on_cold_commit" $i.o1.restartOnColdCommit -}}
{{- if $uePmOn }}
{{- $_ := set $o1 "ue_metrics" (dict
  "enabled" true
  "history_windows" (dig "historyWindows" 40 $uePm | int)
  "max_ues" (dig "maxUes" 256 $uePm | int)) -}}
{{- end }}
{{- $_ := set $base "o1" $o1 -}}
{{- end }}

{{- include "firecell-du.merge" (dict "dst" $base "src" $i.extraConfig) | fromJson | toYaml -}}
{{- end }}

{{/*
dnsmasq config for a DU's O-RU M-plane lease. The RU learns the controller
(call-home) address from O-RAN option 43 sub-option 129, sent only to clients
whose vendor class contains "o-ran-ru2/".
*/}}
{{- define "firecell-du.dnsmasqConfig" -}}
{{- $m := .mplane -}}
{{- $d := $m.dhcp -}}
interface=mplane0
bind-interfaces
except-interface=lo
port=0
log-dhcp
dhcp-authoritative
dhcp-leasefile=/tmp/dnsmasq.leases
dhcp-range={{ $d.ruIp }},static,{{ $d.leaseTime }}
dhcp-host={{ .ofh.ruMac }},{{ $d.ruIp }},{{ $d.leaseTime }}
dhcp-option=vendor:o-ran-ru2/,129,{{ include "firecell-du.ip" $m.duCidr }}
{{- with $d.controllerFqdn }}
dhcp-option=vendor:o-ran-ru2/,130,"{{ . }}"
{{- end }}
{{- with $d.router }}
dhcp-option=option:router,{{ . }}
{{- end }}
{{- end }}
