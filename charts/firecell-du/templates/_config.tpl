{{/*
DU Ocudu config (YAML). Pass (dict "root" $ "inst" <merged instance>).
__POD_IP__ and __MPLANE_SSH_PASSWORD__ are filled in by du-launcher.sh.
*/}}
{{- define "firecell-du.duConfig" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $i := .inst -}}
{{- $ofh := $i.ofh -}}

{{- $dpdk := eq (include "firecell-du.dpdk" $i) "true" -}}
{{- $ruType := include "firecell-du.ruType" $i -}}
{{- $sdrRadio := eq (include "firecell-du.sdr" $i) "true" -}}
{{- $cell := dict
  "network_interface" (ternary (toString $ofh.vfPciAddr) (toString $ofh.interface) $dpdk)
  "enable_promiscuous" $ofh.promiscuous
  "du_mac_addr" (toString $ofh.duMac)
  "ru_mac_addr" (toString $ofh.ruMac)
  "dl_port_id" $ofh.dlPorts
  "ul_port_id" $ofh.ulPorts
  "prach_port_id" $ofh.prachPorts -}}
{{- if $ofh.vlanCp }}{{ $_ := set $cell "vlan_tag_cp" $ofh.vlanCp }}{{ end }}
{{- if $ofh.vlanUp }}{{ $_ := set $cell "vlan_tag_up" $ofh.vlanUp }}{{ end }}
{{- if or $i.mplane.enabled $ofh.vendorProfile (eq (include "firecell-du.ruVendor" $i) "simulator") }}
{{- $_ := set $cell "ru_type" (include "firecell-du.ruVendor" $i) -}}
{{- end }}
{{- if $i.mplane.enabled }}
{{- $_ := set $cell "carrier_admin" "unlocked" -}}
{{- $_ := set $cell "enabled" true -}}
{{- end }}
{{- /* The generic timing and compression unless the DU applies the vendor's profile; ofh.ruOfh wins over both. */ -}}
{{- $ruOfhBase := $ofh.ruOfh -}}
{{- if not $ofh.vendorProfile }}
{{- $ruOfhBase = include "firecell-du.merge" (dict "dst" (deepCopy $ofh.genericTiming) "src" $ofh.ruOfh) | fromJson -}}
{{- end }}
{{- $ruOfh := include "firecell-du.merge" (dict "dst" $ruOfhBase "src" (dict "cells" (list $cell))) | fromJson -}}

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
{{- if $sdrRadio }}
{{- /* Split 8: the radio (lower PHY) threads run on cpus.ru; there are no OFH threads. */ -}}
{{- $sdrKey := get (dict "aw2s" "aw2s" "uhd" "b210" "zmq" "zmq") $ruType -}}
{{- $exec = dict
  "affinities" (dict "main_pool_cpus" (toString $cpu.pool) "main_pool_pinning" "mask")
  "threads" (dict "main_pool" (dict "nof_threads" $cpu.nofThreads) "lower_phy" (dict "execution_profile" (toString (dig "sdr" $sdrKey "lowerPhyProfile" "triple" $i.ru))))
  "cell_affinities" (list (dict "ru_cpus" (toString $cpu.ru) "ru_pinning" "mask")) -}}
{{- end }}

{{- $f1uBind := "__POD_IP__" -}}
{{- if dig "network" "enabled" false ($i.f1u | default dict) }}
{{- $f1uBind = include "firecell-du.ip" $i.f1u.network.cidr -}}
{{- else if dig "bindAddress" "" ($i.f1u | default dict) }}
{{- $f1uBind = toString $i.f1u.bindAddress -}}
{{- end }}

