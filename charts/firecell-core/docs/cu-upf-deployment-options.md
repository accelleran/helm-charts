# CU placement vs UPF datapath — network architecture & system requirements

**Status:** lab playbook (Firecell core + Accelleran / Amarisoft RAN)  
**UPF image baseline:** `af-qos-upf:bugbot-ul-nongbr-htb-20261020b` (or successor with GBR-IE-only HTB arming)  
**Related:** [known-issues.md](./known-issues.md) KI-2 (macvlan sibling bypass)

This document defines **two supported deployment options**. Same CN build; only **CU placement**, **UPF N3/N6 wiring**, and **XDP attach mode** change.

---

## 1. Goals

| Goal | Meaning |
|------|---------|
| Option 1 | CU (at least CU-UP) **colocated** with UPF on the CN host → user plane must hit the eBPF hook |
| Option 2 | CU **with DU** on the RAN host; CN/UPF on a separate machine → production-like path |
| Stability | Sustained UL/DL (≫15 s), not only a short post-attach window |
| No code fork | One UPF image; topology selects wiring + `UPF_XDP_ATTACH_MODE` |

---

## 2. Option summary

| | Option 1 — CU near UPF | Option 2 — CU with DU |
|--|------------------------|------------------------|
| **CU / DU** | CU-UP (and often CU-CP) on **CN host** | CU-CP, CU-UP, DU on **RAN host** |
| **UPF host** | Same as CU | Separate from RAN |
| **N3/N6 wiring** | Linux **bridge + veth** (or equivalent) into UPF netns | **Physical NICs** (or `hostNetwork` bind to those NICs) |
| **Multus macvlan** | **Do not use** for colocated N3 (sibling bypass) | **Not required / not used** |
| **XDP mode** | **`generic`** | **`native`** |
| **Why** | Bridge delivers frames via `netif_receive_skb` so generic XDP runs | Frames arrive on the wire; native XDP on the PF is the intended path |

```text
Option 1 (colocated)
  [CN host]
    CU-UP ──veth──► br-n3 ──veth──► UPF net1 (N3)   XDP=generic
    DN   ◄──────── br-n6 ──veth──► UPF net2 (N6)

Option 2 (CU with DU)
  [RAN host]              [switch]              [CN host]
    DU ── F1 ── CU-UP ════════════ N3 GTP ═══════► UPF on phys NIC (N3)  XDP=native
                                      N6 ◄════════ UPF on phys NIC (N6) ──► DN
```

---

## 3. Network architecture (detail)

### 3.1 Option 1 — CU near UPF (colocated)

**Problem avoided:** two **macvlan** endpoints on the same parent (CU N3 + UPF N3) under **generic XDP** — host-local delivery **bypasses** the XDP hook (KI-2). Symptom: N3 `rx↑`, XDP `run_cnt` flat, N6 `tx=0`.

**Target L2:**

1. Create `br-n3` / `br-n6` on the CN host (`stp_state=0`).
2. Enslave physical uplinks **only after** removing macvlan children and setting `sriov_numvfs=0` on those PFs (else `RTNETLINK: Device or resource busy`).
3. Attach UPF `net1`/`net2` via **veth** (or bridge NAD) into `br-n3`/`br-n6`.
4. Attach colocated CU-UP N3 into `br-n3` the same way.
5. Move / flush L3 (UPF N3 addr e.g. `10.3.0.101`, N6 toward DN) onto the bridge or UPF veth per lab addressing.

**Control plane:** NGAP/N2 to AMF as today; only N3/N6 user-plane wiring is special.

### 3.2 Option 2 — CU with DU (separated)

**No macvlan required.** UPF N3 and N6 bind to **physical interfaces** on the CN host (direct or via `hostNetwork`). CU-UP on the RAN host sends GTP-U across the lab switch to the UPF N3 address.

**Do not** leave Option 1 bridges/VFs/macvlan children in place when switching to Option 2 — they pollute the PF and confuse addressing.

