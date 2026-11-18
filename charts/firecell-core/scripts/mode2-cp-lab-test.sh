#!/usr/bin/env bash
# Mode-2 CP lab harness (fc-ha) — no RAN/UE.
# See examples/README-rc02-active-active.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SSH_HOST="${MODE2_SSH:-firecell@192.168.30.36}"
NS="${MODE2_NS:-firecell-core}"
VIP0="${MODE2_VIP0:-192.168.30.205}"
VIP1="${MODE2_VIP1:-192.168.30.204}"
VIP_SBI="${MODE2_VIP_SBI:-192.168.30.202}"
VIP_UPF="${MODE2_VIP_UPF:-192.168.30.203}"
AMF_IMAGE_SUBSTR="${MODE2_AMF_IMAGE:-rc02-aa-}"
# Mode-2 CP allows AMF×2 or ×3; SMF×1 (CP-only) or ×2 (compose).
AMF_REPLICAS="${MODE2_AMF_REPLICAS:-}"
REPORT_DIR="${MODE2_REPORT_DIR:-/tmp/mode2-cp-lab-$(date +%Y%m%d-%H%M%S)}"
PASS=0
FAIL=0
SKIP=0
RESULTS=()

usage() {
  cat <<'EOF'
Usage: mode2-cp-lab-test.sh [--suite 0|1|2|3|0,1,2,3|all]
Env: MODE2_SSH MODE2_NS MODE2_VIP0 MODE2_VIP1 MODE2_VIP_SBI MODE2_VIP_UPF MODE2_AMF_IMAGE
EOF
}

SUITE_FILTER="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite) SUITE_FILTER="$2"; shift 2 ;;
    --suite=*) SUITE_FILTER="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

want_suite() {
  local s="$1"
  [[ "$SUITE_FILTER" == "all" ]] && return 0
  [[ ",$SUITE_FILTER," == *",$s,"* ]] && return 0
  return 1
}

# Run kubectl on cluster; pass remote command as one string.
k() {
  local cmd="$1"
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$SSH_HOST" "microk8s kubectl -n ${NS} ${cmd}"
}

k_raw() {
  local cmd="$1"
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$SSH_HOST" "microk8s kubectl ${cmd}"
}

record() {
  local id="$1" status="$2" detail="$3"
  RESULTS+=("${id}|${status}|${detail}")
  printf '  %-4s  %s — %s\n' "$status" "$id" "$detail"
  case "$status" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
    SKIP) SKIP=$((SKIP + 1)) ;;
  esac
}

wait_amf_ready() {
  local want="${1:-2}" timeout="${2:-180}" t=0 r
  while (( t < timeout )); do
    r="$(k "get sts oai-amf -o jsonpath='{.status.readyReplicas}'" 2>/dev/null || echo 0)"
    [[ "${r:-0}" == "$want" ]] && return 0
    sleep 5
    t=$((t + 5))
  done
  return 1
}

wait_ep() {
  local svc="$1" timeout="${2:-60}" t=0 ep
  while (( t < timeout )); do
    ep="$(k "get endpoints ${svc} -o jsonpath='{.subsets[*].addresses[*].ip}'" 2>/dev/null || true)"
    [[ -n "$ep" ]] && { echo "$ep"; return 0; }
    sleep 3
    t=$((t + 3))
  done
  return 1
}

wait_pod_ready_label() {
  local sel="$1" min="${2:-1}" timeout="${3:-120}" t=0 n
  while (( t < timeout )); do
    n="$(k "get pods -l ${sel} --no-headers" 2>/dev/null | awk '$3=="Running" {split($2,a,"/"); if (a[1]>0) c++} END{print c+0}')"
    (( n >= min )) && return 0
    sleep 5
    t=$((t + 5))
  done
  return 1
}

mkdir -p "$REPORT_DIR"
if [[ -z "$AMF_REPLICAS" ]]; then
  AMF_REPLICAS="$(k "get sts oai-amf -o jsonpath='{.spec.replicas}'" 2>/dev/null || echo 2)"
fi
echo "Mode-2 CP lab test — SSH=$SSH_HOST NS=$NS suites=$SUITE_FILTER"
echo "Report: $REPORT_DIR"
echo

