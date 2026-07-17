# Waykin AR-3 Static Audit Receipt

## Baseline

- Branch: `ar3-runtime-integration`
- Audited head before this receipt: `50a3543e610099979aadf03727bf6c27b6daacad`
- Base: `agent/ar1-realitykit-session-shell` at `430516e2272e5cf5e304e7d756afa4d2e605fc22`

## Repaired

The AR runtime integration tests now construct `WorldEvent` with the canonical initializer:

```swift
WorldEvent(
    kind: kind,
    occurredAt: .distantPast,
    intensity: 0.5,
    debugLabel: kind.rawValue
)
```

The stale `timestamp` and `metadata` argument form is not present on the audited branch.

## Static contract audit

Confirmed by direct source comparison:

- `ARWorldCommand` cases used by the adapter and renderer exist in `WaykinCore`.
- `SpatialIntent` enum values used by AR-3 exist in the sealed core contracts.
- `WorldEventKind` values used by the seven-event demo arc exist in the core model.
- `CompanionBehaviorState` mappings are exhaustive for the current enum.
- Lira, discovery, and threat use stable semantic UUIDs in the adapter.
- `WaykinCore` remains free of ARKit and RealityKit imports in the AR-3 diff.
- AR-3 does not alter movement acceptance, Bond, persistence, session memories, event scheduling, field receipts, or semantic audio.

## Execution evidence

- GitHub Actions runs for audited head: none observed.
- Local `swift test`: NOT_EXECUTED in this audit.
- Local `make validate`: NOT_EXECUTED in this audit.
- Simulator validation: NOT_EXECUTED in this audit.
- Physical AR runtime arc: NOT_EXECUTED in this audit.

## Classification

`WAYKIN_AR3_STATIC_REPAIR_COMPLETE_EXECUTION_PENDING`

This receipt does not authorize merge. Local compilation and validation remain required.
