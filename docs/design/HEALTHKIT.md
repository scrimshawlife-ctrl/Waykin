# HealthKit Enrichment

```yaml
document_id: WAYKIN-HEALTHKIT-001
version: 0.1
status: IMPLEMENTED_MVP
required_for_demo: false
```

## Scope

Optional read of **steps** (last hour) and **walking+running distance** (today) to produce `ActivityEnrichment` semantic bands.

## Boundaries

| Layer | Allowed |
| ----- | ------- |
| App | `HealthKitMetricsProvider`, `NullHealthMetricsProvider` |
| WaykinCore | `ActivityEnrichment` / `StepCadenceBand` only — **no HealthKit import** |

## Authorization

- Demo Mode never requests HealthKit
- UI tests use `NullHealthMetricsProvider`
- Real walk may call `requestAuthorizationIfNeeded()` non-blocking
- Deny → `authorizationDenied: true`, empty bands; walk continues

## Cadence bands (steps / last hour)

| Steps | Band |
| ----- | ---- |
| unknown / missing | unknown |
| &lt; 200 | low |
| 200–1999 | moderate |
| ≥ 2000 | high |

## Privacy

No HealthKit sample UUIDs, device names, or medical diagnoses. Enrichment is coarse.

## Tests

- `ActivityEnrichmentTests` (core)
- `PathProgressIntegrationTests` health null/denied + cadence helper
- Isolation: HealthKit not in WaykinCore sources
