# Simulator Preflight (before outdoor walk)

```yaml
document_id: WAYKIN-SIM-PREFLIGHT-001
version: 0.1
status: ACTIVE
evidence_ceiling: OBSERVED_IN_SIMULATOR_ONLY
cannot_prove: [sun_glare, night_street_glare, outdoor_contrast, GPS_integrity]
```

Use this to catch UI regressions **before** a physical walk. Passing preflight does **not** complete outdoor QA.

## Commands

```bash
git rev-parse --short HEAD
make validate
# optional:
make validate-simulator
```

Record SHA: _______________

## Appearance

| Check | How | Result |
| ----- | --- | ------ |
| S1 Day theme | Settings → Light, or scheme Light | PASS / FAIL |
| S2 Night theme | Settings → Dark | PASS / FAIL |
| S3 Night ≠ invert | Visually compare mist vs indigo-earth | PASS / FAIL |
| S4 Bond text day | Home bond line uses darker bondText | PASS / FAIL |

## Session chrome

| Check | How | Result |
| ----- | --- | ------ |
| S5 Begin Walk | Home → Begin Walk (demo) | PASS / FAIL |
| S6 Lira silhouette | Active: silhouette + filament + chest core | PASS / FAIL |
| S7 Pause / End | 48pt, End not alarm-red | PASS / FAIL |
| S8 Ahead / behind icons | Labels with WKIcon path icons | PASS / FAIL |
| S9 Reduced motion | Accessibility → Reduce Motion on; restart app | PASS / FAIL |
| S10 Pressure path | Run demo until pressure language; ring + text | PASS / FAIL |

## Accessibility

| Check | How | Result |
| ----- | --- | ------ |
| S11 Dynamic Type | Largest accessibility sizes; primary CTAs remain usable | PASS / FAIL |
| S12 VoiceOver smoke | Companion name / bond / pause labeled | PASS / FAIL / SKIP |

## Explicitly NOT proven here

- Outdoor daylight glare on mist backgrounds
- Night street lighting washout
- Real GPS / location integrity
- Battery / thermal during long walks
- True AR outdoor tracking

Those require `OUTDOOR_QA_CHECKLIST.md` + filled receipt.

## Sign-off (sim only)

```yaml
sim_preflight: PASS | FAIL | PARTIAL
sha:
operator:
date:
notes: |
```
