# Simulator Checklist Automation

```yaml
document_id: WAYKIN-SIM-CHECKLIST-AUTO-001
version: 0.1
status: ACTIVE
evidence_class: OBSERVED_IN_SIMULATOR_ONLY
outdoor_qa: NOT_COMPUTABLE
```

Maps manual preflight items to automated coverage. Visual night≠invert judgment remains partial (token hex + theme resolution asserted; pixel look still human).

| Manual ID | Coverage | Evidence |
| --------- | -------- | -------- |
| S1 Day theme | Settings → Day force | `testSettingsAppearanceForce` |
| S2 Night theme | Settings → Night force | `testSettingsAppearanceForce` |
| S3 Night ≠ invert | Token hex + theme resolve | `AppearanceAndARSkinTests`, `WKTokensTests` |
| S4 Home Lira + Form | Home stage + Dawn/Veil/Rupture | `testHomeLiraStageAndFormSkins` |
| S5 Begin Walk demo | Smoke | `testBeginWalkCompletesAndCreatesMemory` |
| S6 Pause / End | Smoke | `testPauseResumeEndWorks` |
| S7 Settings force | Auto/Day/Night round-trip | `testSettingsAppearanceForce` |
| S8 AR form label | Form tracks selected skin | `testARCompanionFormLabelTracksSkin` |
| A11y largest text | Presence + CTAs | `testActiveSessionAccessibilityAtLargestTextSize` |
| Still matrix 7×3 | Assets loadable | `testStillCatalogCoversFullPoseSkinMatrix` |

## Reset contract

`-WAYKIN_RESET_STATE YES` clears demo persistence **and** UserDefaults for:

- `LiraSkin.storageKey`
- `AppearancePreference.storageKey`

so UI tests start at Dawn + Auto appearance.

## Commands

```bash
make validate
make validate-simulator
./scripts/sim_walk_preflight.sh
```