{{- $base := dict
  "f1ap" (dict "addrs" (include "firecell-du.cuCpAddress" $root) "bind_addrs" "0.0.0.0")
  "f1u" (dict "socket" (list (dict "bind_addr" $f1uBind)))
  "gnb_id" $v.gnb.gnbId
  "gnb_id_bit_length" $v.gnb.gnbIdBitLength
  "gnb_du_id" $i.duId
  "cell_cfg" $cellCfg
  "expert_execution" $exec -}}
{{- if $sdrRadio }}
{{- $bw := int $c.bandwidthMHz -}}
{{- $sdr := dict -}}
{{- if eq $ruType "aw2s" }}
{{- $a := $i.ru.sdr.aw2s -}}
{{- if $a.generate }}
{{- /* The DU derives srate, bw=, nrb_dl= and oversampling from the model and the cell, and writes the Swallow file. */ -}}
{{- $genArgs := printf "lib=%s,rf_config=/root/.config/%s" $a.lib $a.rfConfigFile -}}
{{- with $a.extraArgs }}{{ $genArgs = printf "%s,%s" $genArgs . }}{{ end -}}
{{- $sdr = dict
  "device_driver" "aw2s"
  "device_args" $genArgs
  "tx_gain" $a.txGain
  "rx_gain" $a.rxGain -}}
{{- $block := dict
  "sku" $a.sku
  "iq_tx_shift" $a.iqTxShift
  "iq_compression" $a.iqCompression
  "time_offset_us" $a.timeOffsetUs
  "antennas" (list) -}}
{{- range $a.antennas }}
{{- $_ := set $block "antennas" (append $block.antennas (dict "id" .id "master_port" .masterPort "antenna_port" .antennaPort)) -}}
{{- end }}
{{- /* 0 dBm is a value: test for set, not for truthy (a with block skips 0). */ -}}
{{- $dbm := ($i.txPower | default dict).dbm -}}
{{- if include "firecell-du.isSet" $dbm }}{{ $_ := set $block "tx_power_dbm" $dbm }}{{ end -}}
{{- $_ := set $sdr "aw2s" $block -}}
{{- else }}
{{- /* NR max transmission bandwidth at 30 kHz SCS (TS 38.101-1 Table 5.3.2-1). */ -}}
{{- $nrbTable := dict "10" 24 "15" 38 "20" 51 "25" 65 "30" 78 "40" 106 "50" 133 "60" 162 "70" 189 "80" 217 "90" 245 "100" 273 -}}
{{- $nrb := $a.nrbDl | default (get $nrbTable (toString $bw)) -}}
{{- if not $nrb }}{{ fail (printf "%s: ru.sdr.aw2s.nrbDl is required for a %v MHz cell (no default for that bandwidth)" $i.name $bw) }}{{ end -}}
{{- $args := printf "lib=%s,rf_config=/root/.config/%s,bw=%ve6,nrb_dl=%v,iq_txshift=%v" $a.lib $a.rfConfigFile $bw $nrb $a.iqTxShift -}}
{{- with $a.extraArgs }}{{ $args = printf "%s,%s" $args . }}{{ end -}}
{{- $sdr = dict
  "device_driver" "aw2s"
  "device_args" $args
  "srate" $a.srateMHz
  "tx_gain" $a.txGain
  "rx_gain" $a.rxGain -}}
{{- end }}
{{- with $a.clock }}{{ $_ := set $sdr "clock" . }}{{ end -}}
{{- with $a.sync }}{{ $_ := set $sdr "sync" . }}{{ end -}}
{{- else if eq $ruType "uhd" }}
{{- $b := $i.ru.sdr.b210 -}}
{{- $args := "type=b200" -}}
{{- with $b.serial }}{{ $args = printf "%s,serial=%s" $args . }}{{ end -}}
{{- with $b.extraArgs }}{{ $args = printf "%s,%s" $args . }}{{ end -}}
{{- $sdr = dict
  "device_driver" "uhd"
  "device_args" $args
  "srate" $b.srateMHz
  "tx_gain" $b.txGain
  "rx_gain" $b.rxGain -}}
{{- else }}
{{- $z := $i.ru.sdr.zmq -}}
{{- $sdr = dict
  "device_driver" "zmq"
  "device_args" $z.args
  "srate" $z.srateMHz
  "tx_gain" $z.txGain
  "rx_gain" $z.rxGain -}}
{{- end }}
{{- $_ := set $base "ru_sdr" $sdr -}}
{{- else }}
{{- $_ := set $base "ru_ofh" $ruOfh -}}
{{- end }}
{{- if $dpdk }}
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

{{- $extra := deepCopy ($i.extraConfig | default dict) -}}
{{- if $sdrRadio }}
{{- /* The chart's default extraConfig tunes OFH threads; a split-8 DU has none. */ -}}
{{- $thr := dig "expert_execution" "threads" dict $extra -}}
{{- if kindIs "map" $thr }}{{ $_ := unset $thr "ofh" }}{{ end -}}
{{- end }}
{{- include "firecell-du.merge" (dict "dst" $base "src" $extra) | fromJson | toYaml -}}
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
