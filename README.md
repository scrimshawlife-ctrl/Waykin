<p align="center">
  <img src="docs/assets/waykin-hero.svg" alt="Waykin concept art: a walker and luminous companion moving through a mountain valley at dawn" width="100%">
</p>

<p align="center">
  <a href="https://github.com/scrimshawlife-ctrl/Waykin/actions/workflows/validate.yml"><img alt="Canonical validation" src="https://github.com/scrimshawlife-ctrl/Waykin/actions/workflows/validate.yml/badge.svg?branch=main"></a>
  <a href="https://github.com/scrimshawlife-ctrl/Waykin/actions/workflows/waykin-ci.yml"><img alt="Waykin CI" src="https://github.com/scrimshawlife-ctrl/Waykin/actions/workflows/waykin-ci.yml/badge.svg?branch=main"></a>
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white">
  <img alt="Platform iOS" src="https://img.shields.io/badge/platform-iOS-0A84FF?logo=apple&logoColor=white">
  <a href="LICENSE"><img alt="Apache 2.0 License" src="https://img.shields.io/badge/license-Apache--2.0-6E56CF"></a>
</p>

<p align="center">
  <strong>An audio-first adaptive walking experience.</strong><br>
  You move. Lira moves with you. The world responds. Bond grows.
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> ·
  <a href="WAYKIN_SPEC.md">Product Contract</a> ·
  <a href="ARCHITECTURE.md">Architecture</a> ·
  <a href="docs/README.md">Documentation</a> ·
  <a href="CONTRIBUTING.md">Contributing</a> ·
  <a href="AGENTS.md">Agent Guide</a>
</p>

> **Concept visual.** The hero artwork communicates product direction and is not evidence of implemented application graphics or AR functionality. See [`docs/assets/BRAND_GUIDE.md`](docs/assets/BRAND_GUIDE.md).

---

## What Is Waykin?

Waykin turns a real-world walk into a small, responsive journey shared with a persistent companion named **Lira**.

The current product is deliberately constrained around one coherent loop:

```text
Home
  → Begin Walk
  → Active Session
  → Session Summary
  → Memory
```

Movement becomes semantic world state. World state produces bounded events. Events shape Lira, pursuit pressure, audio cues, memories, and Bond—without requiring a backend or generative-AI runtime.

### MVP Pillars

| Pillar | Current contract |
|---|---|
| **Real-world movement** | Walking is the launch activity and gameplay input. |
| **One companion** | Lira is the single persistent companion. |
| **Bounded pressure** | Pursuit creates tension without becoming an enemy platform. |
| **One progression metric** | Bond represents the evolving relationship with Lira. |
| **Audio first** | Semantic audio carries presence, discovery, pressure, and memory. |
| **Local and deterministic** | Core behavior is seeded, testable, and locally persisted. |

The binding scope is defined in [`WAYKIN_SPEC.md`](WAYKIN_SPEC.md). Broader design documents are not implementation authority unless promoted through the repository’s documented process.

## Quick Start

### Requirements

- macOS with a compatible Xcode installation
- Swift 6 toolchain
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- An iOS Simulator for simulator validation

### Build and Validate

```bash
git clone https://github.com/scrimshawlife-ctrl/Waykin.git
cd Waykin

make build
make test
make validate
make validate-simulator
```

`make validate-simulator` targets `iPhone 17 Pro` by default. Override the simulator with:

```bash
WAYKIN_SIMULATOR_NAME="iPhone 17 Pro" make validate-simulator
```

### Run the Deterministic Demo

```bash
make demo
```

Demo Mode exercises the same bounded walking loop without location permission or physical movement.

## Runtime Architecture

```text
Core Location sample / deterministic Demo tick
      ↓
MovementIntegrityProcessor
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
SessionMemory + Bond
```

`WaykinCore` owns semantic gameplay state. SwiftUI, MapKit, SwiftData, Core Location, AVFoundation, ARKit, and RealityKit remain adapter or presentation concerns and must not become alternate sources of gameplay truth.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for system ownership, dependency direction, AR boundaries, and deferred seams.

## Implemented Surface

