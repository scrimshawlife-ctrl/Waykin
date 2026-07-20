# ADR-0003: Local-First SwiftData Persistence

- Status: Accepted
- Date: 2026-07-20
- Decision owner: Waykin product and engineering
- Scope: iPhone MVP persistence

## Context

Waykin is a solo-developer, audio-first adaptive movement application. Its MVP must complete walks without a network dependency and currently persists a small amount of durable state: Lira, Bond, and concise session memories. Preferences and field-test evidence already use separate storage mechanisms appropriate to their semantics.

The current SwiftData implementation proves file-backed reopen behavior, but the persistent schema is not explicitly versioned, production initialization can fall back without adequately exposing degraded durability, companion retrieval is based on unspecified fetch order, and the one-memory-per-session invariant is enforced primarily in application code.

## Decision

Waykin adopts SwiftData as the canonical local database for MVP durable domain state.

The implementation will:

1. remain local-first and offline-capable;
2. place SwiftData behind narrow repository protocols;
3. serialize database access through a SwiftData `ModelActor`;
4. establish a versioned schema and migration plan;
5. use a stable canonical Lira identity;
6. enforce session completion idempotency through the durable schema;
7. expose initialization, migration, read, and write failures explicitly;
8. keep raw location, HealthKit samples, AR transforms, transient events, and ordinary diagnostics outside the product database;
9. retain bounded field-test receipts as separate atomic JSON artifacts;
10. defer CloudKit and all remote databases until an explicit product requirement passes a separate architecture gate.

## Rationale

SwiftData matches Waykin's small typed local domain, Apple platform target, privacy posture, and one-developer operating constraint. Replacing it with Firebase, Supabase, Realm, or a custom backend would add authentication, networking, synchronization, privacy, failure-state, and operations complexity without solving a current MVP requirement.

The repository boundary prevents SwiftData from becoming gameplay architecture. Versioning and actor isolation reduce migration and concurrency risk while preserving future optionality.

## Consequences

### Positive

- Walk completion remains independent of connectivity.
- Durable state remains on-device by default.
- The implementation uses native Apple persistence and migration facilities.
- Domain engines remain testable without a database.
- Cloud synchronization can be evaluated later without changing core gameplay contracts.

### Costs

- Schema changes require migration discipline.
- Persistence failures need explicit user-facing degraded states and test coverage.
- Repository protocols and a model actor add a small amount of infrastructure.
- Multi-device continuity is intentionally unavailable until separately promoted.

## Rejected Alternatives

### Firebase or Supabase

Rejected for MVP because remote persistence, authentication, availability, privacy, and operational concerns are not justified by current requirements.

### Realm

Rejected because the current native SwiftData implementation is sufficient and migration would produce cost without demonstrated benefit.

### Custom SQLite layer

Rejected because Waykin does not require low-level query control or a cross-platform database abstraction.

### Immediate CloudKit synchronization

Deferred rather than permanently rejected. CloudKit requires a product requirement, compatible schema, conflict and deletion policy, entitlements, migration strategy, and physical multi-device evidence.

## Promotion Conditions for Cloud Sync

A new ADR is required when one or more approved requirements exist:

- multi-device Bond and memory continuity;
- reinstall recovery;
- independently durable Apple Watch writes;
- account-backed personalization;
- support-visible server state.

## References

- `ARCHITECTURE.md`
- `docs/design/PERSISTENCE_ARCHITECTURE.md`
- `docs/plans/PERSISTENCE_HARDENING_PLAN.md`
