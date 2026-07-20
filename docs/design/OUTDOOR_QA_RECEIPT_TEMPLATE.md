# Outdoor QA Receipt Template

```yaml
document_id: WAYKIN-OUTDOOR-QA-RECEIPT
version: 0.1
template: true
# Copy this file to docs/design/receipts/OUTDOOR_QA_RECEIPT_<YYYYMMDD>_<device>.md
# Fill on device. Do not mark OBSERVED without completing the walk protocol.
```

## Meta

| Field | Value |
| ----- | ----- |
| Date (local) | |
| Operator | |
| Build SHA (`git rev-parse --short HEAD`) | |
| App version / config | Debug / Release |
| Device model | |
| iOS version | |
| Location context | Outdoor sun / shade / night street / other: |
| Weather / glare notes | |
| Companion name shown | Lira |
| Modes exercised | Demo / Real walk |

## Evidence class rules

| Class | When to use |
| ----- | ----------- |
| **OBSERVED** | Directly seen on physical device in stated conditions |
| **PARTIAL** | Some passes done; gaps listed |
| **NOT_COMPUTABLE** | Not run or simulator-only |

## Simulator preflight

Complete `SIMULATOR_PREFLIGHT.md` first (optional but recommended).

| Preflight | Result |
| --------- | ------ |
| Sim day/night switch | PASS / FAIL / SKIP |
| Sim reduced motion | PASS / FAIL / SKIP |
| Sim pressure icons + labels | PASS / FAIL / SKIP |

## Device passes (from OUTDOOR_QA_CHECKLIST)

### Pass A — Day

| ID | Result | Notes |
| -- | ------ | ----- |
| D1 | PASS / FAIL / NA | |
| D2 | PASS / FAIL / NA | |
| D3 | PASS / FAIL / NA | |
| D4 | PASS / FAIL / NA | |
| D5 | PASS / FAIL / NA | |
| D6 | PASS / FAIL / NA | |
| D7 | PASS / FAIL / NA | |
| D8 | PASS / FAIL / NA | |

### Pass B — Night

| ID | Result | Notes |
| -- | ------ | ----- |
| N1 | PASS / FAIL / NA | |
| N2 | PASS / FAIL / NA | |
| N3 | PASS / FAIL / NA | |
| N4 | PASS / FAIL / NA | |
| N5 | PASS / FAIL / NA | |
| N6 | PASS / FAIL / NA | |

### Pass C — Reduced motion

| ID | Result | Notes |
| -- | ------ | ----- |
| R1 | PASS / FAIL / NA | |
| R2 | PASS / FAIL / NA | |
| R3 | PASS / FAIL / NA | |

### Pass COH — Multi-surface coherence (#143)

Score the **same walk moment** across surfaces. PASS only with OBSERVED on named SHA.

| Moment (note wall-clock or event) | Heard cue? (basename/kind) | UI phrase | Still pose / graphicsPath | AR state + Continuity note | Agree? |
| --------------------------------- | -------------------------- | --------- | ------------------------- | -------------------------- | ------ |
| quietInterval / rest | | | | | Y / N / partial |
| lead / companionMovesAhead | | | | | Y / N / partial |
| bondMoment | | | | | Y / N / partial |
| path strained (GPS integrity) | | | | | Y / N / partial |
| path offPath | | | | | Y / N / partial |
| pursuit begins / intensifies | | | | | Y / N / partial |
| AR walk 10–15 m continuity | n/a | n/a | n/a | Continuity: | Y / N / partial |

Evidence class for COH overall: OBSERVED / PARTIAL / NOT_COMPUTABLE  
Notes (disagreements):

### Pass D — Hunt / pressure tone

| ID | Result | Notes |
| -- | ------ | ----- |
| H1 | PASS / FAIL / NA | |
| H2 | PASS / FAIL / NA | |
| H3 | PASS / FAIL / NA | |

## Photos / attachments (optional)

| Ref | Description | Path or issue comment |
| --- | ----------- | --------------------- |
| P1 | Home day | |
| P2 | Active guide day | |
| P3 | Active pressure night | |

Do not commit private location EXIF. Prefer cropped UI-only captures.

## Overall

```yaml
day_pass: true | false | partial
night_pass: true | false | partial
reduced_motion_pass: true | false | partial
pressure_tone_pass: true | false | partial
evidence_class: OBSERVED | PARTIAL | NOT_COMPUTABLE
blockers: |
  ...
follow_ups: |
  ...
signed_by:
signed_at:
```

## After OBSERVED overall pass

1. Store filled receipt under `docs/design/receipts/`
2. Update `ECHO_THEME_IMPORT.md` / `APPICON_LIRA_ECHO_IMPORT.md` `outdoor_qa` field
3. Optionally open eng note for HO-001 contrast validated
4. Product owner only: consider APPROVED_FOR_EXPORT for visual tokens already integrated
