# AR Baseline Reconciliation

Status: `IMPLEMENTED_UNVERIFIED`

Issue: #27

## Purpose

Reconstruct the useful AR-1 and merged AR-2 implementation on top of current `main` without carrying forward the conflicted branch history or stale documentation overrides.

## Included

- Isolated `WaykinARLab` application target and scheme
- Camera authorization and AR capability resolution
- AR session lifecycle and interruption handling
- Horizontal raycast placement
- Bounded semantic entity registry
- Procedural engineering representation of Lira
- Deterministic `idle`, `follow`, `investigate`, `alert`, and `celebrate` presentation states
- `ARWorldCommand` renderer for companion, discovery, threat, removal, and clear operations
- Privacy-filtered AR diagnostics and validation receipt
- Focused app-target unit tests

Issue #35 extends this isolated engineering surface with deterministic living-companion transitions, bounded RealityKit presentation changes, stable Lira identity, and explicit AR Lab state/result diagnostics. Simulator and automated validation are engineering evidence only; physical-device presentation and readability remain `NOT_COMPUTABLE`.

## Deliberately Rejected During Reconciliation

The earlier branch redirected the normal `Waykin` scheme to launch the AR Lab. This reconstruction preserves the normal walking application as the `Waykin` executable and exposes the AR Lab only through the separate `WaykinARLab` scheme.

Stale versions of binding architecture and repository-governance documents were not copied over current `main`. Their compatible AR claims were manually reconciled into `ARCHITECTURE.md`.

## Frozen Systems

- Movement acceptance and integrity
- World event selection
- Companion gameplay state
- Pursuit semantics
- Bond
- Persistence schemas
- Session memories and field receipts
- Semantic audio

## Required Validation

Run from `agent/ar-reconciliation-main`:

```bash
xcodegen generate
make build
make test
make validate
make validate-simulator
git diff --check
```

Verify framework isolation:

```bash
! grep -RInE '^[[:space:]]*import[[:space:]]+(ARKit|RealityKit|SwiftUI|MapKit|SwiftData|AVFoundation)' Sources/WaykinCore
```

## Physical Evidence Gate

On a compatible iPhone, validate:

- Camera authorization paths
- Session start, pause, reset, interruption, and recovery
- Horizontal placement success and bounded failure behavior
- Lira replacement and all five presentation states
- Discovery and threat placeholders
- Clear-session cleanup
- Tracking-limited messaging
- Battery and thermal observations

No physical-device claim is valid until direct evidence is attached to the PR or issue.
