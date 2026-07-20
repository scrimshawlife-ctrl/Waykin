# Waykin Architecture

Waykin is currently a solo-developer MVP vertical slice, not a platform. The architecture is bounded around one walking loop and five primary runtime systems.

## Runtime Flow

```text
Core Location sample / deterministic Demo tick
      ↓
MovementIntegrityProcessor (real samples only)
      ↓
MovementEngine
      ↓
MovementSnapshot
      ↓
WorldState
      ↓
WorldEventGenerator
      ↓
WorldEvent
      ↓
CompanionRuntime / PursuitState
      ↓
AudioCue
      ↓
AppAudioCuePlayer
      ↓
Local bundled audio asset or safe silence
      ↓
SessionMemory + Bond
```

## Primary Systems

- Movement Integrity: validates real sample accuracy and timestamps, rejects implausible displacement, stabilizes walking speed, and establishes fresh anchors across lifecycle gaps.
- Movement Engine: owns session transitions, elapsed and active time, distance, speed, route points, simulation, and accepted real walking samples.
- World State: derives serializable session context from local movement signals, Bond, time context, familiarity, energy, and pressure.
- Event Generator: emits zero or one deterministic semantic event per tick using a seeded, weighted, cooldown-aware configuration.
- Companion Runtime: maps events and commands into a small behavior vocabulary for Lira.
- Audio Experience Layer: maps semantic events to semantic audio cues with priority and cooldown handling.
- App Audio Adapter: maps the seven canonical cue kinds to bundled local assets, enforces a two-channel playback bound, and owns Apple audio-session lifecycle behavior.

Persistence supports Bond and concise memories. It is not a generalized backend or content platform.

## Local Field Receipt

```text
Existing runtime signals
      ↓
Local receipt observer
      ↓
Privacy-filtered JSON receipt
```

`FieldTestReceiptBuilder` observes existing session, movement-integrity, event, audio, lifecycle, permission, persistence, path, and coarse activity-enrichment seams. It records no coordinates, route geometry, provider error strings, personal memory text, raw health samples, sample identifiers, or device names. The observer does not select events, request cues, calculate movement, change Bond, or write normal memories.

`FileFieldTestReceiptStore` writes atomically to the app's Application Support directory, retains at most 20 receipts, and never transfers them over a network. Receipt storage is separate from SwiftData session-memory persistence.

## Presentation Boundaries

SwiftUI and MapKit consume state from the core. They do not own gameplay rules.

`RealLocationProvider` is a foreground Core Location adapter. It converts `CLLocation` values into raw `LocationSample` values and reports authorization and signal state. The core `MovementEngine` is the sole owner of movement acceptance and metrics. Only an accepted `MovementSnapshot` can update Companion Walk state or semantic audio.

Production-capable playback remains behind the semantic `AudioCue` boundary. The core knows no filenames; `AppAudioCuePlayer` uses `AVAudioPlayer` and a centralized app-target catalog to resolve local assets or fail to silence safely.

## HealthKit Boundary

`HealthKitMetricsProvider` is an optional app-layer adapter. It maps HealthKit reads into platform-neutral `ActivityEnrichment`; `WaykinCore` never imports HealthKit or treats HealthKit samples as canonical movement truth.

Current HealthKit enrichment is soft context only. It may affect presentation, a bounded experience-energy hint, summary text, and privacy-filtered evidence. It must not directly select events, change movement acceptance, calculate Bond, generate memories, or determine whether a walk succeeds.

Before expansion, the adapter must distinguish request completion, metric availability, no data, query failure, and unavailable service without claiming definitive read authorization that HealthKit cannot expose. Refresh work must be serialized, bounded, cancellable, and independent of Demo Mode.

## Apple Watch Reference Boundary

Apple Watch is not currently implemented. When promoted, it is an optional workout-lifecycle, sensor, haptic, and minimal-control surface.

```text
Apple Watch platform adapters
      ↓
Platform-neutral wearable snapshots and commands
      ↓
iPhone Waykin app and WaykinCore
      ↓
Canonical movement / events / Lira / pursuit / audio / Bond / memory
```

The Watch may own `HKWorkoutSession`, live workout collection, minimal Start/Pause/Resume/End controls, haptics, and temporary local recovery. It may not own movement-integrity thresholds, event generation, Lira behavior authority, pursuit, Bond, memories, canonical outcome, or AR state.

HealthKit workout mirroring should carry workout lifecycle and live workout metrics. WatchConnectivity should carry only non-authoritative semantic state and acknowledgements. Every cross-device message requires a session identifier and monotonically increasing revision.

Shared wearable contracts must remain free of HealthKit, WatchKit, WatchConnectivity, SwiftUI, and platform object types. Raw heart-rate or effort values must not directly select events or increase coercive pursuit pressure.

See `docs/design/HEALTHKIT.md` for the implementation and promotion sequence.

### AR Presentation Contract

`WaykinCore` defines platform-neutral AR presentation values under `Sources/WaykinCore/Presentation/`. `SpatialIntent` describes the semantic placement role of a companion, discovery, threat, or environmental object without importing ARKit, RealityKit, or renderer-specific coordinates.

`ARWorldCommand` carries immutable spawn, update, removal, and session-clear intents across the core-to-app boundary. The app-target AR adapter owns tracking, anchors, entity construction, animation playback, occlusion, diagnostics, and graceful capability fallback. It may realize or defer commands, but it must not mutate movement, world, event, companion, pursuit, Bond, or persistence state.

```text
WaykinCore semantic state
      ↓
SpatialIntent / ARWorldCommand
      ↓
App-target AR adapter
      ↓
ARKit + RealityKit presentation
```

The reconstructed AR baseline adds an isolated `WaykinARLab` target with camera authorization, capability monitoring, session lifecycle handling, horizontal raycast placement, bounded entity registration, procedural Lira presentation, deterministic presentation states, and privacy-filtered diagnostics. The normal `Waykin` scheme continues to launch `WaykinApp`; the AR Lab is a separate engineering surface.

The contract remains presentation-only. AR capability and tracking state may inform whether the app shows AR, a limited fallback, or no AR, but tracking quality does not become an alternate source of gameplay truth. Physical walking and the production Companion Walk loop are not connected to AR in this baseline.

## Retained Compatibility

The repository still contains deprecated proof-of-concept runtime types for Orc Pursuit and Future Self. They are retained only as temporary source/API compatibility while the current product surface, recommendations, Demo Mode, variants, and tests are consolidated around Companion Walk. Future deletion or migration should follow `docs/SOLO_MVP_SCOPE.md`.

## Deferred Seams

- Manual physical-device GPS, audio, HealthKit, and interruption validation.
- Review of local field receipts against manual subjective notes.
- Device-specific calibration of the conservative walking integrity thresholds.
- Replacement of deterministic engineering tones with production sound design.
- Richer tuning of event weights.
- Optional migration of old proof-of-concept experience code after the walking loop is proven.
- Connection of AR presentation commands to Lira, movement, events, and pursuit.
- Physical-device validation of AR placement, tracking loss, interruption recovery, and battery impact.
- HealthKit workout writing.
- watchOS target, workout sessions, workout mirroring, WatchConnectivity, heart-rate enrichment, Watch controls, and Watch haptics.

The architecture deliberately defers backend services, accounts, multiplayer, creator tools, marketplaces, generative AI, wearable implementation beyond the approved reference seam, and generalized narrative infrastructure.