- Deterministic walking-session state machine
- Real-sample movement integrity processing
- Seeded, cooldown-aware event generation
- Lira companion runtime
- Bounded pursuit state
- Seven semantic audio cue kinds
- App-target `AVAudioPlayer` adapter with safe-silence fallback
- SwiftData persistence for Bond and concise session memories
- Deterministic Demo Mode
- When-In-Use Core Location wiring for physical-device walks
- Privacy-filtered local field-test receipts
- Platform-neutral AR presentation contracts and app-side AR work in progress

Compatibility values for running, cycling, hiking, and climbing may remain in the model, but **walking is the only current product activity**.

## Scope Boundaries

Waykin does **not** currently include:

- Accounts, authentication, or backend infrastructure
- Multiplayer or social graphs
- Marketplace or creator systems
- Generative-AI runtime behavior
- Generalized narrative engines
- LiveOps, currencies, inventory, or skill trees
- Wearable dependence
- AR-glasses dependence
- Live weather integration

Future-state documentation is reference material until explicitly promoted through an accepted issue, architecture review, and—when necessary—an ADR. See [`docs/governance/DOCUMENT_AUTHORITY.md`](docs/governance/DOCUMENT_AUTHORITY.md).

## Safety and Privacy

- Waykin is not safety equipment.
- Location is requested only for an active real walk.
- Demo Mode requires no location permission.
- Pause and stop behavior remain available.
- Pursuit must never pressure a user to continue through distress or unsafe conditions.
- Memories are concise deterministic facts, not precise route archives.
- Local field receipts exclude coordinates and personal memory text, retain at most 20 files, and never upload automatically.

## Validation Status

The following results were recorded on **July 16, 2026** and apply to the tested repository state at that time:

| Layer | Command or protocol | Recorded result |
|---|---|---|
| Swift package build | `make build` | PASS |
| Swift package tests | `make test` | PASS — 40 tests |
| Native app tests | Focused `xcodebuild test` | PASS — 58 tests |
| Canonical harness | `make validate` | PASS, including native app build |
| Simulator UI | `make validate-simulator` | PASS — 6 UI tests |
| Physical GPS walk | Manual protocol | `NOT_COMPUTABLE` in that receipt |
| Physical audio playback | Manual protocol | `NOT_COMPUTABLE` in that receipt |

Workflow badges above report the current `main` branch state. A badge can be unknown or failing until GitHub Actions has run successfully for that workflow. Dated validation claims are historical evidence, not permanent guarantees. Do not mark GPS, device audio, battery, outdoor usability, or AR behavior as validated without direct device evidence.

## Documentation Map

| Area | Document |
|---|---|
| Binding product scope | [`WAYKIN_SPEC.md`](WAYKIN_SPEC.md) |
| Architecture | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Agent operating contract | [`AGENTS.md`](AGENTS.md) |
| Contribution workflow | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Documentation index | [`docs/README.md`](docs/README.md) |
| Current capability matrix | [`docs/canonical/CURRENT_CAPABILITY_MATRIX.md`](docs/canonical/CURRENT_CAPABILITY_MATRIX.md) |
| Document authority | [`docs/governance/DOCUMENT_AUTHORITY.md`](docs/governance/DOCUMENT_AUTHORITY.md) |
| Known limitations | [`KNOWN_LIMITATIONS.md`](KNOWN_LIMITATIONS.md) |
| Solo MVP scope | [`docs/SOLO_MVP_SCOPE.md`](docs/SOLO_MVP_SCOPE.md) |
| Physical walk validation | [`docs/PHYSICAL_DEVICE_WALK_VALIDATION.md`](docs/PHYSICAL_DEVICE_WALK_VALIDATION.md) |
| Field-test protocol | [`docs/FIELD_TEST_PROTOCOL.md`](docs/FIELD_TEST_PROTOCOL.md) |
| Audio contract | [`docs/AUDIO_ASSET_CONTRACT.md`](docs/AUDIO_ASSET_CONTRACT.md) |

## Contributing

Waykin uses issue-scoped branches, draft pull requests, explicit scope boundaries, and evidence-backed validation.

Start with [`CONTRIBUTING.md`](CONTRIBUTING.md). Coding agents must also read [`AGENTS.md`](AGENTS.md) before modifying the repository.

## License

Licensed under the [Apache License 2.0](LICENSE).
