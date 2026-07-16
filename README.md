# Waykin

**Minimum Proof of Concept (MPOC)**

A movement-driven experience engine where persistent companions change how real-world activity feels.

## Validation

The canonical validation harness is the single source of truth:

```bash
make validate
# or
./scripts/validate.sh
```

This runs:
- Tool version checks
- `xcodegen generate`
- `swift build`
- `swift test`

See `KNOWN_LIMITATIONS.md` for gates that remain unverified until full simulator execution.

## Build & Run (Swift Package)

```bash
swift build
swift test
swift run WaykinDemo
```

The Demo executable proves the full loop in simulation (no permissions or GPS required).

## Key Features in This MPOC

- MovementEngine with deterministic simulation
- Three modular experiences: Companion Walk, Orc Pursuit, Future Self
- Companion state machine
- Deterministic Memory generation
- Time-of-day Recommendation engine
- Full session lifecycle + persistence simulation
- Day / Night variants

## iOS App

The full SwiftUI + RealityKit + MapKit app is scaffolded in `App/`.
Open the sources in Xcode to assemble the native iOS target (requires full Xcode).

See `DEMO_SCRIPT.md` for exact steps to experience the core thesis.

## Status

See `WAYKIN_MPOC_IMPLEMENTATION_RECEIPT.md` (generated at end of build).

## Limitations (this build)

- AR is structural stub only (full RealityKit requires Xcode + device)
- No real backend
- Demo uses terminal simulation for full loop
- Climb activity is extension point only

This MPOC proves: Choose movement → Choose experience → Move/simulate → Experience reacts → Memory created → Companion remembers → New recommendation.
