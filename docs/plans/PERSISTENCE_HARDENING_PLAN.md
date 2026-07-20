# Persistence Hardening Plan

## Outcome

Convert Waykin's working SwiftData prototype into a versioned, deterministic, failure-visible, actor-isolated local persistence subsystem without changing gameplay behavior or introducing cloud services.

## Scope Guard

This plan does not add accounts, networking, CloudKit, a third-party database, persistent GPS history, persistent HealthKit samples, persistent AR state, or a generalized telemetry store.

## Baseline Evidence to Capture

Before WP-DB1 implementation begins, pin the exact `main` SHA and record:

- Xcode and Swift versions;
- package, native, and UI test counts;
- file-backed persistence reopen results;
- current SwiftData schema and store path;
- current UserDefaults keys;
- current receipt-storage path and retention bound;
- clean-worktree status.

## Work Packages

### WP-DB1 — Canonical Persistence Foundation

**Priority:** P0

**Deliverables**

- `WaykinSchemaV1: VersionedSchema`.
- `WaykinMigrationPlan` with V1 registered.
- One `WaykinPersistenceContainerFactory` used by production, tests, previews, and diagnostics.
- Actual store identity available to privacy-safe diagnostics.
- Explicit persistence availability/degraded state.
- Removal of ambiguous silent fallback and `try!` persistence initialization.

**Acceptance**

- All container construction routes through one factory.
- Existing file-backed data opens without loss.
- Failed initialization cannot be reported as durable file-backed operation.
- UI can distinguish available, degraded, and failed persistence.
- Existing gameplay tests remain behaviorally unchanged.

### WP-DB2 — Durable Integrity and Deterministic Identity

**Priority:** P0

**Deliverables**

- Stable canonical Lira identifier or singleton app-state pointer.
- Exact companion fetch instead of unsorted `.last` selection.
- Unique durable `sessionID` completion constraint.
- Typed not-found, fetch, migration, and write errors.
- Removal of `try?` where it conflates missing data with database failure.

**Acceptance**

- Canonical companion selection is deterministic.
- Two writes for the same completed session cannot create two canonical summaries.
- Independent tasks or contexts are covered by duplicate-write tests.
- Read failures remain distinguishable from no-record results.

### WP-DB3 — Repository and ModelActor Boundary

**Priority:** P1

**Deliverables**

- `CompanionRepository`.
- `SessionMemoryRepository` or a bounded `SessionRepository` if structured summaries are introduced concurrently.
- SwiftData-backed `@ModelActor` implementation.
- In-memory deterministic test implementations.
- App-model dependency injection through protocols.

**Acceptance**

- WaykinCore gameplay engines do not import SwiftData.
- All production database reads and writes pass through one serialized authority.
- Persistence failure and latency can be injected in tests.
- No gameplay rules move into persistence adapters.

### WP-DB4 — Structured Completed-Session Aggregate

**Priority:** P1

**Deliverables**

Persist one concise aggregate per completed session containing approved fields such as:

- session ID;
- scenario or mode;
- start and completion timestamps;
- active duration;
- accepted distance;
- completion reason;
- Bond before and after;
- concise memory text.

**Explicit exclusions**

- raw coordinates;
- route geometry;
- every movement sample;
- every event tick;
- audio playback logs;
- raw HealthKit records;
- AR anchors or transforms;
- unrestricted AI conversation history.

**Acceptance**

- Memory presentation does not require parsing prose to recover core session facts.
- One completion transaction saves Bond linkage and the session aggregate idempotently.
- Existing memory history remains compatible or has a documented migration.

### WP-DB5 — Migration, Recovery, and Lifecycle Validation

**Priority:** P1

**Deliverables**

- Seeded schema migration fixtures.
- Store-reopen and app-relaunch tests.
- Interrupted and repeated completion tests.
- Production/test store isolation tests.
- Explicit reset tests.
- Corruption or migration-failure recovery behavior.
- Documentation for support-safe recovery that does not silently delete data.

**Acceptance**

- A previous-version store migrates under test.
- Duplicate or resumed completion produces one canonical record.
- Receipt JSON remains separate from SwiftData.
- A failed migration produces a visible state and preserves the original store for diagnosis or explicit recovery.

### WP-DB6 — CloudKit Evaluation Gate

**Priority:** P2

This is a decision package, not implementation.

Evaluate CloudKit only after an approved requirement exists. The package must cover:

- product requirement and user value;
- compatible schema review;
- merge/conflict policy;
- deletion propagation;
- account and entitlement states;
- offline and partial-sync presentation;
- privacy disclosures;
- migration and rollback;
- multi-device physical evidence;
- operating and support burden.

**Acceptance**

- Output is a separate ADR with `PROMOTE`, `DEFER`, or `REJECT`.
- No CloudKit capability or schema constraint is added before that decision.

## Recommended Issue Breakdown

1. P0 — Establish SwiftData VersionedSchema and container factory.
2. P0 — Remove silent fallback and expose persistence degradation.
3. P0 — Enforce deterministic Lira and session identity.
4. P1 — Introduce repository protocols and SwiftData ModelActor.
5. P1 — Add structured completed-session aggregate.
6. P1 — Build migration, interruption, duplicate, and recovery suite.
7. P2 — Run CloudKit promotion review when product requirements justify it.

## Sequencing

```text
WP-DB1
   ↓
WP-DB2
   ↓
WP-DB3
   ↓
WP-DB4
   ↓
WP-DB5
   ↓
WP-DB6 only after a qualifying product requirement
```

WP-DB4 may be designed during WP-DB3, but production migration should not begin until the versioned schema and integrity rules are established.

## Completion Receipt

The final implementation receipt must include:

- baseline and final SHAs;
- files changed;
- schema versions and migration stages;
- store location and backup classification;
- tests and counts;
- duplicate-write evidence;
- reopen and migration evidence;
- degraded-mode evidence;
- privacy exclusions confirmed;
- CloudKit status;
- known residual risks.
