# Waykin Current Capability Matrix

| Capability | Status | Authority | Agent action |
|---|---|---|---|
| Walking session | Implemented | Binding | Preserve and test |
| Movement integrity | Implemented | Binding | Do not change thresholds without scoped issue |
| Lira companion | Implemented | Binding | Extend only through approved states |
| Bond | Implemented | Binding | Require migration plan for schema or semantic changes |
| Bounded pursuit pressure | Implemented | Binding | Preserve safety constraints; real-walk pressure curve from PR #248 is gameplay tuning only |
| Deterministic events | Implemented | Binding | Seeded reproducibility; companion-first defaultRules v1.1 |
| Semantic audio | Implemented | Binding | Core must not own filenames |
| Local persistence | Implemented | Binding | Make no cloud assumptions |
| Field-test receipts | Implemented | Binding | Preserve privacy filtering |
| AR semantic contracts | Implemented | Binding | Keep platform-neutral |
| AR app adapter (MVP) | **Implemented (frozen)** | Binding | Maintenance/defects only — see `AR_MVP_FREEZE.md` |
| Packaged companion mesh (Ember Fox) | **Implemented** | Binding | PR #246; do not re-import/replace without asset issue; #242/#243 superseded |
| Mesh async load + procedural fallback + live replace | **Implemented** | Binding | Authored asset must replace fallback; single companion anchor |
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
| Outdoor physical AR QA | Partial | Binding evidence | PARTIAL receipt 2026-07-20 (historical pre-mesh); full PASS requires #41 re-walk on **current** tip SHA |
| Indoor Ember Fox device smoke | Pending device | Binding evidence | Mesh may render on device; outdoor tracking/thermal still incomplete without receipts |
| Glasses glance adapter | Implemented (flag default off) | Supporting | Mock/transport; physical glasses NOT_COMPUTABLE |
| Companion presentation matrix | Implemented | Binding | Shared behavior/distance/AR string authority |
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

## Runtime identity snapshot (non-binding convenience)

| Field | Value |
| --- | --- |
| Documented `main` tip at last matrix refresh | `7df3a169ede507ce54469330318f66c4603f8c3d` |
| Companion package | Ember Fox USDZ (`MESHY_EMBER_FOX_WALK_V1`) |
| Mesh authority | PR #246 |
| Superseded mesh PRs | #242, #243 (closed) |
| Retired default package | Artist-blend / DCC mid-LOD (`ARTIST_BLEND_HERO_DCC_MID_LOD`) |
| Live coordination | `docs/collaboration/ACTIVE_WORK.md` |
