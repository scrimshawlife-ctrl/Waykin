<p align="center">
  <img src="docs/assets/hero/waykin-hero-banner.png" alt="Waykin concept banner showing a traveler and luminous companion on a trail at dawn" width="100%">
</p>

<h1 align="center">Waykin</h1>

<p align="center">
  <strong>Movement becomes adventure.</strong>
</p>

<p align="center">
  A movement-driven experience platform where companions, rivals, and pursuers react to how you move through the real world.
</p>

> **Concept visual:** The hero artwork illustrates the product direction and is not current application footage.

## Quick Start

```bash
git clone https://github.com/scrimshawlife-ctrl/Waykin.git
cd Waykin
make generate
make build
make test
make validate
```

### Simulator Validation

```bash
make validate-simulator
# or with explicit device
WAYKIN_SIMULATOR_NAME="iPhone 17 Pro" make validate-simulator
```

## What Waykin Is

Waykin is **not** a fitness tracker, virtual pet, cosmetic skin system, or AR novelty.

It is a system where:

```
Movement
  → Experience rules (Experience Pack)
  → Companion / rival behavior
  → Session result
  → Persistent memory
  → Future recommendations
```

The same core engines drive both simulated Demo Mode and real-device sessions.

## Current Proof of Concept

Three deterministic Experience Packs are implemented:

| Companion Walk | Orc Pursuit | Future Self |
|---|---|---|
| ![Companion Walk](docs/assets/experiences/companion-walk-card.png) | ![Orc Pursuit](docs/assets/experiences/orc-pursuit-card.png) | ![Future Self](docs/assets/experiences/future-self-card.png) |
| Calm companionship and exploration | Adaptive pursuit pressure | A stronger version of you stays ahead |

*Concept visuals — illustrate intended experience direction. Not current application footage.*

**Experience Pack Overview**

![Experience Pack Overview](docs/assets/experiences/experience-pack-overview.png)

Appearance + behavior + rules + progression

All experiences use the canonical MovementEngine and produce SessionMemory records.

## How It Works (Concept)

![Movement to Memory](docs/assets/diagrams/movement-to-memory.png)

*Concept visual — Movement becomes adaptive experience, persistent memory, and shared story.*

## Supported Surfaces (Observed)

| Surface                     | Current state                              |
|-----------------------------|--------------------------------------------|
| Swift package               | VALIDATED (17 tests)                       |
| iOS Simulator               | VALIDATED (build + UI smoke)               |
| Demo Mode                   | VALIDATED (CALM_DAY_WALK, NIGHT_ORC_PURSUIT, FUTURE_SELF_INTERVAL) |
| MapKit presentation         | Present in ActiveSessionView               |
| SwiftData persistence       | File-backed + @Query memory restoration    |
| Real Core Location path     | IMPLEMENTED (RealLocationProvider + real session start) |
| Physical iPhone walk        | IMPLEMENTED_UNVERIFIED / pending manual protocol |
| Phone AR (RealityKit)       | Structural stubs only                      |
| AR glasses                  | Future presentation surface                |

## Run in Xcode

1. Install XcodeGen if needed: `brew install xcodegen`
2. `make generate`
3. Open the generated `Waykin.xcodeproj`
4. Select the **Waykin** scheme
5. Choose an iPhone Simulator
6. Run the app
7. Use "Demo Scenarios" or the "Start Real Walk (COMPANION_WALK)" entry

Demo Mode requires no location permission. The real walk path requests When-In-Use authorization only when started.

## Demo Mode

Demo Mode exists to provide:

- No physical movement required
- No location permission required
- Deterministic, repeatable regression surface using the exact same MovementEngine and ExperienceEngine

Scenarios (via DemoSessionController):

- `CALM_DAY_WALK`
- `NIGHT_ORC_PURSUIT`
- `FUTURE_SELF_INTERVAL`

See `DEMO_SCRIPT.md` for exact terminal and UI flows.

## Architecture

![Waykin Architecture Diagram](docs/assets/diagrams/waykin-architecture.png)

*Engineering diagram — based on the current repository implementation.*

High-level data flow (proven in package + simulator):

```
World Context (time, activity)
      ↓
Movement Engine (snapshots + real ingestion)
      ↓
Experience Engine (Experience Pack rules)
      ↓
Companion Runtime
      ↓
Memory + Persistence (SwiftData)
      ↓
Presentation Adapters (MapKit, SwiftUI, future AR)
```

Major boundaries:
- `MovementEngine` + `LocationProviding` (sim + real)
- `WaykinExperience` protocol (pure functions)
- `PersistenceStore` with throwing save + @Query views
- AppModel owns engines and navigation

Full details: `ARCHITECTURE.md`

## Validation Pipeline

![Validation Pipeline](docs/assets/diagrams/validation-pipeline.png)

*Engineering diagram — current observed state.*

Canonical commands (verified):

```bash
make build          # swift build
make test           # swift test (17 tests)
make validate       # full harness (package + generation)
make validate-simulator
```

### Validation Matrix

| Layer                  | Command                     | Evidence (observed)                  |
|------------------------|-----------------------------|--------------------------------------|
| Package build          | `make build`                | PASS                                 |
| Package tests          | `make test`                 | 17 tests, 0 failures                 |
| Canonical harness      | `make validate`             | OVERALL: PASS (package + generation) |
| Simulator UI tests     | `make validate-simulator`   | 7 tests targeted; UI smoke surface   |
| Physical device        | Manual protocol             | Pending (see physical doc)           |

## Physical-Device Validation

Three-layer strategy:

1. Deterministic Demo Mode (package)
2. Simulator route + UI validation
3. Physical iPhone field validation (required for real GPS, drift, battery, usability)

Simulator cannot fully prove real GPS behavior, outdoor accuracy, or device sensor characteristics.

See `docs/PHYSICAL_DEVICE_WALK_VALIDATION.md` for the preflight checklist and 5–10 minute COMPANION_WALK protocol.

**No physical walk receipt has been filled yet.** All physical claims remain `NOT_COMPUTABLE` until direct device observation.

## Current Scope

| Capability | Status                  |
|------------|-------------------------|
| Walk       | Current focus (real path ready) |
| Run        | Core model present      |
| Cycling    | Deferred                |
| Hiking     | Deferred                |
| Climbing   | Deferred                |
| Marketplace| Deferred                |
| Multiplayer| Deferred                |
| AR glasses | Future                  |

## Roadmap (High Level)

```
Simulator-valid MPOC
→ Physical walk validation (COMPANION_WALK)
→ Real run validation
→ Outdoor usability refinement
→ Audio-first behavior
→ Wearables and glasses adapters
```

## Safety and Privacy

- Waykin is not safety equipment.
- Location is used only during active movement sessions (When-In-Use).
- Demo Mode works completely without location permission.
- Exact route coordinates should not be committed in validation artifacts.
- Unsupported conclusions (battery, AR performance, real-world accuracy) remain `NOT_COMPUTABLE`.

## Contributing and Agent Workflow

- Read the existing engineering contracts in the repository.
- Preserve canonical validation: always run `make validate` before claiming success.
- Run `make validate-simulator` for any UI or session flow changes.
- Keep changes scoped. Do not fabricate test results or physical evidence.
- Distinguish clearly between simulator-validated and physical-device surfaces.
- Physical-device claims require the manual protocol in `docs/PHYSICAL_DEVICE_WALK_VALIDATION.md`.

## License

Apache 2.0 — see `LICENSE`.