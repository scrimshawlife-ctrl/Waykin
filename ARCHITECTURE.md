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
CompanionWalkExperience
      ├─ WorldState
      ├─ WorldEventGenerator → WorldEvent? (0–1 / tick)
      ├─ CompanionPresentationMatrix → behavior + relative distance
      ├─ AudioExperienceLayer (event cue, else behavior-transition cue)
      └─ ExperienceUpdate commands / semanticAudioCues
      ↓
App orchestration (WaykinAppModel / DemoSessionController)
      ├─ CompanionRuntime
      ├─ PathProgressEngine (+ optional PathAudioCoupling soft cues)
      ├─ AppAudioCuePlayer
      ├─ CanonicalARWorldCommandMapper → ARWorldCommand (when AR attached)
      └─ CompanionPresencePresentation / session UI
      ↓
SessionMemory + Bond
```

## Primary Systems

- Movement Integrity: validates real sample accuracy and timestamps, rejects implausible displacement, stabilizes walking speed, and establishes fresh anchors across lifecycle gaps.
- Movement Engine: owns session transitions, elapsed and active time, distance, speed, route points, simulation, and accepted real walking samples.
- World State: derives serializable session context from local movement signals, Bond, time context, familiarity, energy, and pressure.
- Event Generator: emits zero or one deterministic semantic event per tick using a seeded, weighted, cooldown-aware configuration.
- Companion presentation matrix: single source for behavior + relative distance + AR presentation string mapping (`CompanionPresentationMatrix`).
- Companion Runtime: applies experience commands (and event overlays) into Lira’s small behavior vocabulary.
- Audio Experience Layer: maps world events and companion behavior transitions onto the seven semantic cue kinds (priority + cooldown); path soft cues use the same kinds via `PathAudioCoupling` when event/behavior audio is silent.
- App Audio Adapter: maps cue kinds to bundled produced WAVs, enforces a two-channel playback bound, and owns Apple audio-session lifecycle behavior.
- Path progress: semantic on-path / strained / offPath presentation (not navigation).

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

**Shipped presentation bridge (MVP):** Demo and real Companion Walk emit `ARWorldCommand` batches through `CanonicalARWorldCommandMapper` when an AR handler is attached (`CanonicalARSessionView` full-screen cover). Continuity uses world-plane plant with re-plant / camera-anchor fallback (`ARPlacementResolver`); presentation state `.follow` remains local pose, not continuous walker re-anchor. See `docs/design/REAL_WALK_TO_AR_MAPPING.md` and `docs/design/AR_MVP_FREEZE.md`.

An isolated `WaykinARLab` target remains available for camera/placement engineering. The normal `Waykin` scheme launches `WaykinApp` with production session AR.

The contract remains **presentation-only**. AR capability and tracking state may inform whether the app shows AR, a limited fallback, or no AR, but tracking quality does **not** become an alternate source of gameplay truth (movement, events, Bond, memories). Physical outdoor tracking quality remains evidence-gated (Issue #41 PARTIAL until re-walk PASS).

## AI Director Release-Candidate Boundary

The post-MVP Conversation Director and Pathfinder Director are release-candidate references, not current runtime systems.

```text
WaykinCore canonical state
      ↓ bounded, privacy-reviewed context projection
Provider-neutral AIDirector contract
      ↓
Replaceable provider adapter (Grok candidate)
      ↓ untrusted proposal
Validation / policy / timeout / rate-limit boundary
      ↓
Accepted semantic proposal or deterministic fallback
```

The AI boundary follows these rules:

- `WaykinCore` remains provider-agnostic and owns movement, events, Lira state, pursuit, Bond, memories, rewards, and session outcome.
- Grok is a replaceable adapter candidate, not a hard-coded dependency.
- Every model response is untrusted input and must be schema-validated, sanitized, bounded, and rejectable.
- Provider timeout, outage, refusal, malformed output, or disabled cloud AI must degrade to authored local dialogue, deterministic route behavior, or silence.
- Raw coordinates, unrestricted route history, raw HealthKit samples, and private memory text are excluded unless a separate privacy and architecture decision authorizes them.
- Model output may not directly invoke AR, audio, persistence, rewards, movement, event generation, or state mutation.

For Conversation, the model may propose one bounded Lira utterance plus semantic delivery metadata. It may not create durable personal profiles, write memories, change Bond, or provide navigational or safety instructions.

For Pathfinder, the model may propose route style and rank points of interest supplied by an approved mapping provider. MapKit or another approved routing service remains authoritative for route geometry, legality, reachability, closures, constraints, and return-path feasibility.

See `docs/design/AI_DIRECTOR_RELEASE_CANDIDATES.md` for promotion gates, evidence requirements, and non-goals.

## Retained Compatibility

The repository still contains deprecated proof-of-concept runtime types for Orc Pursuit and Future Self. They are retained only as temporary source/API compatibility while the current product surface, recommendations, Demo Mode, variants, and tests are consolidated around Companion Walk. Future deletion or migration should follow `docs/SOLO_MVP_SCOPE.md`.

## Deferred Seams

**Done on main (do not re-open without a defect):** production WAV cues; companion-first event weight tune; real-walk/demo → AR command bridge; AR MVP freeze scope; path progress v1.1; HealthKit read hardening code-side (#104).

**Still open:**

- Manual physical-device GPS, outdoor audio audibility, HealthKit device lifecycle, and interruption validation (Issue #41 / protocols).
- Outdoor AR re-walk after continuity + audio mitigations (COH receipt on tip SHA).
- Review of local field receipts against manual subjective notes.
- Device-specific calibration of the conservative walking integrity thresholds.
- Optional migration/deletion of old proof-of-concept experience code.
- HealthKit workout writing.
- watchOS target, workout sessions, workout mirroring, WatchConnectivity, heart-rate enrichment, Watch controls, and Watch haptics.
- Provider-neutral AI Director contracts, privacy projection, validation, deterministic fallback, and provider substitution.
- Conversation Director and Pathfinder Director prototypes after promotion.

The architecture deliberately defers backend services, accounts, multiplayer, creator tools, marketplaces, AI implementation beyond the approved release-candidate references, wearable implementation beyond the approved reference seam, and generalized narrative infrastructure.