# ── Suite 0 ──────────────────────────────────────────────────────────────────
if want_suite 0; then
  echo "=== Suite 0 — Offline ==="
  if [[ -d "$ROOT/tests/aa" ]]; then
    PY=(python3)
    if [[ -x "$ROOT/.venv-aa/bin/python" ]]; then
      PY=("$ROOT/.venv-aa/bin/python")
    elif [[ -x "$ROOT/.venv-aa/bin/pytest" ]]; then
      PY=("$ROOT/.venv-aa/bin/python")
    fi
    if (cd "$ROOT" && "${PY[@]}" -m pytest tests/aa -q --tb=line >"$REPORT_DIR/t0.1-pytest.txt" 2>&1); then
      record T0.1 PASS "pytest tests/aa via ${PY[*]}"
    else
      # Bootstrap venv once if pytest missing
      if grep -q "No module named pytest" "$REPORT_DIR/t0.1-pytest.txt" 2>/dev/null; then
        python3 -m venv "$ROOT/.venv-aa" >/dev/null 2>&1 || true
        "$ROOT/.venv-aa/bin/pip" install -q pytest >/dev/null 2>&1 || true
        if (cd "$ROOT" && "$ROOT/.venv-aa/bin/python" -m pytest tests/aa -q --tb=line >"$REPORT_DIR/t0.1-pytest.txt" 2>&1); then
          record T0.1 PASS "pytest tests/aa (bootstrapped .venv-aa)"
        else
          record T0.1 FAIL "see $REPORT_DIR/t0.1-pytest.txt"
        fi
      else
        record T0.1 FAIL "see $REPORT_DIR/t0.1-pytest.txt"
      fi
    fi
  else
    record T0.1 SKIP "tests/aa missing"
  fi
  echo
fi

