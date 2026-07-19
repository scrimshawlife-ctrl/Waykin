# HealthKit Enrichment

```yaml
document_id: WAYKIN-HEALTHKIT-001
version: 0.2
status: IMPLEMENTED_V1_1
required_for_demo: false
```

## Scope

Optional read of **steps** (last hour) and **walking+running distance** (today) to produce `ActivityEnrichment` semantic bands.

## Boundaries

| Layer | Allowed |
| ----- | ------- |
| App | `HealthKitMetricsProvider`, `NullHealthMetricsProvider`, `FakeHealthMetricsProvider` |
| WaykinCore | `ActivityEnrichment` / `StepCadenceBand` only — **no HealthKit import** |

## Authorization

- Demo Mode never requests HealthKit
- UI tests use `NullHealthMetricsProvider`
- App tests may inject `FakeHealthMetricsProvider`
- Real walk may call `requestAuthorizationIfNeeded()` non-blocking at **start** and **resume**
- Deny → `authorizationDenied: true`, empty bands; walk continues

## Cadence bands (steps / last hour)

| Steps | Band |
| ----- | ---- |
| unknown / missing | unknown |
| &lt; 200 | low |
| 200–1999 | moderate |
| ≥ 2000 | high |

## Presentation

- `energyHint` (0…0.2) lightly lifts presence opacity and can color path-on phrases
- Never required for Demo Mode or walk completion

## Privacy

No HealthKit sample UUIDs, device names, or medical diagnoses. Enrichment is coarse. Field-test receipts store **cadence band + denied flag only** (no step totals).

## Tests

- `ActivityEnrichmentTests` (core)
- `PathProgressIntegrationTests` health null/denied + fake provider + cadence helper
- Isolation: HealthKit not in WaykinCore sources
