# Waykin AR Product Redesign Map

```yaml
document_id: WAYKIN-AR-PRODUCT-REDESIGN-MAP-001
version: 1.1
date: 2026-07-29
status: SUPPORTING_DESIGN_MAP
authority: SUPPORTING
maturity: NEAR_TERM
evidence_class: CODE_AND_DOC_AUDIT
does_not_override: [SOLO_MVP_SCOPE, WAYKIN_SPEC, AR_MVP_FREEZE]
recovered_from_pr: 245
recovered_on_main_base: 28bea09
companion_runtime: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
operator_intent: "No longer audio-first; design for AR"
north_star: docs/design/PRODUCT_VISION_NORTH_STAR.md
ladder: docs/canonical/MVP_TO_VISION_LADDER.md
constraint: "Respect current architecture; do not break the repo"
related:
  - docs/plans/AR_APP_REDESIGN_PLAN.md
  - docs/design/AR_SYSTEM_INVENTORY.md
  - docs/design/AR_SESSION_IA_CONFLICTS.md
  - docs/design/AR_MVP_FREEZE.md
  - docs/design/REAL_WALK_TO_AR_MAPPING.md
  - WAYKIN_SPEC.md
  - docs/SOLO_MVP_SCOPE.md
  - ARCHITECTURE.md
  - docs/canonical/CURRENT_CAPABILITY_MATRIX.md
  - docs/governance/DOCUMENT_AUTHORITY.md
```

## 0. North star vs this map

| Doc | Horizon |
| ---- | ------- |
| [`PRODUCT_VISION_NORTH_STAR.md`](PRODUCT_VISION_NORTH_STAR.md) | **Eventual:** AR companion on walks/runs/rides + fitness; worldbuilding; user-designed companions & experiences |
| [`../canonical/MVP_TO_VISION_LADDER.md`](../canonical/MVP_TO_VISION_LADDER.md) | Gated rungs R0–R8 from MVP → north star |
| **This map** | **Near-term only:** AR-designed **walk** MVP (R1), architecture-preserving |

This map is **chapter one**, not the full vision.

## 1. Purpose

This document **maps the entire AR product redesign space** for Waykin:

- what is already built
- what the architecture allows and forbids
- how product identity must change (audio-first → AR-designed)
- phased work that will not break Core isolation or freeze discipline
- which binding docs must be updated before agents treat AR-first as law

It does **not** by itself rewrite binding product law. Promotion of identity language still requires edits to `docs/SOLO_MVP_SCOPE.md` and `WAYKIN_SPEC.md` (see Phase 0 in the plan).

## 2. Operator decision (ratified for planning)

| Decision | Statement |
| -------- | --------- |
| Product direction | Waykin is **designed for AR** as the primary session surface |
| Deprecated identity | **Audio-first** is no longer the product genus |
| Architecture stance | Keep movement-first **gameplay authority**; AR remains **presentation** |
| Safety | Do not break Core isolation, freeze, determinism, or Pause/End |

**Proposed product line (for Phase 0 law PR):**

> Waykin is an **AR-designed adaptive walking experience**: one companion, Lira, meets you in the world as you walk. Movement is the game; AR, audio, map, and HUD are presentation channels — with **AR the primary designed surface** when the device allows.

## 3. Document authority (how this map sits)

Precedence (from `docs/governance/DOCUMENT_AUTHORITY.md`):

1. `docs/SOLO_MVP_SCOPE.md` — **BINDING**
2. `WAYKIN_SPEC.md` — **BINDING**
3. `README.md`
4. `ARCHITECTURE.md`
5. ADRs
6. … lower tiers …

This map and `docs/plans/AR_APP_REDESIGN_PLAN.md` are **SUPPORTING / NEAR_TERM**. They cannot silently override binding audio-first language until Phase 0 lands.

## 4. Whole-product map