**XDP:** `UPF_XDP_ATTACH_MODE=native` on the physical N3/N6 devices.

---

## 4. System requirements

### 4.1 Hosts (lab reference)

| Role | Example | Notes |
|------|---------|--------|
| CN / UPF | `192.168.30.11` (`core-firecell-30-11`) | ice NICs e.g. `enp1s0f0np0` (N3), `enp1s0f1np1` (N6) |
| RAN (DU+CU) | `192.168.30.30` (`ran-firecell-30-30`) | Option 2 only for CU-UP |
| UE / traffic gen | Amarisoft `uectl` on RAN host (or equiv.) | Test UE e.g. IMSI `…0002` → `12.1.1.2` |
| DN gateway | `10.10.0.2` (lab) | Ping target for UL/DL smoke |

### 4.2 Software / CN

| Component | Requirement |
|-----------|-------------|
| UPF image | Build with **GBR-IE-only** HTB arming (see assumptions) |
| UPF config | `enable_bpf_datapath: yes`; `enable_qos: yes` allowed |
| Env | `UPF_N3_IF` / `UPF_N6_IF`; `UPF_XDP_ATTACH_MODE` = `generic` (Opt1) or `native` (Opt2) |
| SMF | PFCP association to **current** UPF pod/node IP after every UPF roll |
| Kernel / NIC | Option 1: bridge + generic XDP on veth. Option 2: driver **native XDP** on the PF used for N3/N6 |

### 4.3 What is explicitly out of requirements for these two options

- SR-IOV VF + native XDP on **iavf** (lab: native XDP not supported on VF; treated as future Option A, not required here).
- N9 / UL CL E2E (separate UL CL + PSA lab; static contracts only on this branch unless that topology is stood up).

---

## 5. Assumptions

1. **One UPF datapath image** serves both options; operators only change wiring + XDP mode.
2. **Lab default QoS** from SMF is Non-GBR / Session-AMBR carried as QER **MBR** (often with QFI stamped `1`). That must **not** force PASS→TC HTB for basic forwarding.
3. **Separated topology** does not need Multus macvlan; physical (or hostNetwork) is enough and preferred for Option 2.
4. **Colocated topology** always uses bridge/veth + generic XDP — not “native on macvlan”.
5. After UPF restart, SMF may need an updated UPF address / new PFCP association before UE traffic recovers.
6. Amarisoft / Accelleran CU behaviour is equivalent for KI-2: the failure mode is host networking, not the CU implementation.

---

## 6. Known flaws and limitations (honest)

| ID | Flaw | Impact | Mitigation today |
|----|------|--------|------------------|
| F1 | **HTB / PASS→TC QoS path** unstable on generic XDP (~12–15 s UL blackhole: N3 rx↑, N6 tx flat, `tc_redirect_traffic` SHOT) | Real GBR shaping via TC not production-ready on Opt1 | Arm `m_qos_enabling` only when QER has **explicit GBR IE**; MBR-only stays on XDP redirect |
| F2 | Per-session **QERProgram** re-attach (`Exclusivity flag on, cannot modify`) | Multi-UE can disturb TC hooks/maps | Avoid TC path for MBR-only; longer-term: shared QERProgram |
| F3 | `tc_redirect_traffic` **requires XDP metadata** then SHOTs if missing | Fragile under generic XDP | Same as F1; fix redirect to not require meta for direction |
| F4 | Macvlan **sibling bypass** under generic XDP | Colocated CU+UPF on macvlan never hits XDP | Option 1 bridge/veth only |
| F5 | Leftover **SR-IOV VFs / bridges / NADs** from experiments | `busy` enslave, wrong L2, confusion | Tear down before switching options |
| F6 | **N9 / UL CL** not validated on single-UPF `.11` lab | Cannot claim ULCL E2E from this playbook alone | Static `tests/n9/tv_8390_skeleton.sh`; dedicated ULCL lab for live TVs |
| F7 | Lab often still runs **macvlan + generic** even when CU is on RAN | Works for Option-2 *placement* but is **not** the target Option 2 architecture | Align deploy to physical + native when exercising Option 2 “for real” |

