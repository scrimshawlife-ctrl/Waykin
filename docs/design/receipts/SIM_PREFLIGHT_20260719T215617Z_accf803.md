# Simulator Preflight Receipt

```yaml
document_id: WAYKIN-SIM-PREFLIGHT-RECEIPT
date_utc: 2026-07-19T21:56:17Z
git_sha: accf803dd60ac550337500972e20ab9d642ef0da
git_short: accf803
evidence_class: OBSERVED_IN_SIMULATOR_ONLY
outdoor_qa: NOT_COMPUTABLE
```

## Automated checks

| Check | Result |
| ----- | ------ |
| make validate | PASS |
| swift package tests (60) | PASS |
| Demo session tests exercised | PASS |
| WaykinUITests (9) | PASS |
| Accessibility largest text | PASS (after pose value expectation fix) |

## Manual sim checklist (operator)

| ID | Check | Result |
| -- | ----- | ------ |
| S1 | Day appearance | |
| S2 | Night appearance | |
| S3 | Night not invert of day | |
| S4 | Home Lira + Form skins | |
| S5 | Begin Walk demo completes | PASS (UI test) |
| S6 | Pause / End calm | PASS (UI test) |
| S7 | Settings appearance force | |
| S8 | AR Companion form label | |

## Notes

- Does **not** prove outdoor glare, GPS integrity, or night street readability.
- Fixed UI test: presence accessibilityValue is pose description (opening → "Lira is forming presence").
- Device walks use OUTDOOR_QA_RECEIPT_TEMPLATE.md.