```text
┌─────────────────────────────────────────────────────────────────┐
│                         WAYKIN PRODUCT                          │
│  Solo walk · one companion (Lira) · Bond · bounded pursuit      │
└───────────────────────────────┬─────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌─────────────────┐     ┌──────────────────┐
│  GAMEPLAY     │     │  SEMANTIC STATE │     │  PRESENTATION    │
│  AUTHORITY    │     │  (Core)         │     │  CHANNELS        │
│               │     │                 │     │                  │
│ MovementEngine│────▶│ WorldState      │────▶│ ★ AR (primary    │
│ Integrity     │     │ Events          │     │   design target) │
│ Session outcome│    │ CompanionRuntime│     │ Audio (support)  │
│ Bond / Memory │     │ Pursuit         │     │ 2D presence      │
│               │     │ Path progress   │     │ Map / HUD        │
│ NEVER owned   │     │ Presentation    │     │ Glasses glance   │
│ by AR/audio   │     │ Matrix          │     │ (flag-off)       │
└───────────────┘     └────────┬────────┘     └────────▲─────────┘
                               │                       │
                               │  ARWorldCommand       │
                               │  SpatialIntent        │
                               └───────────────────────┘
                                 App AR adapter only
```

### 4.1 Identity transition

| Layer | Historical (shipped docs) | Target (AR-designed) |
| ----- | ------------------------- | -------------------- |
| Genus | Audio-first walking app | **AR-designed** walking companion |
| Primary session surface | 2D presence; AR optional cover | **AR canvas when available** |
| Audio | Product identity | Required **supporting** channel (pocket, eyes-up, a11y) |
| Map / path | Secondary | Secondary spatial support |
| Gameplay truth | Movement | **Unchanged: movement** |

## 5. Architecture map (do not break)

### 5.1 Runtime flow (OBSERVED)

```text
Core Location sample / Demo tick
      ↓
MovementIntegrityProcessor (real only)
      ↓
MovementEngine → MovementSnapshot
      ↓
CompanionWalkExperience
      ├─ WorldState
      ├─ WorldEventGenerator → WorldEvent? (0–1 / tick)
      ├─ CompanionPresentationMatrix → behavior + distance + AR string
      ├─ AudioExperienceLayer (event → behavior → AR-presentation → path soft)
      └─ ExperienceUpdate commands / semanticAudioCues
      ↓
WaykinAppModel
      ├─ CompanionRuntime apply
      ├─ PathProgressEngine
      ├─ AppAudioCuePlayer
      ├─ Session map presentation
      └─ CanonicalARWorldCommandMapper → [ARWorldCommand]
            ↓ (only if handler attached)
      CanonicalARSessionRuntime / ARWorldCommandRenderer
            ↓
      RealityKit (world plant + continuity re-plant)
```

### 5.2 Boundary law

| May | Must not |
| --- | -------- |
| Core emit semantic state + matrix strings | Core import ARKit / RealityKit / MapKit / filenames |
| App map state → `ARWorldCommand` | AR select events, accept GPS, change Bond, write memories |
| Tracking gate AR UI quality | Tracking invent walk / world truth |
| Audio + AR + 2D share matrix | Divergent behavior vocabularies per surface |
| Degrade AR on limited tracking | Fail Pause/End or block safety |

### 5.3 Placement policy (ratified #125)

| Rule | Detail |
| ---- | ------ |
| Default | World-plane plant (ground raycast → `AnchorEntity`) |
| Fallback | Camera-anchor if raycast fails |
| Continuity | Re-plant if missing / detached / > ~6 m from camera |
| `.follow` | Local pose only — **not** continuous walker re-anchor |
| Expansion | Continuous escort requires **new product issue + ADR** |

## 6. System inventory (index)

Full file-level inventory: [`AR_SYSTEM_INVENTORY.md`](AR_SYSTEM_INVENTORY.md).

| Subsystem | Location | Status |
| --------- | -------- | ------ |
| AR contracts | `Sources/WaykinCore/Presentation/` | Binding semantics |
| Presentation matrix | `Sources/WaykinCore/Engines/CompanionPresentationMatrix.swift` | Shared authority |
| Walk experience | `Sources/WaykinCore/Experiences/` | No AR commands |
| Command mapper | `App/AR/CanonicalARWorldCommandMapper.swift` | Demo + real |
| AR session UI | `App/AR/CanonicalARSessionView.swift` | fullScreenCover |
| Renderer / plant | `App/AR/ARWorldCommandRenderer.swift`, `ARPlacementResolver.swift` | Frozen MVP |
| Mesh / skeletal | `App/AR/Companion/*` | Mid-LOD + fallback |
| Orchestration | `App/WaykinApp.swift` (`WaykinAppModel`) | Attach/detach handler |
| 2D presence | `App/CompanionPresenceView.swift` | Fallback / chrome |
| Map | `App/SessionMapViews.swift` | Semantic, not nav |
| Audio adapter | `App/AppAudioCuePlayer.swift` | Filenames + session |
| Freeze contract | `docs/design/AR_MVP_FREEZE.md` | Maintenance-only |
| Walk→AR map | `docs/design/REAL_WALK_TO_AR_MAPPING.md` | OBSERVED |

