# Outdoor QA Receipt (PENDING device walk)

```yaml
document_id: WAYKIN-OUTDOOR-QA-RECEIPT
version: 0.1
template: false
status: PENDING_DEVICE
evidence_class: NOT_COMPUTABLE
prepared_utc: 2026-07-25T19:45:35Z
git_sha: 3cc8ac21a3bbe286486c551b04630b5531ec928c
git_short: 3cc8ac2
branch: main
```

> Scaffolded by `scripts/outdoor_qa_prep.sh`. Rows below are **blank** until a human operator records **OBSERVED** results on a named device. Do not mark PASS without the walk.

## Meta

| Field | Value |
| ----- | ----- |
| Date (local) | |
| Operator | |
| Build SHA | `3cc8ac21a3bbe286486c551b04630b5531ec928c` |
| Short SHA | `3cc8ac2` |
| App version / config | Debug / Release |
| Device model | |
| iOS version | |
| Location context | Outdoor sun / shade / night street / other: |
| Weather / glare notes | |
| Companion name shown | Lira |
| Modes exercised | Demo / Real walk / AR Lab |

## Pre-device gate

| Gate | Result |
| ---- | ------ |
| `make validate` | (run at prep) |
| Sim preflight (optional) | PASS / FAIL / SKIP |

## Pass A — Day (UI)

| ID | Result | Notes |
| -- | ------ | ----- |
| D1 | | |
| D2 | | |
| D3 | | |
| D4 | | |
| D5 | | |
| D6 | | |
| D7 | | |
| D8 | | |

## Pass B — Night (UI)

| ID | Result | Notes |
| -- | ------ | ----- |
| N1 | | |
| N2 | | |
| N3 | | |
| N4 | | |
| N5 | | |
| N6 | | |

## Pass C — Reduced motion

| ID | Result | Notes |
| -- | ------ | ----- |
| R1 | | |
| R2 | | |
| R3 | | |

## Pass D — Hunt / pressure tone

| ID | Result | Notes |
| -- | ------ | ----- |
| H1 | | |
| H2 | | |
| H3 | | |

## Pass E — Physical AR (Issue #41)

| ID | Result | Notes |
| -- | ------ | ----- |
| E1 Outdoor brightness readability | | |
| E2 States distinguishable without color alone | | |
| E3 Horizontal outdoor placement | | |
| E4 Replace → single Lira | | |
| E5 Clear removes entities | | |
| E6 Background/reopen no resurrection | | |
| E7 Celebrate → Idle | | |
| E8 Thermal / battery notes | | |
| E9 Tracking / lighting / surface notes | | |

## Overall

```yaml
day_pass: true | false | partial | not_run
night_pass: true | false | partial | not_run
reduced_motion_pass: true | false | partial | not_run
pressure_tone_pass: true | false | partial | not_run
ar_physical_pass: true | false | partial | not_run
evidence_class: NOT_COMPUTABLE
blockers: |
  Device walk not yet executed at prep time.
follow_ups: |
  Complete OUTDOOR_SESSION_PACKET.md on device; open defect issues for FAIL rows.
signed_by:
signed_at:
```
