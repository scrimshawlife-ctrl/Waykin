# Waykin Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 0.3
date: 2026-07-19
status: ACTIVE
goal: freeze_AR_slice_then_pathfinding_and_healthkit
outdoor_qa: DEFERRED_NOT_BLOCKING_ENGINEERING
audio_first: true
```

## Product intent

Finish **AR presentation** well enough that it is a **stable, isolated adapter**, then shift engineering capacity to:

1. **Pathfinding / route semantics** (walking path, not navigation-grade map app)
2. **HealthKit** (movement/health signals as session inputs — scoped, privacy-safe)

AR must not keep expanding into art polish or outdoor QA before those cores ship.

## Where AR is now (enough to freeze for MVP engineering)

| Layer | Status | Notes |
| ----- | ------ | ----- |
| Session 2D stills 7×3 + glyphs | **DIRECTION_ACCEPTED** | Home + walk presence |
| Still motion (crossfade, bond orbit, manifest, hunter echo) | **Done indoor** | C1–C4 + polish |
| AR procedural Living Familiar | **Shipped** | Permanent fallback |
| USDZ package + async load + skin remap | **Shipped** | Mid-LOD spheres; not hero sculpt |
| AR skins Dawn/Veil/Rupture | **Shipped** | Materials only |
| Command replay / soak (#46) | **Done** | Deterministic sim evidence |
| Canonical runtime → AR commands (#42) | **Done** | Core isolation held |
| Outdoor / physical AR (#41) | **NOT_COMPUTABLE** | Device only; **do not block** pathfinding/HK |

**Recommendation:** Treat AR as **MVP-complete for engineering** after the short **AR Freeze** wave below. Optional art upgrade and outdoor AR stay parallel/later.

## Recommended waves

### Wave AR-F — AR Freeze (do this first, ~1–3 PRs)

Goal: **seal the AR adapter** so pathfinding/HK work cannot be derailed by open AR todos.

| ID | Work | Exit criteria | Est. |
| -- | ---- | ------------- | ---- |
| **AR-F1** | **AR freeze doc** — declare MVP AR contract: surfaces, non-goals, frozen paths | `docs/design/AR_MVP_FREEZE.md` + capability matrix update | Small |
| **AR-F2** | **LOD proof** — assert packaged USDZ preloads in sim when present; LOD label stable; fallback still works if load fails | Unit/UI tests green; receipt note | Small |
| **AR-F3** | **Real-walk command bridge check** — confirm live walk already maps to AR commands (or stub gap list only) | Doc: “what AR receives on real walk” with OBSERVED sim / code paths; **no new AR features** | Small–med |
| **AR-F4** | **Boundary tests** — freeze: WaykinCore has no RealityKit; AR does not own path/HK | Existing isolation + 1–2 focused tests if gaps | Small |

**Do not do in AR-F:** hand-sculpt mesh, AnimationLibrary, outdoor QA, new poses, multiplayer AR.

**AR freeze definition of done**

- [ ] Presentation-only companion in AR (spawn/update/clear, skins, motion loops)
- [ ] USDZ optional with procedural fallback
- [ ] Replay/soak remain green
- [ ] Explicit list of AR non-goals (outdoor, glasses, multi-companion)
- [ ] ACTIVE_WORK: AR presentation → Complete / maintenance-only

### Wave P — Pathfinding (after AR-F)

Align with existing contracts: route is **measurement support for Companion Walk**, not turn-by-turn navigation (`KNOWN_LIMITATIONS`, `MOVEMENT_INTEGRITY_CONTRACT`).

| ID | Work | Notes |
| -- | ---- | ----- |
| **P0** | **Scope ADR / issue** | Pathfinding = path integrity + progress along a walk, **not** Google Maps clone |
| **P1** | **Core model** | Path segment / progress / off-path pressure as **semantic state** in WaykinCore (platform-neutral) |
| **P2** | **Integrity hooks** | Tie to accepted GPS samples only; no invalid samples affect path state |
| **P3** | **Demo Mode** | Deterministic path progress without location permission |
| **P4** | **Presentation** | Audio + Lira pose lean only (guide/rival/hunter); no map chrome expansion |
| **P5** | **Receipts** | Sparse path diagnostics without storing full route geometry for privacy |

**Frozen while P runs:** AR mesh art, outdoor AR claims, marketplace.

### Wave H — HealthKit (after P0 at least; can parallel P late if owners split)

| ID | Work | Notes |
| -- | ---- | ----- |
| **H0** | **Scope + privacy** | What we read (steps, walking distance, workout?); Info.plist; no write unless required |
| **H1** | **Adapter boundary** | `HealthKit` only in App; Core receives **semantic samples** (e.g. cadence band, active energy bucket) |
| **H2** | **Session coupling** | Optional enrichment of real walk; never required for Demo Mode |
| **H3** | **Authorization UX** | Deny → silent degrade; no blocked Begin Walk demo |
| **H4** | **Receipts** | Coarse counts only; no raw HealthKit identifiers dumped |
| **H5** | **Tests** | Fake provider in AppTests; no device required for CI |

**Do not:** medical claims, background delivery v1 unless proven needed, multi-day history product.

### Wave D — Device evidence (parallel, non-blocking)

| ID | Work | Blocks? |
| -- | ---- | ------- |
| **D1** | Outdoor QA receipt | **No** — product polish / marketing only |
| **D2** | Physical AR (#41) | **No** — engineering can proceed with sim + freeze |
| **D3** | Field-test protocol walks | **No** — feeds P/H evidence later |

## Explicit sequencing

```text
AR-F (freeze adapter)
    │
    ├─► P0–P5 Pathfinding (primary next engineering)
    │       │
    │       └─► H0–H5 HealthKit (after P0 privacy/scope; prefer after P2)
    │
    └─► D* outdoor/device AR (anytime you have a phone; never blocks P/H)