**What still works despite F1–F3:** gate status in XDP; N3↔N6 forward on XDP redirect; N9 UL `REDIRECT_N9` before QoS branch (MBR-only + empty `m_qos_enabling` is safe for N9).

---

## 7. Acceptance tests (no UPF code changes)

Use the **same** traffic checks for both options; only topology/mode preconditions differ.

### 7.1 Common pass criteria

| ID | Test | Pass |
|----|------|------|
| T1 | UE register + PDU session | UE IP (e.g. `12.1.1.2`) |
| T2 | Timed ping UE → DN gw (`10.10.0.2`), ≥60 s, ~1 pkt / 2 s | ≥95% success; **no** systematic fail after ~15 s |
| T3 | UL counters during T2 | N3 rx↑ **and** N6 tx↑ |
| T4 | DL counters | N6 rx↑ then N3 tx↑ |
| T5 | XDP invoked | bpftool `run_cnt` on N3 uplink prog increases with UL |
| T6 | QoS arming (lab MBR-only) | `m_qos_enabling` empty; UPF log keeps XDP redirect |

### 7.2 Option-specific preconditions

| ID | Option 1 | Option 2 |
|----|----------|----------|
| P1 | CU-UP on CN host; UPF on bridge/veth | CU-UP (+ DU) on RAN host; UPF on **physical** N3/N6 |
| P2 | `UPF_XDP_ATTACH_MODE=generic`; `xdpgeneric` on UPF N3 | `UPF_XDP_ATTACH_MODE=native`; **native** XDP on phys N3 |
| P3 | No macvlan siblings on N3 parent for CU↔UPF | **No** macvlan, **no** br-n3/br-n6 required |

### 7.3 Suggested order

1. **Option 2** (RAN CU+DU, CN UPF) — validate separated path; prefer physical+native when reconfiguring without code changes.  
2. **Option 1** — move CU-UP to CN host, bridge wiring, generic XDP.  
3. Flip back to Option 2 once to prove the playbook is reversible (cleanup F5).

---

## 8. Lab inventory snapshot (reference)

Captured during playbook authoring (adjust as lab drifts):

| Item | Observation |
|------|-------------|
| UPF node | `192.168.30.11`, image `af-qos-upf:bugbot-ul-nongbr-htb-20261020b` |
| RAN node | `192.168.30.30` — `cu-cp`, `cu-up`, `du` Running (Option 2 **placement**) |
| Drift | UPF may still show Multus **macvlan** + **generic** XDP while CU is on RAN — functionally Option-2-like for CU placement, but **not** yet target Option 2 wiring (see F7) |

---

## 9. Test results log

### 2026-10-20 — Option 2 placement (no UPF code changes)

| Item | Result |
|------|--------|
| CU/DU | On `ran-firecell-30-30` (`cu-cp`, `cu-up`, `du` Running) |
| UPF | `af-qos-upf:bugbot-ul-nongbr-htb-20261020b` on `.11` |
| Wiring drift (F7) | Still Multus **macvlan** + **`xdpgeneric`** (not yet physical+native) |
| T1–T2 | UE2 PDU OK; ping `10.10.0.2` **30/30 over ~60s** (`SUMMARY_OPT2 ok=30 fail=0`) |
| T6 | `m_qos_enabling` **empty**; log: keep XDP redirect (MBR-only / no GBR IE) |
| Verdict | **PASS** for separated CU+DU **placement** + sustained UL. Target Option 2 wiring (physical + native, no macvlan) still to align. |

### 2026-10-20 — Option 2 target architecture (physical NICs + native XDP, no macvlan)

