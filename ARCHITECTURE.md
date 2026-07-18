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

`FieldTestReceiptBuilder` observes existing session, movement-integrity, event, audio, lifecycle, permission, and persistence seams. It aggregates high-frequency accepted samples and records a sparse semantic timeline without coordinates, route geometry, provider error strings, or personal memory text. The observer does not select events, request cues, calculate movement, change Bond, or write normal memories.

`FileFieldTestReceiptStore` writes atomically to the app's Application Support directory, retains at most 20 receipts, and never transfers them over a network. Receipt storage is separate from SwiftData session-memory persistence.

## Presentation Boundaries

SwiftUI and MapKit consume state from the core. They do not own gameplay rules.

`RealLocationProvider` is a foreground Core Location adapter. It converts `CLLocation` values into raw `LocationSample` values and reports authorization and signal state. The core `MovementEngine` is the sole owner of movement acceptance and metrics. Only an accepted `MovementSnapshot` can update Companion Walk state or semantic audio.

Production-capable playback remains behind the semantic `AudioCue` boundary. The core knows no filenames; `AppAudioCuePlayer` uses `AVAudioPlayer` and a centralized app-target catalog to resolve local assets or fail to silence safely.

### AR Presentation Contract

`WaykinCore` defines platform-neutral AR presentation values under `Sources/WaykinCore/Presentation/`. `SpatialIntent` describes the semantic placement role of a companion, discovery, threat, or environmental object without importing ARKit, RealityKit, or renderer-specific coordinates.

`ARWorldCommand` carries immutable spawn, update, removal, and session-clear intents across the core-to-app boundary. The app-target AR adapter owns tracking, anchors, entity construction, animation playback, occlusion, and graceful capability fallback. It may realize or defer commands, but it must not mutate movement, world, event, companion, pursuit, Bond, or persistence state.

```text
WaykinCore semantic state
      ↓
SpatialIntent / ARWorldCommand
      ↓
App-target AR adapter
      ↓
ARKit + RealityKit presentation
```

AR-1 adds an isolated physical-device shell with capability monitoring, session lifecycle handling, horizontal raycasts, and a bounded entity registry. Camera tracking, marker placement, surface detection, replacement, and background recovery have been observed on an iPhone 17 Pro; placement and detection calibration remain open. The normal `Waykin` scheme launches `WaykinApp`, while the dedicated `WaykinARLab` scheme launches the isolated AR validation surface.

AR-2 adds procedural Lira embodiment, direct presentation-state controls, and privacy-filtered diagnostics. AR-3 adapts the existing deterministic demo arc and CompanionRuntime state into AR commands without changing core scheduling or progression. Lira embodiment, the deterministic indoor arc, and repaired background/foreground recovery are validated indoors on the tested device. Outdoor-device and measured performance gates remain open; M4 locomotion, orientation, eye contact, and contextual behavior remain separate work.

The contract is intentionally presentation-only. AR capability and tracking state may inform whether the app shows AR, a limited fallback, or no AR, but tracking quality does not become an alternate source of gameplay truth.

## Retained Compatibility

The repository still contains deprecated proof-of-concept runtime types for Orc Pursuit and Future Self. They are retained only as temporary source/API compatibility while the current product surface, recommendations, Demo Mode, variants, and tests are consolidated around Companion Walk. Future deletion or migration should follow `docs/SOLO_MVP_SCOPE.md`.

## Deferred Seams

- Manual physical-device GPS and audio validation.
- Review of local field receipts against manual subjective notes.
- Device-specific calibration of the conservative walking integrity thresholds.
- Replacement of deterministic engineering tones with production sound design.
- Richer tuning of event weights.
- Optional migration of old proof-of-concept experience code after the walking loop is proven.
- Camera-relative companion locomotion, target-facing orientation, and contextual animation.
- Physical-device calibration of AR surface detection and placement, tracking-loss and interruption recovery, and battery impact.

The architecture deliberately defers backend services, accounts, multiplayer, creator tools, marketplaces, generative AI, wearables, and generalized narrative infrastructure.
