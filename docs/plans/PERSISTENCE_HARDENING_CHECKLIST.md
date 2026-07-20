# Persistence Hardening Checklist

## P0 Foundation

- [ ] Pin implementation baseline SHA and toolchain receipt.
- [ ] Add `WaykinSchemaV1`.
- [ ] Add `WaykinMigrationPlan`.
- [ ] Centralize every ModelContainer construction path.
- [ ] Verify real file-backed store URL in diagnostics.
- [ ] Remove `try!` persistence fallback.
- [ ] Represent degraded persistence explicitly.

## P0 Integrity

- [ ] Establish stable canonical Lira identity.
- [ ] Replace unsorted companion fetch.
- [ ] Enforce one canonical completion per `sessionID`.
- [ ] Distinguish not-found from fetch failure.
- [ ] Add independent-context duplicate tests.

## P1 Isolation

- [ ] Add repository protocols.
- [ ] Add SwiftData `ModelActor` adapter.
- [ ] Add deterministic in-memory test adapters.
- [ ] Keep WaykinCore engines free of SwiftData.
- [ ] Inject persistence through app orchestration.

## P1 Session Aggregate

- [ ] Define approved structured completion fields.
- [ ] Persist Bond before/after.
- [ ] Persist distance and active duration.
- [ ] Persist completion reason and scenario/mode.
- [ ] Preserve concise memory text as presentation.
- [ ] Exclude coordinates and route geometry.
- [ ] Exclude raw HealthKit samples.
- [ ] Exclude AR transforms and anchors.
- [ ] Exclude unbounded telemetry and AI history.

## P1 Validation

- [ ] Reopen test passes.
- [ ] Seeded migration test passes.
- [ ] Interrupted completion remains idempotent.
- [ ] Duplicate completion remains idempotent.
- [ ] Production and test stores remain isolated.
- [ ] Reset behavior is explicit and tested.
- [ ] Corruption/migration failure preserves data and exposes recovery state.
- [ ] Field receipts remain separate and bounded.

## P2 Cloud Gate

- [ ] Confirm qualifying product requirement exists.
- [ ] Draft separate CloudKit ADR.
- [ ] Define conflict and deletion policy.
- [ ] Define offline and partial-sync UX.
- [ ] Validate entitlements and privacy disclosure.
- [ ] Collect multi-device physical evidence.
- [ ] Record `PROMOTE`, `DEFER`, or `REJECT`.