# ── Suite 1 ──────────────────────────────────────────────────────────────────
if want_suite 1; then
  echo "=== Suite 1 — Baseline ==="

  # Best-effort spread AMF pods across workers (soft anti-affinity may co-locate).
  N0="$(k "get pod oai-amf-0 -o jsonpath='{.spec.nodeName}'" 2>/dev/null || true)"
  N1="$(k "get pod oai-amf-1 -o jsonpath='{.spec.nodeName}'" 2>/dev/null || true)"
  if [[ -n "$N0" && "$N0" == "$N1" ]]; then
    echo "  (preflight) AMFs co-located on ${N0}; attempting spread..."
    OTHER="fc-ha-a"
    [[ "$N0" == "fc-ha-a" ]] && OTHER="fc-ha-b"
    k_raw "uncordon fc-ha-a" >/dev/null 2>&1 || true
    k_raw "uncordon fc-ha-b" >/dev/null 2>&1 || true
    k_raw "cordon ${N0}" >/dev/null 2>&1 || true
    k "delete pod oai-amf-0 --wait=false" >/dev/null 2>&1 || true
    sleep 20
    k_raw "uncordon ${N0}" >/dev/null 2>&1 || true
    wait_amf_ready "$AMF_REPLICAS" 120 || true
  fi

  AMF_TABLE="$(k "get pods -l app=oai-amf -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,READY:.status.containerStatuses[0].ready --no-headers" 2>/dev/null || true)"
  N0="$(echo "$AMF_TABLE" | awk '$1=="oai-amf-0"{print $2}')"
  N1="$(echo "$AMF_TABLE" | awk '$1=="oai-amf-1"{print $2}')"
  R0="$(echo "$AMF_TABLE" | awk '$1=="oai-amf-0"{print $3}')"
  R1="$(echo "$AMF_TABLE" | awk '$1=="oai-amf-1"{print $3}')"
  if [[ "$R0" == "true" && "$R1" == "true" && -n "$N0" && -n "$N1" ]]; then
    if [[ "$N0" != "$N1" ]]; then
      record T1.1 PASS "amf-0@${N0} amf-1@${N1}"
    else
      record T1.1 PASS "both Ready but co-located on ${N0} (soft anti-affinity; node-kill coverage reduced)"
    fi
  else
    record T1.1 FAIL "ready=${R0}/${R1} nodes=${N0}/${N1}"
  fi

  IMG0="$(k "get pod oai-amf-0 -o jsonpath='{.spec.containers[0].image}'" 2>/dev/null || true)"
  IMG1="$(k "get pod oai-amf-1 -o jsonpath='{.spec.containers[0].image}'" 2>/dev/null || true)"
  if [[ "$IMG0" == *"$AMF_IMAGE_SUBSTR"* && "$IMG1" == *"$AMF_IMAGE_SUBSTR"* ]]; then
    record T1.2 PASS "both use ${AMF_IMAGE_SUBSTR}"
  else
    record T1.2 FAIL "img0=${IMG0} img1=${IMG1}"
  fi

  EP0="$(wait_ep oai-amf-0 45 || true)"
  EP1="$(wait_ep oai-amf-1 45 || true)"
  VIP_GOT0="$(k "get svc oai-amf-0 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
  VIP_GOT1="$(k "get svc oai-amf-1 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
  PORT0="$(k "get svc oai-amf-0 -o jsonpath='{.spec.ports[0].port}/{.spec.ports[0].protocol}'" 2>/dev/null || true)"
  PORT1="$(k "get svc oai-amf-1 -o jsonpath='{.spec.ports[0].port}/{.spec.ports[0].protocol}'" 2>/dev/null || true)"
  if [[ "$VIP_GOT0" == "$VIP0" && "$VIP_GOT1" == "$VIP1" && -n "$EP0" && -n "$EP1" && "$PORT0" == "38412/SCTP" && "$PORT1" == "38412/SCTP" ]]; then
    record T1.3 PASS "VIPs ${VIP_GOT0}/${VIP_GOT1} eps=${EP0}/${EP1}"
  else
    record T1.3 FAIL "vip=${VIP_GOT0}/${VIP_GOT1} want=${VIP0}/${VIP1} ep=${EP0}/${EP1} port=${PORT0}/${PORT1}"
  fi

  SHARED_PORTS="$(k "get svc oai-amf -o jsonpath='{range .spec.ports[*]}{.port}/{.protocol} {end}'" 2>/dev/null || true)"
  SHARED_VIP="$(k "get svc oai-amf -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
  if [[ -n "$SHARED_PORTS" && "$SHARED_PORTS" != *38412* && "$SHARED_PORTS" == *80/TCP* && "$SHARED_VIP" == "$VIP_SBI" ]]; then
    record T1.4 PASS "ports=[${SHARED_PORTS}] vip=${SHARED_VIP}"
  else
    record T1.4 FAIL "ports=[${SHARED_PORTS}] vip=${SHARED_VIP}"
  fi

  if k "get pod oai-amf-0 oai-amf-1 --no-headers" >/dev/null 2>&1; then
    record T1.5 PASS "ordinals oai-amf-0/1 present (pointer=ordinal+1 by chart)"
  else
    record T1.5 FAIL "missing AMF pods"
  fi

  UDSF_R="$(k "get pods -l app=oai-udsf --no-headers" 2>/dev/null | awk '$3=="Running" {split($2,a,"/"); if (a[1]>0) c++} END{print c+0}')"
  REDIS_R="$(k "get pods -l app=udsf-redis --no-headers" 2>/dev/null | awk '$3=="Running" {split($2,a,"/"); if (a[1]>0) c++} END{print c+0}')"
  ENABLE="$(k "get cm firecell-common-config -o yaml" 2>/dev/null | grep -c 'enable_udsf: yes' || true)"
  if (( UDSF_R >= 1 && REDIS_R >= 1 && ENABLE >= 1 )); then
    record T1.6 PASS "udsf=${UDSF_R} redis=${REDIS_R} enable_hits=${ENABLE}"
  else
    record T1.6 FAIL "udsf=${UDSF_R} redis=${REDIS_R} enable=${ENABLE}"
  fi

  SMF_R="$(k "get sts oai-smf -o jsonpath='{.spec.replicas}'" 2>/dev/null \
    || k "get deploy oai-smf -o jsonpath='{.spec.replicas}'" 2>/dev/null || echo x)"
  if [[ "$SMF_R" == "1" || "$SMF_R" == "2" ]]; then
    record T1.7 PASS "smf.replicas=${SMF_R} (1=CP-only Mode-2, 2=compose)"
  else
    record T1.7 FAIL "smf.replicas=${SMF_R}"
  fi

  # Prefer oai-upf pool (compose); fall back to legacy o5gs-upf VIP.
  UPF_POOL="$(k "get pods -l 'app in (oai-upf,oai-upf-a,oai-upf-b)' --no-headers" 2>/dev/null \
    | awk '$3=="Running" {split($2,a,"/"); if (a[1]>0) c++} END{print c+0}')"
  if [[ -z "$UPF_POOL" || "$UPF_POOL" == "0" ]]; then
    UPF_POOL="$(k "get pods --no-headers" 2>/dev/null \
      | awk '/oai-upf-/ && $3=="Running" {split($2,a,"/"); if (a[1]>0) c++} END{print c+0}')"
  fi
  UPF_READY="$(k "get pods -l app=o5gs-upf --no-headers" 2>/dev/null | awk '$2 ~ /^[12]\//{c++} END{print c+0}')"
  UPF_VIP="$(k "get svc o5gs-upf -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
  if (( UPF_POOL >= 1 )); then
    record T1.8 PASS "oai-upf pool ready=${UPF_POOL}"
  elif (( UPF_READY >= 1 )) && [[ "$UPF_VIP" == "$VIP_UPF" ]]; then
    record T1.8 PASS "o5gs-upf ready vip=${UPF_VIP}"
  else
    record T1.8 FAIL "upf_pool=${UPF_POOL} o5gs_ready=${UPF_READY} vip=${UPF_VIP} want=${VIP_UPF}"
  fi
  echo
