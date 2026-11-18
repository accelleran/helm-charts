# Mode-2 CP lab results (sandbox harness)

Harness: `charts/firecell-core/scripts/mode2-cp-lab-test.sh`

Live cluster at these runs still had Helm release **`firecell-5gc`** (galaxy)
with Mode-2 already deployed. Suites validate the Mode-2 CP shape + failover.
Cutover to release name **`firecell-core`** from this sandbox chart is a
separate deploy step (not done here — would replace the live release).

| When | Suites | Result |
|------|--------|--------|
| 2026-11-18 | 0,1 | 9/9 PASS |
| 2026-11-18 | 2,3 | 9/9 PASS |

`ha.fullActiveActive` remains false until PDU kill matrix on firecell-core images.
