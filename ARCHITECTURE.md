# Waykin Architecture

Waykin is currently a solo-developer MVP vertical slice, not a platform. The architecture is bounded around one walking loop and five primary runtime systems.

## Runtime Flow

```text
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
SessionMemory + Bond
```

## Primary Systems

- Movement Engine: starts, pauses, resumes, ends, simulates, and ingests real walking sessions.
- World State: derives serializable session context from local movement signals, Bond, time context, familiarity, energy, and pressure.
- Event Generator: emits zero or one deterministic semantic event per tick using a seeded, weighted, cooldown-aware configuration.
- Companion Runtime: maps events and commands into a small behavior vocabulary for Lira.
- Audio Experience Layer: maps semantic events to semantic audio cues with priority and cooldown handling.

Persistence supports Bond and concise memories. It is not a generalized backend or content platform.

## Presentation Boundaries

SwiftUI and MapKit consume state from the core. They do not own gameplay rules.

Production audio playback is intentionally behind the semantic `AudioCue` boundary. Package tests do not require bundled audio assets.

## Retained Compatibility

The repository still contains earlier proof-of-concept types for Orc Pursuit and Future Self. They are retained to avoid risky churn, but the current product surface and recommendation path are consolidated around Companion Walk as the MVP experience. Future deletion or migration should follow `docs/SOLO_MVP_SCOPE.md`.

## Deferred Seams

- Production audio asset mapping.
- Manual physical-device GPS and audio validation.
- Richer tuning of event weights.
- Optional migration of old proof-of-concept experience code after the walking loop is proven.

The architecture deliberately defers backend services, accounts, multiplayer, AR gameplay, creator tools, marketplaces, generative AI, wearables, and generalized narrative infrastructure.
