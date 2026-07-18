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

1. `companionObserves` → Lira investigates.
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

## Physical validation

Place Lira using **Start Arc**, then press **Next Event** seven times and confirm the displayed event and Lira state follow the canonical sequence. Confirm the manual discovery renderer, threat creation/in-place intensification/removal, final celebration, stable entity counts, scene cleanup, and that the demo session ends after the seventh event.

This bounded protocol passed indoors and outdoors on an iPhone 17 Pro before the allocation repair, including repaired background/foreground recovery and fresh placement after reopen. The final repaired executable passes indoor behavior, the operator-confirmed post-warm-up retained-memory gate, and the predeclared 90-second frame-pacing gate; its bounded outdoor regression remains open. Absolute production memory remains unproven, and sunlight readability was not reported. See `docs/AR3_PHYSICAL_DEVICE_VALIDATION.md` for the evidence and explicit exclusions.