fi

# ── Suite 2 ──────────────────────────────────────────────────────────────────
if want_suite 2; then
  echo "=== Suite 2 — CP failover ==="

  # T2.1
  k "delete pod oai-amf-0 --force --grace-period=0" >/dev/null 2>&1 || k "delete pod oai-amf-0 --wait=false" >/dev/null
  sleep 5
  R1_MID="$(k "get pod oai-amf-1 -o jsonpath='{.status.containerStatuses[0].ready}'" 2>/dev/null || echo false)"
  EP1_MID="$(wait_ep oai-amf-1 30 || true)"
  if wait_amf_ready "$AMF_REPLICAS" 120 && [[ "$R1_MID" == "true" && -n "$EP1_MID" ]]; then
    record T2.1 PASS "survivor ready; ep1=${EP1_MID}; restored ${AMF_REPLICAS}/${AMF_REPLICAS}"
  else
    record T2.1 FAIL "ready_mid=${R1_MID} ep1=${EP1_MID}"
  fi

  # T2.2
  k "delete pod oai-amf-1 --force --grace-period=0" >/dev/null 2>&1 || k "delete pod oai-amf-1 --wait=false" >/dev/null
  sleep 5
  R0_MID="$(k "get pod oai-amf-0 -o jsonpath='{.status.containerStatuses[0].ready}'" 2>/dev/null || echo false)"
  EP0_MID="$(wait_ep oai-amf-0 30 || true)"
  if wait_amf_ready "$AMF_REPLICAS" 120 && [[ "$R0_MID" == "true" && -n "$EP0_MID" ]]; then
    record T2.2 PASS "survivor ready; ep0=${EP0_MID}; restored ${AMF_REPLICAS}/${AMF_REPLICAS}"
  else
    record T2.2 FAIL "ready_mid=${R0_MID} ep0=${EP0_MID}"
  fi

  # T2.3
  k "delete pod -l app=oai-udsf --wait=false" >/dev/null
  sleep 5
  REDIS_OK="$(k "get pods -l app=udsf-redis --no-headers" 2>/dev/null | awk '$2=="1/1"{c++} END{print c+0}')"
  AMF_CL="$(k "get pods -l app=oai-amf --no-headers" 2>/dev/null | grep -c CrashLoop || true)"
  if wait_pod_ready_label "app=oai-udsf" 1 120 && (( REDIS_OK >= 1 )) && (( AMF_CL == 0 )); then
    record T2.3 PASS "udsf recovered; redis ok; no AMF crashloop"
  else
    record T2.3 FAIL "redis=${REDIS_OK} amf_crash=${AMF_CL}"
  fi
  wait_amf_ready "$AMF_REPLICAS" 120 || true

  # T2.4
  k "delete pod -l app=udsf-redis --wait=false" >/dev/null
  sleep 5
  AMF_CL="$(k "get pods -l app=oai-amf --no-headers" 2>/dev/null | grep -c CrashLoop || true)"
  if wait_pod_ready_label "app=udsf-redis" 1 120 && wait_pod_ready_label "app=oai-udsf" 1 120 && (( AMF_CL == 0 )); then
    record T2.4 PASS "redis+udsf recovered; no AMF crashloop"
  else
    record T2.4 FAIL "amf_crash=${AMF_CL}"
  fi
  wait_amf_ready "$AMF_REPLICAS" 120 || true

  # T2.5
  VIP0_B="$(k "get svc oai-amf-0 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
  VIP1_B="$(k "get svc oai-amf-1 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
  k "delete pod oai-amf-0 --wait=false" >/dev/null
  if wait_amf_ready "$AMF_REPLICAS" 180; then
    VIP0_A="$(k "get svc oai-amf-0 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
    VIP1_A="$(k "get svc oai-amf-1 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || true)"
    if [[ "$VIP0_A" == "$VIP0_B" && "$VIP1_A" == "$VIP1_B" ]]; then
      record T2.5 PASS "2/2 restored; VIPs stable ${VIP0_A}/${VIP1_A}"
    else
      record T2.5 FAIL "VIPs ${VIP0_B}/${VIP1_B} -> ${VIP0_A}/${VIP1_A}"
    fi
  else
    record T2.5 FAIL "did not restore 2/2"
  fi

  # T2.6
  NODE0="$(k "get pod oai-amf-0 -o jsonpath='{.spec.nodeName}'" 2>/dev/null || true)"
  NODE1="$(k "get pod oai-amf-1 -o jsonpath='{.spec.nodeName}'" 2>/dev/null || true)"
  if [[ -z "$NODE0" || -z "$NODE1" || "$NODE0" == "$NODE1" ]]; then
    record T2.6 SKIP "AMFs not on distinct nodes (${NODE0}/${NODE1})"
  else
    k_raw "cordon ${NODE0}" >/dev/null
    k "delete pod oai-amf-0 --wait=false" >/dev/null
    sleep 10
    SUR_READY="$(k "get pod oai-amf-1 -o jsonpath='{.status.containerStatuses[0].ready}'" 2>/dev/null || echo false)"
    EP_SUR="$(wait_ep oai-amf-1 30 || true)"
    NEW_NODE=""
    PHASE=""
    t=0
    while (( t < 120 )); do
      NEW_NODE="$(k "get pod oai-amf-0 -o jsonpath='{.spec.nodeName}'" 2>/dev/null || true)"
      PHASE="$(k "get pod oai-amf-0 -o jsonpath='{.status.phase}'" 2>/dev/null || true)"
      if [[ "$PHASE" == "Running" && -n "$NEW_NODE" && "$NEW_NODE" != "$NODE0" ]]; then
        break
      fi
      sleep 5
      t=$((t + 5))
    done
    if [[ "$SUR_READY" == "true" && -n "$EP_SUR" ]]; then
      record T2.6 PASS "cordoned ${NODE0}; survivor ready; amf-0->${NEW_NODE:-pending}:${PHASE:-}"
    else
      record T2.6 FAIL "survivor ready=${SUR_READY} ep=${EP_SUR}"
    fi
  fi

  # T2.7
  if [[ -n "${NODE0:-}" ]]; then
    k_raw "uncordon ${NODE0}" >/dev/null || true
  fi
  if [[ "${MODE2_UNCORDON_C:-0}" == "1" ]]; then
    k_raw "uncordon fc-ha-c" >/dev/null || true
  fi
  if wait_amf_ready "$AMF_REPLICAS" 180; then
    record T2.7 PASS "both AMFs Ready after uncordon/recover"
  else
    k "delete pod oai-amf-0 --force --grace-period=0" >/dev/null 2>&1 || true
    if wait_amf_ready "$AMF_REPLICAS" 180; then
      record T2.7 PASS "both AMFs Ready after forced reschedule"
    else
      record T2.7 FAIL "AMF STS not 2/2 after recover"
    fi
  fi
  echo
