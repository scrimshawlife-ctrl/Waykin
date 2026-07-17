# AR-3 Runtime Integration

## Objective

Connect the existing deterministic Companion Walk demo semantics to the AR presentation layer without modifying movement, event generation, Bond, persistence, field receipts, or audio semantics.

## Runtime flow

```text
DemoSessionController
        ↓
CompanionRuntime + WorldEvent
        ↓
ARCompanionRuntimeAdapter
        ↓
ARWorldCommand[]
        ↓
ARWorldCommandRenderer
        ↓
Procedural Lira / discovery / threat placeholders
```

## Canonical demo arc

1. `companionObserves` → Lira investigates; discovery placeholder appears.
2. `companionDrawsNear` → Lira becomes alert and draws near semantically.
3. `distantPresence` → Lira investigates; distant threat placeholder appears.
4. `pursuitBegins` → Lira becomes alert; stable threat identity remains active.
5. `pursuitIntensifies` → alert state remains; threat intensity increases.
6. `pursuitFades` → threat placeholder is removed; Lira returns to follow.
7. `bondMoment` → Lira celebrates.

## AR Lab controls

- **Start Arc** resets rendered content and starts the canonical demo scenario.
- **Next Event** advances exactly one existing demo tick.
- **Run Arc** processes all remaining demo ticks.
- Existing direct state and engineering-placeholder controls remain available.

## Ownership boundary

The adapter reads public core values and emits presentation contracts. It does not mutate core event scheduling, companion rules, movement state, progression, persistence, or audio.

## Explicitly deferred

- real-player follow locomotion
- yaw smoothing and target-facing orientation
- timing-based RealityKit animation playback
- physical walking integration
- Bond mutation from AR
- final models and skeletal animation
- outdoor calibration

## Pre-device validation

```bash
swift test
xcodegen generate
make build
make validate
make validate-simulator
git diff --check
```

Expected core framework isolation:

```bash
grep -RInE '^[[:space:]]*import[[:space:]]+(ARKit|RealityKit)' Sources/WaykinCore
```

No matches are allowed.

## Physical validation target

Place Lira using **Start Arc**, then press **Next Event** seven times and confirm the displayed event and Lira state follow the canonical sequence. Confirm discovery creation, threat creation/intensification/removal, final celebration, stable entity counts, and scene cleanup.
