# Indoor AR hybrid smoke (device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-001
version: 1.0
status: ACTIVE
priority: deferred_rec_3
evidence_rule: OBSERVED_only_on_named_device
not: outdoor_COH
depends_on:
  - docs/design/LIRA_AR_PRODUCTION_RIG.md
  - docs/design/AR_MVP_FREEZE.md
  - docs/design/DEBUG_OPERATOR_CONTINUATION.md
  - Issue_41_outdoor_parked
```

**Purpose:** Confirm on a **physical iPhone indoors** that DCC / hybrid / puppet motion paths are live and legible — without claiming outdoor glare, GPS, or #41 COH PASS.

**Who:** Human with Debug (or Release + `-WAYKIN_OPERATOR_DEBUG`) build on tip `main`.

**Not this packet:** Daylight outdoor walk (#41). Use outdoor packet for that.

---

## 0. Pre-device gate (laptop)

```bash
git checkout main && git pull --ff-only
SHA=$(git rev-parse HEAD)
echo "tip=$SHA"
make check-lira-usdz
make validate
# optional:
bash scripts/sim_walk_preflight.sh
bash scripts/indoor_ar_smoke_prep.sh
```

| Gate | Required |
|------|----------|
| `make check-lira-usdz` | PASS |
| `make validate` | PASS |
| Exact tip SHA recorded | yes |
| Receipt scaffold under `docs/design/receipts/` | yes |

---

## 1. Build identity

| Field | Value |
|-------|-------|
| `git_sha` (full) | |
| `git_short` | |
| Config | Debug (preferred) |
| Device model | |
| iOS | |
| Date (local) | |
| Operator | |
| Light | indoor / window / artificial |

Install **exact** tip. Do not mix SHAs mid-session.

---

## 2. Operator chrome

- DEBUG build: operator strip ON during Active Session  
- Settings → Field-test receipts → after AR session end, **Share latest JSON**  
- Confirm receipt schema ≥ 5 and inspect:

  - `summary.arPresentation.arSessionOpened`  
  - `finalLODDescription` / `meshEvidenceClass`  
  - `motionDiagnosticsLine` (expect `dcc:` / `hybrid:` / `puppet:` style labels when skeletal path ran)  
  - `continuityReplantCount`, `companionPlaced`  

- Console.app: subsystem `life.scrimshaw.waykin`, category `ar`

---

## 3. Smoke protocol (~10–15 min)

| ID | Check | Pass criteria | Result |
|----|--------|---------------|--------|
| I1 | Cold launch → Home | Splash dismisses; Begin Walk visible | |
| I2 | Demo Begin Walk | Session chrome; operator strip shows Persist + Map | |
| I3 | Open AR full-screen | Cover not swipe-dismiss; Pause/End mirrored | |
| I4 | Plant / place Lira | Companion becomes visible on horizontal surface (table/floor) | |
| I5 | Motion source | Operator chrome / receipt motion line shows **dcc**, **hybrid**, or **puppet** (not stuck `none` forever after place) | |
| I6 | Idle → walk presentation | Distinct motion or still change when session state advances (no color-only claim) | |
| I7 | Tracking loss (cover lens briefly) | Continuity hint or calm recovery; no duplicate Liras after recover | |
| I8 | Clear / leave AR | No leftover companion when AR closed | |
| I9 | Re-open AR | Single Lira; no resurrected pile of entities | |
| I10 | Reduce Motion ON | Continuous decorative motion stops or stills; state still readable | |
| I11 | Skin / form if available | Dawn/Veil/Rupture materials change without crash | |
| I12 | End walk → Settings receipt | Share JSON; `arPresentation` filled; no coordinates | |

Mark each: **PASS** / **FAIL** / **NOT_COMPUTABLE** (not exercised).

---

## 4. Evidence rules

- `OBSERVED` only for direct device sight  
- Indoor ≠ outdoor glare  
- FAIL → **new bounded defect issue** (do not sidewalk-edit product under freeze)  
- Do not close #41 from this packet  

---

## 5. Receipt path

```text
docs/design/receipts/INDOOR_AR_HYBRID_SMOKE_<UTC>_<shortsha>.md
```

Scaffold: run `scripts/indoor_ar_smoke_prep.sh` or copy template section below.

---

## 6. Related code (for operators / agents)

| Area | Path |
|------|------|
| Clip source enum | `App/AR/Companion/LiraSkeletalPlayer.swift` (`dcc` / `hybrid` / `puppet`) |
| USDZ | `App/Resources/Lira_AR_Base.usdz` |
| Diagnostics publish | `App/AR/CanonicalARSessionView.swift` |
| Integrity | `make check-lira-usdz` |

---

## Template body (paste into receipt)

```markdown
# Indoor AR hybrid smoke receipt

\`\`\`yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_local:
git_sha:
git_short:
device_model:
ios:
operator:
evidence_class: OBSERVED_INDOOR_DEVICE   # or NOT_COMPUTABLE if not run
outdoor_qa: NOT_COMPUTABLE
\`\`\`

## Results I1–I12

| ID | Result | Notes |
|----|--------|-------|
| I1 | | |
| I2 | | |
| I3 | | |
| I4 | | |
| I5 | | motion label: |
| I6 | | |
| I7 | | |
| I8 | | |
| I9 | | |
| I10 | | |
| I11 | | |
| I12 | | receipt schema / ar opened: |

## Failures → issues

-

## Explicit non-claims

- Outdoor readability / #41 COH
- GPS / battery / thermal (unless noted)
```
