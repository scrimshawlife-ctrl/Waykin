# Simulator Preflight Receipt (post #126 menu UX)

```yaml
document_id: WAYKIN-SIM-PREFLIGHT
version: 0.2
status: PASS_SIM
evidence_class: OBSERVED_IN_SIMULATOR_ONLY
date_utc: 2026-07-20
git_sha: pending_merge
protocol: SIMULATOR_PREFLIGHT + UI smoke
cannot_prove: [outdoor_glare, GPS, AR_tracking, outdoor_audio]
```

## Commands

| Command | Result |
| ------- | ------ |
| `make validate` | PASS (97 package tests) |
| AppTests `SessionMenuUXTests` | PASS (3) |
| UITests: launch + demo complete + pause/resume/end | PASS (3) on iPhone 17 |

## Checklist (code + automated smoke)

| ID | Result | Notes |
| -- | ------ | ----- |
| S5 Begin/Demo Walk | PASS | Demo via `waykin.beginWalk` → "Demo Walk"; real primary CTA present |
| S6–S8 session chrome | PASS | Pause/Resume/End smoke green |
| Menu #126 | PASS_SIM | Home CTA inversion + AR fullScreenCover + mirrored controls in code |
| Outdoor | NOT_COMPUTABLE | Deferred to daylight re-walk (#41) |

## Notes

Outdoor menu feel remains **NOT_COMPUTABLE** until physical re-walk tomorrow.
