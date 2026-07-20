# Waykin Persistence Architecture

## Status

- Decision: `SWIFTDATA_LOCAL_FIRST`
- Scope: iPhone solo-MVP and release-candidate hardening
- Cloud sync: deferred pending an explicit product requirement
- Backend services: out of MVP scope

## Goals

Waykin persistence must remain local-first, offline-capable, privacy-preserving, deterministic, and implementable by one developer. Durable storage supports concise user state and completed-session records. It does not become an alternate gameplay authority, telemetry lake, generalized content backend, or account platform.

## Canonical Storage Map

| Data | Canonical storage |
|---|---|
| Lira identity, Bond, durable session summaries, concise memories | SwiftData |
| Onboarding, appearance, cosmetic selection, other small preferences | UserDefaults / AppStorage |
| Field-test receipts and exportable diagnostic evidence | Atomic JSON in Application Support |
| Reconstructable or downloaded assets | Caches |
| Future credentials or provider secrets | Keychain |
| Raw movement samples, route geometry, AR transforms, transient world state | Memory only by default |
| HealthKit source records | HealthKit; persist only minimal derived Waykin summaries when approved |

## Canonical Runtime Boundary

```text
WaykinCore domain state
        ↓
Persistence repository protocols
        ↓
SwiftData persistence actor
        ↓
Versioned SwiftData schema
        ↓
Application Support / Waykin / Waykin.store
```

WaykinCore domain models and engines remain free of SwiftData annotations and imports. SwiftData is an app infrastructure adapter behind narrow persistence contracts.

## Current State

The repository currently persists `CompanionRecord` and `SessionMemoryRecord` through SwiftData. Field-test receipts are intentionally separate bounded JSON artifacts. User interface preferences are stored through UserDefaults. Reopen tests verify that Bond and memories survive reconstruction of a file-backed container.

## Required Hardening

### Schema versioning

Establish `WaykinSchemaV1: VersionedSchema` and a `WaykinMigrationPlan` before public users accumulate mutable durable data. All production and test container construction must route through one factory.

### Failure visibility

Production persistence initialization failures must not silently substitute an ambiguous store while claiming durable operation. The app may continue in an explicitly degraded mode, but durable writes must fail visibly and produce privacy-safe diagnostics.

### Deterministic identity

The canonical Lira record must be fetched by a stable identifier or through one canonical app-state pointer. Unsorted fetch ordering is not a semantic selector.

### Idempotent completion writes

`sessionID` is the durable completion idempotency key. The database schema must enforce one canonical memory or summary per completed session, not rely only on a fetch-then-insert check.

### Serialized database authority

SwiftData reads and writes should execute through a `ModelActor` implementation so persistence has one serialized authority and can later support background completion, Watch messages, or CloudKit without changing domain engines.

## Repository Contracts

Recommended contracts:

```swift
public protocol CompanionRepository: Sendable {
    func loadCanonicalCompanion() async throws -> Companion?
    func saveCompanion(_ companion: Companion) async throws
}

public protocol SessionMemoryRepository: Sendable {
    func saveMemory(_ memory: SessionMemory) async throws
    func memory(for sessionID: UUID) async throws -> SessionMemory?
    func recentMemories(limit: Int) async throws -> [SessionMemory]
    func memoryCount() async throws -> Int
}
```

Test doubles should implement the same contracts without requiring SwiftData.

## Durable Session Aggregate

Persist concise structured facts at successful session completion:

- session identifier
- scenario or walk mode
- start and completion timestamps
- active duration
- accepted distance
- completion reason
- Bond before and after
- concise memory text

Do not persist raw GPS samples, full route geometry, every event tick, audio playback history, HealthKit samples, AR anchors, or renderer transforms as ordinary product data.

## Retention

- Companion and Bond: retained until explicit reset.
- Session summaries and memories: retained locally; any future cap requires a product decision and migration path.
- Field receipts: existing bounded retention remains separate.
- Raw movement and health enrichment: session lifetime unless explicitly promoted as a minimal derived summary.
- Reconstructable assets: cache semantics.

## Migration and Recovery Requirements

The persistence suite must cover:

- store reopen across process reconstruction
- seeded previous-schema migration
- explicit degraded state on initialization or migration failure
- duplicate session completion through independent tasks or contexts
- interrupted-write idempotency
- deterministic companion retrieval
- production/test store isolation
- explicit reset behavior
- receipt-file separation
- corruption recovery that never silently destroys user data

## CloudKit Promotion Gate

CloudKit remains deferred until an approved requirement exists, such as multi-device Bond/history continuity, reinstall recovery, independent durable Watch writes, account-backed personalization, or support-visible server state. Promotion requires a separate ADR covering conflict policy, deletion propagation, entitlements, privacy, offline states, migration, and device evidence.

## Explicit Non-Goals

- Firebase
- Supabase
- Realm migration
- custom REST backend
- user accounts for MVP
- network dependency for completing a walk
- persistent raw telemetry
- persistent route history by default
- persistent AR world state
- immediate CloudKit adoption
