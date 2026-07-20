# HealthKit and Apple Watch Integration

```yaml
document_id: WAYKIN-HEALTHKIT-001
version: 1.0
status: IMPLEMENTED_V1_HARDENED_WITH_WATCH_REFERENCE
authority: REFERENCE
required_for_demo: false
```

## Current Implemented Scope

Waykin optionally reads **steps from the previous hour** and **walking/running distance from the current day** to produce platform-neutral `ActivityEnrichment` values.

| Layer | Allowed |
|---|---|
| App | `HealthKitMetricsProvider`, `NullHealthMetricsProvider`, `FakeHealthMetricsProvider` |
| WaykinCore | `ActivityEnrichment` and coarse activity bands only; no HealthKit import |

Demo Mode never requests HealthKit. A real walk may request authorization at start and resume. Missing, unavailable, or unreadable data must not block the walk.

## Current Semantic Use

- `energyHint` lightly affects presence and experience energy.
- Session summary may show a coarse activity line without exposing step totals.
- Field-test receipts store only a coarse activity band and denial flag.
- HealthKit never becomes movement truth, event authority, Bond authority, or a completion requirement.

## Current Limits

The repository currently has no:

- watchOS target.
- `HKWorkoutSession` or `HKLiveWorkoutBuilder`.
- Workout-session mirroring.
- WatchConnectivity session.
- Live heart-rate stream.
- HealthKit workout writer.
- Watch controls, haptics, or summary surface.

An Apple Watch may indirectly contribute samples to the HealthKit store, but that is not a Waykin Watch integration.

## Required HealthKit Hardening

Before Apple Watch implementation is promoted:

1. ~~Replace the misleading definitive read-authorization state with request-completion and per-metric availability states.~~ **Done (#104)** — `requestCompleted` + per-metric `ActivityMetricAvailability`.
2. ~~Fix the start-time race where enrichment may complete before `realExperienceContext` exists.~~ **Done (#104)**.
3. ~~Distinguish query failure, no data, unavailable service, and unreadable data.~~ **Done (#104)** — internal only; receipts still band + denied flag.
4. ~~Rename or clarify the current one-hour step-volume band; it is not live cadence.~~ **Done (#104)** — documented as recent-hour step volume.
5. ~~Add bounded periodic refresh during active real walks, with cancellation on pause or end and one outstanding query maximum.~~ **Done (#104)** — 120s interval, generation cancel, single in-flight query.
6. ~~Give daily walking distance a bounded semantic purpose or remove the unnecessary read permission.~~ **Done (#104)** — soft energy fallback when step volume unknown.
7. Add direct-device evidence for authorization, denial, empty samples, refresh, and lifecycle behavior. **Still NOT_COMPUTABLE** without a named-device protocol.

## Apple Watch Authority Contract

The iPhone remains the canonical gameplay authority.

```text
Apple Watch adapters
  workout lifecycle / sensors / haptics / minimal controls
                    ↓
Platform-neutral wearable contracts
                    ↓
iPhone Waykin app
  MovementEngine / WorldState / events / Lira / pursuit / audio
                    ↓
Bond / memory / summary / AR
```

Apple Watch may own workout collection, minimal Start/Pause/Resume/End controls, bounded haptic rendering, and local recovery while disconnected. It must not own movement acceptance, event selection, Lira behavior, pursuit state, Bond, memory generation, canonical outcome, or AR state.

Shared wearable contracts must not import HealthKit, WatchKit, WatchConnectivity, SwiftUI, or platform object types. Every cross-device message must contain a session identifier and monotonic revision.

Raw heart-rate or effort values must not directly select events or increase coercive pursuit pressure. They may only provide bounded context, presentation intensity, optional audio-density reduction, or summary information.

## Transport Responsibilities

Use HealthKit workout mirroring for workout lifecycle, live workout metrics, reconnection, and supported background recovery.

Use WatchConnectivity only for non-authoritative semantic state such as:

- Latest Lira state.
- Pursuit band.
- Immediate control acknowledgements.
- Completed summary delivery.

Do not transfer route geometry, personal memory text, or diagnostic receipts to Watch.

## Minimal Watch Product Surface

1. **Ready** — Lira status and Start Walk.
2. **Active** — elapsed time, distance, effort or heart-rate band, Lira state, Pause, and End.
3. **Summary** — duration, distance, Bond delta, one closing phrase, and Done.

The first Watch release excludes maps, AR, memory browsing, detailed health charts, complications, skin management, independent event generation, and independent Bond calculation.

## Promotion Sequence

### Phase 0 — HealthKit V1 hardening

Correct authorization semantics, enrichment ordering, query provenance, and refresh lifecycle while preserving Demo Mode isolation.

### Phase 1 — Optional workout writing

Add explicit write authorization and an app-layer `WorkoutWriting` protocol. Save completed Waykin walks with duplicate protection. Write failure must never block Waykin completion.

### Phase 2 — Minimal watchOS target

Add a Watch app, workout controller, platform-neutral wearable contracts, outdoor walking workout, and the three-screen UI.

### Phase 3 — Workout mirroring

Install the iPhone mirroring handler during app initialization, reconcile repeated callbacks idempotently, and preserve iPhone gameplay authority.

### Phase 4 — Semantic Watch presentation

Send bounded Lira, pursuit, Bond, phrase, lifecycle, and haptic commands with cooldowns.

### Phase 5 — Paired-device validation

Validate start, pause, resume, and end from either device; phone lock/background behavior; temporary disconnection and reconnection; duplicate delivery; permission denial; missing heart-rate data; crash recovery; workout save/discard; and battery, thermal, audio, and haptic behavior.

## Privacy and Safety

Health data remains optional and local unless separately approved. No diagnoses, medical claims, raw sample identifiers, device names, or detailed health histories belong in memories or field-test receipts. Missing or stale wearable data degrades to `unknown` without blocking the walk. Waykin is not safety equipment or medical guidance.

## Promotion Gate

Apple Watch implementation requires an accepted GitHub issue defining user outcome, allowed and frozen systems, target and entitlement changes, data contracts, privacy and safety constraints, tests, paired-device evidence, and rollback path. Until then, Apple Watch remains an approved architectural reference rather than an implementation claim.
