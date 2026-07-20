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
| HealthKit read enrichment | **Implemented (v1.1 hardened)** | Binding | Optional step-volume + distance; Demo never blocked |
| HealthKit authorization/query hardening | **Implemented (#104)** | Binding | requestCompleted + metric availability + ordered refresh; device evidence still NOT_COMPUTABLE |
| HealthKit workout writing | Deferred | Reference only | Requires explicit issue, write authorization, duplicate protection, and failure fallback |
| Apple Watch app target | Deferred | Reference only | No watchOS target or Watch UI may be claimed |
| Apple Watch workout session | Deferred | Reference only | Requires workout lifecycle, live builder, and paired-device evidence |
| Workout-session mirroring | Deferred | Reference only | Preserve iPhone gameplay authority and idempotent reconciliation |
| WatchConnectivity semantic sync | Deferred | Reference only | Non-authoritative state only; session ID + revision required |
| Live heart-rate/effort enrichment | Deferred | Reference only | Raw metrics may not directly select events or raise coercive pressure |
| Outdoor physical AR QA | Partial | Near term | Device evidence only (non-blocking) |
| Conversation Director | **Release candidate** | Reference only | Define provider-neutral contracts and evidence gate before implementation |
| Pathfinder Director | **Release candidate** | Reference only | AI proposes route intent only; authoritative routing remains outside the model |
| Grok provider adapter | Candidate | Reference only | Replaceable adapter; no hard-coded dependency or direct state mutation |
| Generalized autonomous world director | Deferred | Reference only | Do not implement from planning references |
| AI-owned gameplay state | Excluded | Binding | Prohibited |
| Experience Pack runtime | Deferred | Reference only | Preserve seam only |
| Backend/auth/cloud save | Deferred | Reference only | Do not implement |
| Multiplayer | Excluded | Binding | Do not implement |
| Marketplace/creator SDK | Excluded | Binding | Do not implement |
| Economy/LiveOps | Deferred | Reference only | Do not implement |
| Generative AI required for canonical loop | Excluded | Binding | Deterministic and offline fallback behavior is mandatory |