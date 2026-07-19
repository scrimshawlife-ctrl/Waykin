# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 3.0
date: 2026-07-19
status: EXPERIENCE_LOOP_COHESION_COMPLETE
goal: close_path_health_into_session_summary_and_walk_feel
outdoor_qa: DEFERRED_NON_BLOCKING
ar_status: FROZEN_MAINTENANCE_ONLY
```

## Completed waves

| Wave | Status |
| ---- | ------ |
| Design / indoor presentation / AR mid-LOD / USDZ | **Done** |
| **AR-F** freeze + **P/H MVP** | **Done** (#98) |
| **Path/Health v1.1** | **Done** (#99) — phrases, receipts, fake provider, energy hint |

## Wave v3 — Experience Loop Cohesion (this plan)

Path and Health already compute; this wave makes them **feel finished** in the walk loop without navigation chrome, outdoor QA, or AR expansion.

| ID | Work | Acceptance |
| -- | ---- | ---------- |
| **E1** | Human path / cadence copy helpers in core | Pure, privacy-safe strings; no coordinates |
| **E2** | `SessionSummary` path + cadence fields | Optional fields; demo/real populate from path/activity |
| **E3** | Summary UI shows path + cadence lines | Normal UI (not UI-test-only); a11y identifiers |
| **E4** | `ExperienceContext.activityEnergyHint` | Optional 0…1; default 0 preserves demo determinism |
| **E5** | Companion Walk blends energy hint | World energy uses max(speedEnergy, hint) |
| **E6** | Real walk refreshes context energy | After Health refresh, real experience context updates |
| **E7** | Path-aware memory suffix (app) | Physical/demo end may append one short path clause |

### Out of scope

| Track | Work |
| ----- | ---- |
| Outdoor | Device walk QA / outdoor receipt OBSERVED |
| AR | Issue #41; sculpted USDZ / AnimationLibrary |
| Path v2 | Corridor geometry / map product |
| Health v2 | Workouts, background delivery |
| Audio | New cue kinds / production sound redesign |

## Product cores after this wave

| Track | Status |
| ----- | ------ |
| AR | Maintenance-only |
| Path + Health | **Surfaced end-to-end** (session + summary + mild energy bias) |
| Experience tuning | Soft energy only; no event-weight overhaul |

## Related

- [PATHFINDING.md](PATHFINDING.md)
- [HEALTHKIT.md](HEALTHKIT.md)
- [AR_MVP_FREEZE.md](AR_MVP_FREEZE.md)
