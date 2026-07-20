# Waykin Current Capability Matrix

| Capability | Status | Authority | Agent action |
|---|---|---|---|
| Walking session | Implemented | Binding | Preserve and test |
| Movement integrity | Implemented | Binding | Do not change thresholds without scoped issue |
| Lira companion | Implemented | Binding | Extend only through approved states |
| Bond | Implemented | Binding | Require migration plan for schema or semantic changes |
| Bounded pursuit pressure | Implemented | Binding | Preserve safety constraints |
| Deterministic events | Implemented | Binding | Seeded reproducibility; companion-first defaultRules v1.1 |
| Semantic audio | Implemented | Binding | Core must not own filenames |
| Local persistence | Implemented | Binding | Make no cloud assumptions |
| Field-test receipts | Implemented | Binding | Preserve privacy filtering |
| AR semantic contracts | Implemented | Binding | Keep platform-neutral |
| AR app adapter (MVP) | **Implemented (frozen)** | Binding | Maintenance/defects only — see `AR_MVP_FREEZE.md` |
| Real-walk-to-AR commands | **Implemented** | Binding | Device tracking quality still requires evidence |
| Path progress (semantic) | **Implemented (v1.1+summary)** | Binding | Not navigation-grade |
| HealthKit read enrichment | **Implemented (v1.1+energy)** | Binding | Optional steps/distance read; Demo never blocked |
| HealthKit authorization/query hardening | **Planned** | Near term | Fix state semantics, race, provenance, refresh lifecycle, and device evidence |
| HealthKit workout writing | **Not implemented** | Reference | Requires explicit issue, write authorization, duplicate protection, and failure fallback |
| Apple Watch app target | **Not implemented** | Reference | No watchOS target or Watch UI may be claimed |
| Apple Watch workout session | **Not implemented** | Reference | Requires workout lifecycle, live builder, and paired-device evidence |
| Workout-session mirroring | **Not implemented** | Reference | Preserve iPhone gameplay authority and idempotent reconciliation |
| WatchConnectivity semantic sync | **Not implemented** | Reference | Non-authoritative state only; session ID + revision required |
| Live heart-rate/effort enrichment | **Not implemented** | Reference | Raw metrics may not directly select events or raise coercive pressure |
| Outdoor physical AR QA | Partial | Near term | Device evidence only (non-blocking) |
| AI Director | Deferred | Reference only | Do not implement |
| Experience Pack runtime | Deferred | Reference only | Preserve seam only |
| Backend/auth/cloud save | Deferred | Reference only | Do not implement |
| Multiplayer | Excluded | Binding | Do not implement |
| Marketplace/creator SDK | Excluded | Binding | Do not implement |
| Economy/LiveOps | Deferred | Reference only | Do not implement |
| Generative AI runtime | Excluded | Binding | Do not implement |