fi

# ── Suite 3 ──────────────────────────────────────────────────────────────────
if want_suite 3; then
  echo "=== Suite 3 — SBI soft-HA ==="

  AUSF_POD="$(k "get pods -l app=oai-ausf --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}'" 2>/dev/null || true)"
  if [[ -z "$AUSF_POD" ]]; then
    record T3.1 SKIP "no running AUSF"
  else
    k "delete pod ${AUSF_POD} --wait=false" >/dev/null
    sleep 15
    AUSF_N="$(k "get pods -l app=oai-ausf --no-headers" 2>/dev/null | awk '$2 ~ /^[1-9]/{c++} END{print c+0}')"
    NRF_N="$(k "get pods -l app=oai-nrf --no-headers" 2>/dev/null | awk '$2=="2/2"{c++} END{print c+0}')"
    if (( AUSF_N >= 1 && NRF_N >= 1 )); then
      record T3.1 PASS "ausf_ready_pods=${AUSF_N} nrf=${NRF_N}"
    else
      sleep 30
      AUSF_N="$(k "get pods -l app=oai-ausf --no-headers" 2>/dev/null | awk '$2 ~ /^[1-9]/{c++} END{print c+0}')"
      NRF_N="$(k "get pods -l app=oai-nrf --no-headers" 2>/dev/null | awk '$2=="2/2"{c++} END{print c+0}')"
      if (( AUSF_N >= 1 && NRF_N >= 1 )); then
        record T3.1 PASS "ausf_ready_pods=${AUSF_N} nrf=${NRF_N} (after wait)"
      else
        record T3.1 FAIL "ausf=${AUSF_N} nrf=${NRF_N}"
      fi
    fi
  fi

  UDM_POD="$(k "get pods -l app=oai-udm --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}'" 2>/dev/null || true)"
  if [[ -z "$UDM_POD" ]]; then
    record T3.2 SKIP "no running UDM"
  else
    k "delete pod ${UDM_POD} --wait=false" >/dev/null
    sleep 15
    UDM_N="$(k "get pods -l app=oai-udm --no-headers" 2>/dev/null | awk '$2 ~ /^[1-9]/{c++} END{print c+0}')"
    if (( UDM_N >= 1 )); then
      record T3.2 PASS "udm_ready_pods=${UDM_N}"
    else
      sleep 30
      UDM_N="$(k "get pods -l app=oai-udm --no-headers" 2>/dev/null | awk '$2 ~ /^[1-9]/{c++} END{print c+0}')"
      if (( UDM_N >= 1 )); then
        record T3.2 PASS "udm_ready_pods=${UDM_N} (after wait)"
      else
        record T3.2 FAIL "udm=${UDM_N}"
      fi
    fi
  fi
  echo