| Item | Result |
|------|--------|
| CU/DU (C1) | On `ran-firecell-30-30` (`cu-cp`, `cu-up`, `du` Running) |
| UPF | `af-qos-upf:bugbot-ul-nongbr-htb-20261020b` on `core-firecell-30-11` |
| Wiring & XDP (C2–C3) | `host-device` CNI NADs `upf-n3-phys` (`enp1s0f0np0` → `net1` `10.3.0.101/24`) and `upf-n6-phys` (`enp1s0f1np1` → `net2` `10.10.0.101/24`), `UPF_XDP_ATTACH_MODE=native` (`mode=xdp` on `ice` driver, no macvlan) |
| T1–T2 (A1–A2) | UE2 registered (`12.1.1.2`); ping `10.10.0.2` **32/32 over 64s** (`SUMMARY_opt2_phys_native ok=32 fail=0 first_fail_at=none`) |
| T3–T5 (A3–A4) | UL: `net1` rx `1724802→1724839` (+37), `xdp_handle_uplink` `run_cnt` `92→129` (+37), `m_dp_iface_coun` N6 TX `4→36` (+32). DL: `net2` rx `7876451→7876529` (+78), `xdp_handle_shaping` `run_cnt` `327→405` (+78), `m_dp_iface_coun` N3 TX `4→36` (+32) |
| T6 (A5–A6) | `m_qos_enabling` **0 entries** (`keep XDP redirect`); static N9 `tests/n9/tv_8390_skeleton.sh` **25/25 PASS** |
| Verdict | **PASS** — meets C1–C4 and A1–A6 |

### 2026-10-20 — Option 1 target architecture (colocated CU-UP on CN + `br-n3` / `br-n6` + `xdpgeneric`)

| Item | Result |
|------|--------|
| Placement & Wiring (B1–B2) | `cu-up` scheduled on `core-firecell-30-11` attached to `br-n3` via `gnb-n3-bridge` (`10.3.0.5/24`); UPF `net1` on `upf-n3-bridge` (`br-n3`, `10.3.0.101/24`) and `net2` on `upf-n6-bridge` (`br-n6` enslaving `enp1s0f1np1`, `10.10.0.101/24`); `UPF_XDP_ATTACH_MODE=generic` (`mode=xdpgeneric`, `kind=veth`) |
| Operational note | Set `nmcli dev set enp1s0f0np0 managed no` and `nmcli dev set enp1s0f1np1 managed no` on `.11` so NetworkManager DHCP timeout does not detach `enp1s0f1np1` from `br-n6` after releasing `host-device` PFs |
| T1–T2 (A1–A2) | UE2 registered (`12.1.1.2`); ping `10.10.0.2` **32/32 over 64s** (`SUMMARY_opt1_colocated_bridge ok=32 fail=0 first_fail_at=none`) |
| T3–T5 (A3–A4) | UL: `net1` rx `45→81` (+36), `net2` tx `24→59` (+35), `xdp_handle_uplink` `run_cnt` `40→76` (+36), `m_dp_iface_coun` N6 TX `4→36` (+32). DL: `net2` rx `55→131` (+76), `net1` tx `25→59` (+34), `xdp_handle_shaping` `run_cnt` `46→122` (+76), `m_dp_iface_coun` N3 TX `4→36` (+32) |
| T6 (A5) | `m_qos_enabling` **0 entries** (`keep XDP redirect (no m_qos_enabling)`) |
| Verdict | **PASS** — meets B1–B3 and A1–A5 |

---

## 10. Document history

| Date | Note |
|------|------|
| 2026-10-20 | Initial architecture, requirements, assumptions, flaws; dual-option test plan |
| 2026-10-20 | Option 2 placement sustained UL PASS (macvlan+generic drift noted as F7) |
| 2026-10-20 | Option 1 colocated bridge initial attempt (`net2` left on macvlan): UL N6 tx↑ but DL 0% |
| 2026-10-20 | Full PASS on both target architectures: Option 2 (`upf-n3-phys`/`upf-n6-phys` + `native` XDP, 32/32 over 64s) and Option 1 (colocated `cu-up` + `upf-n3-bridge`/`upf-n6-bridge` + `generic` XDP, 32/32 over 64s) |
