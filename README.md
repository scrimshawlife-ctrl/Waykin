# Waykin — Minimum Proof of Concept

> Waykin is not an app that records movement. It is a platform where movement
> changes the behavior of a persistent AI companion, making every real-world
> journey feel like a shared adventure.

This repository is the MPOC build: one persistent companion, GPS movement
sessions, three plug-in experiences (**Companion Walk**, **Orc Pursuit**,
**Future Self**), an AR companion, and a memory system that makes tomorrow's
greeting different because of today's walk.

## Layout

```
Waykin/
├── Package.swift               Swift package: engines + simulator
├── Sources/
│   ├── WaykinCore/             Platform-free engines (no UIKit/ARKit/CoreLocation)
│   │   ├── Models/             Companion, Relationship, Memory, LocationMemory
│   │   ├── Movement/           GeoCoordinate, MovementSessionTracker, MovementSession
│   │   ├── Experiences/        Experience protocol, engine/runner, 3 experiences
│   │   ├── Companion/          CompanionEngine — greetings, bond, place recognition
│   │   ├── Memory/             MemoryEngine + MemoryStore seam
│   │   ├── AI/                 AIProvider abstraction, PromptBuilder, offline voice
│   │   └── Recommendation/     RecommendationEngine (time/weather/history scoring)
│   └── WaykinSim/              waykin-sim: the 2-day demo scenario on macOS
├── Tests/WaykinCoreTests/      20 unit tests incl. the modularity proof
└── App/                        iOS app (SwiftUI · RealityKit · ARKit · SwiftData)
    ├── project.yml             XcodeGen manifest
    └── Waykin/
        ├── Views/              Onboarding, Home, Session, Summary
        ├── AR/                 ARCompanionView (RealityKit follow/idle/celebrate)
        └── Services/           AppState, SwiftData persistence, CoreLocation, audio
```

The dependency rule: **WaykinCore imports only Foundation.** Every engine is
deterministic and testable; the app layer adapts CoreLocation, SwiftData,
RealityKit, and AVFoundation onto core protocols.

```
User → Movement Engine → Experience Engine → Companion Intelligence → Memory Engine → Presentation
```

## Quick start (no device needed)

Requires Swift 5.9+ (any Mac with Xcode 15+).

```bash
swift test          # 20 tests across all five pillars
swift run waykin-sim
```

`waykin-sim` plays the full demonstration scenario: Day 1 onboarding, a
simulated 10-minute **Future Self** walk at Shoreline Park (with a mid-walk
pause and a finishing surge), the session summary, the generated memory —
then Day 2, where Ember greets you with yesterday's memory, recognizes the
park, and recommends today's experiences.

Try the other experiences:

```bash
swift run waykin-sim --experience orc-pursuit
swift run waykin-sim --experience walk-together
```

## Running the iOS app

Requires Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```bash
cd App
xcodegen generate
open Waykin.xcodeproj    # select the Waykin scheme, pick a simulator or device, Run
```

- **On device** (recommended): full ARKit companion + real GPS.
- **On simulator**: AR falls back to a 2D companion; simulate movement with
  *Features ▸ Location ▸ Freeway Drive* or:

  ```bash
  xcrun simctl location booted start --speed=1.6 --interval=2 37.4312,-122.0898 37.4420,-122.0898
  ```

Demo launch arguments (Scheme ▸ Run ▸ Arguments):

| Flag | Effect |
|---|---|
| `--demo-seed` | Skips onboarding: seeds Ember with yesterday's Future Self memory |
| `--demo-open <id>` | Jumps straight to a session screen (`walk-together`, `orc-pursuit`, `future-self`) |
| `--demo-autostart` | Starts the session immediately |

## The five pillars, and where they live

| Pillar | Proof |
|---|---|
| 1. Persistent companion | `CompanionEngine` — greetings evolve with bond level and days elapsed; state persists via SwiftData (`StoredCompanion`) |
| 2. Movement session | `MovementSessionTracker` — haversine distance, rolling pace, stop detection, walk/run auto-detection, GPS-noise rejection |
| 3. Experience engine | `Experience` protocol + `ExperienceEngine` registry; `testNewExperiencePluginNeedsNoEngineChanges` registers a 4th experience without touching any engine |
| 4. AR companion | `ARCompanionView` — RealityKit entity anchored ahead of the camera, eases toward you (follow), bobs by state, spins to celebrate |
| 5. Memory | `MemoryEngine` — every session stores location, duration, distance, experience, bond gain, and one generated memory; next visit → “I remember this place.” |

## Adding a fourth experience

```swift
final class SunsetChaseExperience: Experience {
    let id = "sunset-chase"; let name = "Sunset Chase"
    let summary = "Reach the overlook before the sun dips."
    let difficulty = Difficulty.moderate
    func begin(context: ExperienceContext) -> [ExperienceEvent] { ... }
    func update(_ update: MovementUpdate, context: ExperienceContext) -> [ExperienceEvent] { ... }
    func end(session: MovementSession, context: ExperienceContext) -> ExperienceOutcome { ... }
}

engine.register(id: "sunset-chase", name: "Sunset Chase",
                summary: "...", difficulty: .moderate) { SunsetChaseExperience() }
```

Nothing else changes — the movement engine, runner, recommendation engine,
memory generator, and UI pick it up automatically.

## AI layer

The MPOC runs fully offline: `RuleBasedProvider` gives the companion a short,
memory-aware voice, and `PromptBuilder` assembles the exact system prompt
(activity, location, weather, relationship level, recent memories, active
experience, achievements) that a hosted model receives when you plug a real
provider into `AIProvider`. `waykin-sim` prints that prompt at the end of its run.

## Docs

- [Docs/DEMO.md](Docs/DEMO.md) — the 10-minute Future Self demo script
- [Docs/LIMITATIONS.md](Docs/LIMITATIONS.md) — known limitations