fi

# ── Report ───────────────────────────────────────────────────────────────────
REPORT_FILE="$REPORT_DIR/results.txt"
{
  echo "Mode-2 CP lab results $(date -Is)"
  echo "SSH=$SSH_HOST suites=$SUITE_FILTER"
  echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
  echo
  printf '%s\n' "${RESULTS[@]}"
} | tee "$REPORT_FILE"

{
  echo "# Mode-2 CP lab results"
  echo
  echo "- When: $(date -Is)"
  echo "- Host: ${SSH_HOST}"
  echo "- Suites: ${SUITE_FILTER}"
  echo "- PASS=${PASS} FAIL=${FAIL} SKIP=${SKIP}"
  echo
  echo "| ID | Status | Detail |"
  echo "|----|--------|--------|"
  for line in "${RESULTS[@]}"; do
    id="${line%%|*}"
    rest="${line#*|}"
    st="${rest%%|*}"
    det="${rest#*|}"
    echo "| ${id} | ${st} | ${det} |"
  done
} >"$REPORT_DIR/results.md"

# Copy report into repo-friendly path under /tmp only (lab artifact)
cp "$REPORT_DIR/results.md" "$REPORT_DIR/RESULTS.md"

echo
echo "Wrote $REPORT_FILE and $REPORT_DIR/results.md"
if (( FAIL > 0 )); then
  exit 1
fi
exit 0
