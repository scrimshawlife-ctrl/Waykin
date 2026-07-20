# Persistence Hardening Checklist

## P0 Foundation

- [x] Pin implementation baseline SHA and toolchain receipt. (`8f25dc2`, Swift 6.3.2, Xcode 26.5, 2026-07-20)
- [x] Add `WaykinSchemaV1`.
- [x] Add `WaykinMigrationPlan`.
- [x] Centralize every ModelContainer construction path. (`WaykinPersistenceContainerFactory`; app production path)
- [x] Verify real file-backed store URL in diagnostics.
- [x] Remove ambiguous `try!` durable fallback (degraded in-memory path; emergency only if that fails).
- [x] Represent degraded persistence explicitly. (`PersistenceAvailability`)

## P0 Integrity

- [x] Establish stable canonical Lira identity. (`CanonicalCompanionIdentity.liraID`)
- [x] Replace unsorted companion fetch.
- [x] Enforce one canonical completion per `sessionID` (unique attribute + store check).
- [x] Distinguish not-found from fetch failure. (`fetchFailed` / empty optional)
- [x] Add independent-context duplicate tests.

## P1 Isolation

- [x] Add repository protocols. (`CompanionRepository` / `SessionMemoryRepository` / `WaykinPersistenceServing`)
- [x] Add SwiftData `ModelActor` adapter. (`WaykinPersistenceActor` + `WaykinPersistenceGateway`)
- [x] Add deterministic in-memory test adapters. (`InMemoryPersistenceRepository`, `FailingPersistenceRepository`)
- [x] Keep WaykinCore engines free of SwiftData. (only Persistence/* imports SwiftData)
- [x] Inject persistence through app orchestration. (`WaykinAppModel.persistence`)

## P1 Session Aggregate

- [x] Define approved structured completion fields. (`CompletedSession`)
- [x] Persist Bond before/after.
- [x] Persist distance and active duration.
- [x] Persist completion reason and scenario/mode.
- [x] Preserve concise memory text as presentation.
- [x] Exclude coordinates and route geometry.
- [x] Exclude raw HealthKit samples.
- [x] Exclude AR transforms and anchors.
- [x] Exclude unbounded telemetry and AI history.
- [x] One completion transaction (companion + aggregate) via `saveCompletedSession`.

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