```

## Path isolation (protect the freeze)

| Workstream | Allowed | Frozen |
| ---------- | ------- | ------ |
| AR-F | `App/AR/**`, AR docs/tests, capability matrix | WaykinCore gameplay, HealthKit, path algorithms |
| Pathfinding | `Sources/WaykinCore/**` path/movement, focused App wiring, docs | AR mesh/USDZ art, HealthKit details |
| HealthKit | `App/**` Health adapter, plist, AppTests fakes | WaykinCore importing HealthKit |

## What “complete AR” means here

**Yes — complete for unblocking pathfinding/HK:**

- Companion can appear in AR during a session
- Skins + mid-LOD (USDZ or procedural)
- Deterministic command path + soak
- Indoor motion good enough
- Documented freeze so AR is maintenance-only

**No — not required to start pathfinding/HK:**

- Hand-sculpted hero mesh
- Skeletal AnimationLibrary
- Outdoor AR tracking receipt
- Perfect visual parity with stills

## Immediate next actions (recommended)

1. **AR-F1** — write `AR_MVP_FREEZE.md` + mark AR presentation complete in capability matrix / ACTIVE_WORK  
2. **AR-F2** — confirm USDZ LOD path in one focused test/receipt (if not already solid on main)  
3. **AR-F3** — one short doc: real-walk → `ARWorldCommand` mapping gaps (list only; no feature creep)  
4. Open **Issue P0** pathfinding scope  
5. Open **Issue H0** HealthKit privacy/scope (can draft in parallel with P0)

## Related

- [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md)
- [LIRA_ANIMATION_PLAN.md](LIRA_ANIMATION_PLAN.md)
- [AR_REPLAY_VALIDATION.md](../AR_REPLAY_VALIDATION.md)
- [MOVEMENT_INTEGRITY_CONTRACT.md](../MOVEMENT_INTEGRITY_CONTRACT.md)
- [KNOWN_LIMITATIONS.md](../../KNOWN_LIMITATIONS.md)
- [canonical/CURRENT_CAPABILITY_MATRIX.md](../canonical/CURRENT_CAPABILITY_MATRIX.md)