## 7. Capability matrix slice (AR-relevant)

From `docs/canonical/CURRENT_CAPABILITY_MATRIX.md`:

| Capability | Status | Redesign note |
| ---------- | ------ | ------------- |
| Semantic audio | Implemented | Keep as supporting channel |
| AR semantic contracts | Implemented | Keep |
| AR app adapter (MVP) | **Implemented (frozen)** | Unfreeze only by issue |
| Real-walk→AR commands | Implemented | Keep spine |
| Path progress | Implemented | HUD / soft coupling |
| Outdoor physical AR QA | **Partial** | Gate marketing claims (#41) |
| Glasses glance | Flag-off | Not AR-product core |
| Multiplayer / marketplace / AR gameplay | Excluded | Still excluded |

## 8. Freeze rings (redesign envelope)

```text
RING A — Safe without freeze lift
  Docs identity, agent context, comments, evidence collection,
  outdoor re-walk, UX copy, fallback messaging

RING B — Controlled unfreeze (named issue)
  Session-default AR, entry flow, chrome/HUD in AR,
  degraded-tracking UX, placement coach marks
  Still: commands-only, no new gameplay, no Core ARKit

RING C — Architecture change (ADR + scope rewrite)
  Continuous walker re-anchor, AR-owned mechanics,
  multi-entity world sim, glasses-required product
  → high break risk; not required for “AR app” v1
```

**Default path:** Ring A → evidence → Ring B. Avoid Ring C.

## 9. Target session IA (AR-designed)

```text
Home
  ├─ Begin Walk (REAL — primary)
  ├─ Demo Walk (secondary)
  ├─ Memory / Settings
  └─ …

Active Session
  ├─ ★ PRIMARY: AR canvas (when capability available + authorized)
  │     Lira world-planted · discovery/threat · mirrored Pause/End
  ├─ SECONDARY: compact HUD (Bond, path phrase, pressure, continuity)
  ├─ TERTIARY: semantic audio (policy-on for walks)
  └─ FALLBACK: 2D presence ± map (camera denied / unsupported / user choice)

Session Summary → Memory → Home
```

### Capability fallback table

| Capability state | Default surface |
| ---------------- | --------------- |
| `available` / `active` | AR primary |
| `trackingLimited` | AR degraded + continuity HUD; no gameplay change |
| `cameraDenied` / `unsupported` | 2D presence primary + clear copy |
| Demo, no camera | 2D + audio; AR if device allows |

## 10. Conflict map

| Conflict | Severity | Resolution owner |
| -------- | -------- | ---------------- |
| Binding **audio-first** vs AR design intent | High | Phase 0 binding docs |
| **AR MVP freeze** vs redesign work | High | Ring A vs issue-scoped Ring B |
| UIUX “presence OR AR not both animating” | Med | Keep; AR cover replaces active 2D animation |
| Outdoor PARTIAL vs AR marketing | High | #41 before PASS claims |
| Skills `REPO_CONTEXT` audio-first | Med | Phase 0 agent pack |
| Continuous follow expectation vs world-plant | Med | Product education + optional later ADR |

## 11. Binding doc delta map (Phase 0)

| Document | Today | Target edit |
| -------- | ----- | ----------- |
| `docs/SOLO_MVP_SCOPE.md` | audio-first promise; audio-only presentation path | AR-designed promise; multi-channel presentation with AR primary design target |
| `WAYKIN_SPEC.md` | audio-first contract; AR as #8 | AR-designed contract; AR presentation elevated; audio remains MVP system |
| `README.md` | “audio-first” hero | AR-designed hero + pillars |
| `ARCHITECTURE.md` | neutral / audio-centric narration | Presentation stack: AR primary design target |
| `docs/legal/TERMS.md` | audio-first experience | Match product line |
| `skills/**/REPO_CONTEXT.md` | Audio-first walking companion | AR-designed walking companion |
| `docs/design/AR_MVP_FREEZE.md` | freeze only | Add pointer to this map + unfreeze process |
| Design art docs `audio_first: true` | YAML flags | Historical or update to `ar_designed: true` |

## 12. Test & evidence map

| Proof | Suite / artifact | Guards |
| ----- | ---------------- | ------ |
| Command bridge | `CanonicalARRuntimeIntegrationTests`, real movement handler tests | Mapper lifecycle |
| Determinism | `ARCommandReplaySoakTests` | No wall-clock in core tests |
| Core isolation | `scripts/check_core_framework_isolation.sh` | No ARKit in Core |
| Outdoor AR | #41 + outdoor receipts | Continuity / thermal / battery |
| UI safety | UIUX #126 | Pause/End in AR cover |
| Validate | `make build && make test && make validate` | Repo health |

## 13. Explicit non-goals (redesign v1)

- RealityKit **gameplay** (combat, physics puzzles as authority)
- Multi-companion AR
- Marketplace / UGC assets
- Mandatory AR glasses
- Cloud / multiplayer
- Continuous walker re-anchor without ADR
- Dropping semantic audio entirely
- Importing AR frameworks into `WaykinCore`
- Claiming outdoor AR PASS from simulator alone

## 13b. Session IA conflicts (summary)

Active Session today is **2D-rooted** with AR as optional cover. AR-designed product inverts root/fallback. Full register: [`AR_SESSION_IA_CONFLICTS.md`](AR_SESSION_IA_CONFLICTS.md) (C1–C11: law vs tree, exclusive Lira, dual covers, a11y spine, pocket vs eyes-up, authority deadlock).

## 14. Related documents (full web)

| Topic | Doc |
| ----- | --- |
| Phased execution | [`../plans/AR_APP_REDESIGN_PLAN.md`](../plans/AR_APP_REDESIGN_PLAN.md) |
| File inventory | [`AR_SYSTEM_INVENTORY.md`](AR_SYSTEM_INVENTORY.md) |
| Session IA conflicts | [`AR_SESSION_IA_CONFLICTS.md`](AR_SESSION_IA_CONFLICTS.md) |
| North star vision | [`PRODUCT_VISION_NORTH_STAR.md`](PRODUCT_VISION_NORTH_STAR.md) |
| MVP → vision ladder | [`../canonical/MVP_TO_VISION_LADDER.md`](../canonical/MVP_TO_VISION_LADDER.md) |
| Freeze | [`AR_MVP_FREEZE.md`](AR_MVP_FREEZE.md) |
| Walk→AR | [`REAL_WALK_TO_AR_MAPPING.md`](REAL_WALK_TO_AR_MAPPING.md) |
| UI modality | [`WAYKIN_UIUX_SPEC.md`](WAYKIN_UIUX_SPEC.md) |
| Art / mesh | [`LIRA_AR_PRODUCTION_RIG.md`](LIRA_AR_PRODUCTION_RIG.md), [`LIRA_AR_SCULPT_PLAN.md`](LIRA_AR_SCULPT_PLAN.md) |
| Outdoor | [`OUTDOOR_QA_CHECKLIST.md`](OUTDOOR_QA_CHECKLIST.md), [`CONTINUATION_PLAN.md`](CONTINUATION_PLAN.md) |
| Path | [`PATHFINDING.md`](PATHFINDING.md) |
| Audio contract | [`../AUDIO_ASSET_CONTRACT.md`](../AUDIO_ASSET_CONTRACT.md) |
| Capability truth | [`../canonical/CURRENT_CAPABILITY_MATRIX.md`](../canonical/CURRENT_CAPABILITY_MATRIX.md) |

## 15. Claim labels (audit residue)

| Label | Claim |
| ----- | ----- |
| OBSERVED | AR command spine, freeze, optional fullScreenCover entry, audio-first binding language |
| INFERRED | Product feels multi-modal; audio-first under-describes ship |
| NOT_COMPUTABLE | Whether session-default AR will increase return intent (needs outdoor/device product evidence; not inventable) |
| NOT_COMPUTABLE | Outdoor AR quality PASS until #41 re-walk |

## 16. Change control

- Product-intent changes (identity, default modality) → binding docs first, then agents, then UX.
- `App/AR/**` feature work → cite freeze exception issue.
- Placement model change → ADR.
- Any Core boundary change → isolation script + architecture review.

---

*End of map v1.0 — supports planning only until Phase 0 binding promotion.*
