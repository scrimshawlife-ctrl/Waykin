# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 2.0
date: 2026-07-19
status: PATH_HEALTH_V1_1_COMPLETE
goal: deepen_path_progress_and_health_enrichment_presentation
outdoor_qa: DEFERRED_NON_BLOCKING
ar_status: FROZEN_MAINTENANCE_ONLY
```

## Completed waves (v1.0)

| Wave | Status |
| ---- | ------ |
| Design / indoor presentation / AR mid-LOD / USDZ | **Done** |
| **AR-F** freeze docs + mapping | **Done** |
| **P** pathfinding MVP | **Done** (`PathProgressEngine` + app wiring) |
| **H** HealthKit MVP | **Done** (App adapter + null provider + bands) |

## Wave v1.1 — Path + Health deepen (this plan)

Primary product track after AR freeze. No navigation chrome, no HealthKit in core, Demo Mode never blocked.

| ID | Work | Acceptance |
| -- | ---- | ---------- |
| **P1** | Path relation phrases in session presence | When pursuit inactive and no stronger world event, phrase reflects `PathRelation` |
| **P2** | Path integrity in pressure presentation | Inactive pursuit blends `pathIntegrityPressure` into pressure intensity / a11y |
| **P3** | Privacy-safe path fields on field-test receipts | Summary captures relation, meters, pressure, accept count — **no coordinates** |
| **P4** | Real-walk path integration tests | Accepted samples advance path; rejections strain / off-path |
| **H1** | `FakeHealthMetricsProvider` | Deterministic enrichment for app tests |
| **H2** | Energy hint presentation | Coarse `energyHint` lightly affects presence opacity; never required for walk |
| **H3** | Health refresh on resume | Real walk re-refreshes enrichment at start **and** on resume from pause |
| **H4** | Coarse activity band on receipts | Cadence band + denied flag only (no sample UUIDs / raw medical claims) |

### Out of scope (still deferred)

| Track | Work |
| ----- | ---- |
| Outdoor | Device walk QA / outdoor receipt OBSERVED |
| AR | Issue #41 physical AR; sculpted USDZ / AnimationLibrary |
| Path v2 | Corridor geometry (still no nav chrome) |
| Health v2 | Workouts, background delivery (separate privacy review) |

## Product cores

| Track | Status after v1.1 |
| ----- | ----------------- |
| AR presentation | Maintenance-only |
| Path progress | MVP → **v1.1 presentation + receipts + real-walk tests** |
| Health enrichment | MVP → **v1.1 fake + energy hint + refresh + receipt band** |

## Related

- [AR_MVP_FREEZE.md](AR_MVP_FREEZE.md)
- [REAL_WALK_TO_AR_MAPPING.md](REAL_WALK_TO_AR_MAPPING.md)
- [PATHFINDING.md](PATHFINDING.md)
- [HEALTHKIT.md](HEALTHKIT.md)
