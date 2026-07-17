# Waykin

Waykin is an audio-first adaptive walking experience where a persistent companion and occasional phenomena respond to how you move.

The current MVP is intentionally narrow: one walking loop, one companion, one bounded pressure phenomenon, deterministic Demo Mode, physical-device walk wiring, persistent Bond, and concise session memories.

## Quick Start

```bash
make build
make test
make validate
make validate-simulator
```

`make validate-simulator` requires an available iOS Simulator. By default it targets `iPhone 17 Pro`; override with:

```bash
WAYKIN_SIMULATOR_NAME="iPhone 17 Pro" make validate-simulator
```

## Current Product Loop

```text
Home
  -> Begin Walk
  -> Active Session
  -> Session Summary
  -> Memory
```

Home shows Lira, Bond, the latest memory when one exists, one primary Begin Walk action, Memory History, and a separate real-walk entry for physical-device validation. Demo Mode runs the same deterministic walking loop without requiring movement or location permission.

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

The core package emits semantic state and semantic audio cues. SwiftUI, MapKit, persistence, and the app-target audio adapter consume that state without owning gameplay rules or filenames.

## Implemented Scope

- Walking is the MVP activity.
- Lira is the single companion.
- Bond is the persistent progression measure.
- Pursuit is a bounded pressure state, not a separate enemy system.
- Event generation is deterministic, seeded, cooldown-aware, and test-covered.
- Seven semantic audio cues map through an `AVAudioPlayer` app adapter to restrained bundled placeholder WAV files or safe silence.
- SwiftData persists companion Bond and session memories.
- Demo Mode is deterministic and package-testable.
- Physical-device walking is wired through When-In-Use Core Location, but field behavior remains unverified until manually tested.

Existing run, cycle, hike, and climb model values may still exist for compatibility. Deprecated Orc Pursuit and Future Self runtime types remain only as temporary source/API compatibility and are not returned by recommendations, Demo Mode, variants, or the primary UI.

## Explicit Non-Goals

Waykin currently does not include multiplayer, social graphs, accounts, backend infrastructure, marketplace or creator systems, generative AI, AR gameplay, wearable integration, live weather, currencies, inventory, skill trees, achievements, or a generalized narrative engine.

## Safety And Privacy

- Waykin is not safety equipment.
- Location is requested only for an active real walk.
- Demo Mode requires no location permission.
- Pause and stop behavior are preserved.
- Session memories are concise deterministic facts, not precise historical route archives.
- Pursuit pressure must never instruct unsafe movement or continued exertion through distress.

## Validation Status

Observed on July 16, 2026:

| Layer | Command | Status |
|---|---|---|
| Package build | `make build` | PASS |
| Package tests | `make test` | PASS, 25 tests |
| App audio adapter | focused `xcodebuild test` | PASS, 7 tests |
| Canonical harness | `make validate` | PASS, including native app build |
| Simulator UI | `make validate-simulator` | PASS, 6 UI tests |
| Physical GPS walk | Manual protocol | NOT_COMPUTABLE |
| Physical audio playback | Manual protocol | NOT_COMPUTABLE |

Do not mark physical GPS, audio-device, battery, or outdoor usability behavior as validated without direct device evidence.

## Documentation

- Architecture: `ARCHITECTURE.md`
- Known limitations: `KNOWN_LIMITATIONS.md`
- Solo MVP scope contract: `docs/SOLO_MVP_SCOPE.md`
- Physical-device manual protocol: `docs/PHYSICAL_DEVICE_WALK_VALIDATION.md`
- Audio asset contract: `docs/AUDIO_ASSET_CONTRACT.md`

## License

Apache 2.0. See `LICENSE`.
