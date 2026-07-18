# Waykin Current Product Specification

## Status

- Maturity: `CURRENT`
- Authority: `BINDING`
- Implementation status: `PARTIAL`
- Approved scope: `true`

## Product Contract

Waykin is an audio-first adaptive walking experience in which one persistent companion, Lira, and one bounded pursuit-pressure state respond to how the user moves.

The current product is a solo-developer MVP vertical slice. Complexity belongs in deterministic data and configuration, not in additional platforms or generalized systems.

## Approved MVP Systems

1. Movement integrity and Movement Engine
2. World State and deterministic Event Generator
3. Lira Companion Runtime
4. Bounded Pursuit State
5. Semantic Audio Experience
6. Local Bond and concise Session Memory persistence
7. Privacy-filtered local field-test receipts
8. Platform-neutral AR presentation contracts and milestone-scoped app adapters

## Binding Invariants

- Walking is the launch activity.
- Lira is the single canonical companion.
- Bond is the single persistent progression metric.
- Pursuit is bounded pressure, not a generalized enemy framework.
- Seeded behavior must remain reproducible.
- `WaykinCore` must not depend on ARKit, RealityKit, SwiftUI, MapKit, SwiftData, or audio filenames.
- Presentation adapters may realize semantic state but may not become alternate gameplay authorities.
- Physical-device behavior is not validated without direct device evidence.
- Safety, pause, and stop behavior take precedence over dramatic pressure.

## Explicitly Excluded or Deferred

The following are not authorized by this specification:

- Backend infrastructure, accounts, authentication, or cloud save
- Multiplayer or social graphs
- Marketplace, creator tools, or creator SDK
- Generalized narrative engine
- Generalized AI Director
- Economy or LiveOps systems
- Generative AI runtime
- Mandatory AR glasses or wearable dependency
- Expansion to run, cycle, hike, or climb before walking is proven

Detailed future documents may guide seams. They do not authorize implementation.

## Validation Contract

```bash
make build
make test
make validate
git diff --check
```

Run `make validate-simulator` for simulator-visible changes. Use the applicable physical-device protocol for GPS, device audio, AR tracking, interruption recovery, thermal, or battery-sensitive behavior.

## Evidence Vocabulary

- `OBSERVED`: directly verified in code, command output, or device evidence.
- `INFERRED`: conclusion derived from observed evidence.
- `NOT_COMPUTABLE`: required evidence is unavailable.
