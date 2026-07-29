# Indoor Ember Fox AR smoke (device)

```yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-001
version: 2.0
status: ACTIVE
priority: deferred_rec_indoor_ember_fox
evidence_rule: OBSERVED_only_on_named_device
not: outdoor_COH
companion_runtime: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
depends_on:
  - docs/design/LIRA_AR_PRODUCTION_RIG.md
  - docs/design/AR_MVP_FREEZE.md
  - docs/design/DEBUG_OPERATOR_CONTINUATION.md
  - Issue_41_outdoor_parked
```

**Purpose:** Confirm on a **physical iPhone indoors** that the **Ember Fox** packaged runtime loads, replaces any procedural fallback, animates the skeleton, and recovers cleanly — without claiming outdoor glare, GPS, or #41 COH PASS.

**Visual gold standard (Prabu device test):** companion should read as the stylized fox mesh in  
[`receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md`](receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md)  
([evidence PNG](receipts/evidence/IMG_2534_prabu_ember_fox_device.png)) — **not** procedural multi-sphere placeholder. Operator strip should show authored `animated_usdz` (or equivalent) with animation playing when follow is active.

**Who:** Human with Debug (or Release + `-WAYKIN_OPERATOR_DEBUG`) build on tip `main` **≥ `b17864e`** (PR #246).

**Not this packet:** Daylight outdoor walk (#41). Use outdoor packet for that.

**Supersedes:** Pre-mesh DCC-clip-centric smoke expectations pinned to artist-blend tips (`d7954ac` / `3cc8ac2` era). Historical receipts retain their SHAs.

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
| `make check-lira-usdz` | PASS (`MESHY_EMBER_FOX_WALK_V1`, triple match) |
| `make validate` | PASS |
| Exact tip SHA recorded | yes |
| Receipt scaffold under `docs/design/receipts/` | yes (tip-bound; do not reuse historical `3cc8ac2` PENDING as install target) |

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
  - `finalLODDescription` / `meshEvidenceClass` (expect Ember Fox / `MESHY_EMBER_FOX_WALK_V1` class when authored path ran)  
  - `motionDiagnosticsLine` (skeleton / authored walk when live)  
  - `continuityReplantCount`, `companionPlaced`  

- Console.app: subsystem `life.scrimshaw.waykin`, category `ar`

---

## 3. Smoke protocol (~10–15 min)

| ID | Check | Pass criteria | Result |
|----|--------|---------------|--------|
| I1 | Cold launch from clean install | Splash dismisses; Home / Begin Walk visible; no crash on persistence init | |
| I2 | Demo or real Begin Walk | Session chrome; persistence healthy | |
| I3 | Open AR full-screen | Cover not swipe-dismiss; Pause/End mirrored | |
| I4 | Procedural fallback window | Fallback **may** appear only during bounded asset load; not permanently | |
| I5 | Ember Fox replacement | Authored mesh **automatically** replaces fallback | |
| I6 | Single companion | Only **one** companion remains after replacement (no duplicate anchors) | |
| I7 | Height / ground contact | Plausible scale and ground contact (not floating/sunk grossly) | |
| I8 | Skeleton animation | Embedded walk affects the **skeleton** (not wrong root-only motion) | |
| I9 | Stationary pause | Companion pauses or idles animation when stationary (if implemented) | |
| I10 | Closing distance | Animation resumes or continues while closing distance / follow | |
| I11 | Plant / replant / interrupt | Tracking loss, background/foreground, replant remain functional; no pile-up | |
| I12 | End session diagnostics | Ending records AR presentation diagnostics before dismissal; share JSON | |
| I13 | Audio | Cues audible under intended audio-session policy (or note silent-switch) | |
| I14 | Stability | No severe hitch, thermal escalation, or **repeated** asset decode during short test | |

Mark each: **PASS** / **PARTIAL** / **FAIL** / **NOT_COMPUTABLE** (not exercised).

Legacy I-series IDs from v1.0 (DCC motion labels) are retired for new walks; historical receipts may still use them.

---

## 4. Evidence fields (capture)

| Field | Value |
|-------|-------|
| Installed commit SHA | |
| Device and iOS | |
| Time to fallback appearance | |
| Time to authored mesh replacement | |
| Anchor count before replacement | |
| Anchor count after replacement | |
| Animation state | |
| Companion scale / ground observation | |
| Session recovery behavior | |
| Audio behavior | |
| Thermal observation | |
| Screenshot or screen recording reference | |
| Overall | PASS / PARTIAL / FAIL / NOT_COMPUTABLE |

---

## 5. Evidence rules

- `OBSERVED` only for direct device sight  
- Indoor ≠ outdoor glare  
- FAIL → **new bounded defect issue** (do not sidewalk-edit product under freeze)  
- Do not close #41 from this packet  
- Issue **#247** (TF hold) may close only when authored mesh replacement is OBSERVED on the archive tip  

---

## 6. Receipt path

```text
docs/design/receipts/INDOOR_AR_HYBRID_SMOKE_<UTC>_<shortsha>.md
```

Scaffold: run `scripts/indoor_ar_smoke_prep.sh` or copy template section below.

---

## 7. Related code (for operators / agents)

| Area | Path |
|------|------|
| Asset catalog / evidence class | `App/AR/Companion/LiraARAssetCatalog.swift` |
| Async load + replace | `App/AR/Companion/LiraARAssetLoader.swift` |
| Skeletal player | `App/AR/Companion/LiraSkeletalPlayer.swift` |
| USDZ | `App/Resources/Lira_AR_Base.usdz` (+ nested + docs mirrors) |
| Diagnostics publish | `App/AR/CanonicalARSessionView.swift` |
| Integrity | `make check-lira-usdz` |

---

## Template body (paste into receipt)

```markdown
# Indoor Ember Fox AR smoke receipt

\`\`\`yaml
document_id: WAYKIN-INDOOR-AR-HYBRID-SMOKE-RECEIPT
date_local:
git_sha:
git_short:
device_model:
ios:
operator:
evidence_class: OBSERVED   # note indoor in device fields — or NOT_COMPUTABLE if not run
outdoor_qa: NOT_COMPUTABLE
companion_runtime: MESHY_EMBER_FOX_WALK_V1
\`\`\`

## Results I1–I14

| ID | Result | Notes |
|----|--------|-------|
| I1 | | |
| I2 | | |
| I3 | | |
| I4 | | fallback timing: |
| I5 | | authored replace: |
| I6 | | anchor count after: |
| I7 | | scale/ground: |
| I8 | | skeleton walk: |
| I9 | | |
| I10 | | |
| I11 | | |
| I12 | | receipt schema / ar opened: |
| I13 | | audio: |
| I14 | | thermal/hitch: |

## Failures → issues

-

## Explicit non-claims

- Outdoor readability / #41 COH
- GPS / battery / thermal PASS (unless noted as OBSERVED)
```
