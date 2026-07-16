# Waykin MPOC Architecture

## System Flow

```text
WorldContext
    ↓
MovementEngine
    ↓
ExperienceEngine
    ↓
CompanionRuntime
    ↓
Memory + Progression
    ↓
PresentationAdapters
```

## Modules

```text
WaykinApp
├── AppShell
├── Domain
├── MovementEngine
├── ExperienceEngine
├── Experiences
│   ├── CompanionWalk
│   ├── OrcPursuit
│   └── FutureSelf
├── CompanionRuntime
├── RecommendationEngine
├── MemoryEngine
├── Persistence
├── Presentation
│   ├── Map
│   ├── Audio
│   └── AR
├── DemoMode
└── Tests
```

## Core Contracts

### Movement Providers

- `LocationProviding`
- `MotionProviding`
- `ClockProviding`
- `MovementSessionManaging`

Each real provider must have a deterministic test/simulation counterpart.

### Experience Contract

Each experience receives immutable movement/context snapshots and returns an update containing:

- Experience state
- Companion commands
- Audio cues
- Narrative events
- Reward events
- Safety events

Experiences must not mutate global state or invoke presentation implementations directly.

### Companion Commands

Presentation-neutral behavior should include:

- Idle
- Follow
- Lead
- Pace
- Pursue
- Flee
- Observe
- Rest
- Celebrate

### Persistence

Persist locally:

- User profile
- Companion and bond state
- Movement sessions and route summaries
- Experience outcomes
- Session memories
- Prior Future Self pace
- Recommendation history and preferences

## Dependency Direction

UI and platform adapters depend on domain protocols. Domain and experience rules do not depend on SwiftUI, MapKit, RealityKit, Core Location, audio playback, or storage implementations.

## Safety Boundary

Deterministic application logic owns session lifecycle, attention state, reward bounds, pause handling, and interaction suppression. Generative AI must never control these paths.
