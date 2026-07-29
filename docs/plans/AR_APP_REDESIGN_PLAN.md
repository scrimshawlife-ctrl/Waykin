# Waykin AR App Redesign Plan

```yaml
document_id: WAYKIN-AR-APP-REDESIGN-PLAN-001
version: 1.0
date: 2026-07-29
status: SUPPORTING_PLAN
authority: SUPPORTING
parent_map: docs/design/AR_PRODUCT_REDESIGN_MAP.md
inventory: docs/design/AR_SYSTEM_INVENTORY.md
constraint: "Do not break Core isolation, freeze discipline, determinism, or safety controls"
```

## Goal

Redesign Waykin as an **AR-designed walking companion app** while **preserving** the existing architecture:

- movement = gameplay authority  
- `ARWorldCommand` = presentation boundary  
- single companion, Bond, bounded pursuit  
- solo local MVP  

## Non-goals

- RealityKit gameplay authority  
- Multi-companion / marketplace  
- Continuous walker re-anchor without ADR  
- ARKit inside `WaykinCore`  
- Dropping semantic audio  
- Outdoor quality claims without #41 PASS  

## Phase overview

| Phase | Name | Break risk | Freeze lift? | Binding law change? |
| ----- | ---- | ---------- | ------------ | ------------------- |
| **0** | Product law & agent context | Low | No | **Yes** |
| **1** | Evidence (#41, sim regression) | Low | No | No |
| **2** | AR-default session UX | Med | **Issue-scoped** | No (uses Phase 0 law) |
| **3** | Controlled AR polish unfreeze | Med | Named items only | Only if placement policy changes |
| **4** | Optional architecture expansions | High | ADR required | Yes |

---

## Phase 0 — Product law (docs / agents only)

**Objective:** Make “AR-designed” the written product contract so humans and agents stop optimizing for audio-first identity.

### Work items

| ID | Task | Files |
| -- | ---- | ----- |
| P0.1 | Rewrite product promise | `docs/SOLO_MVP_SCOPE.md` |
| P0.2 | Rewrite product contract + MVP systems narrative | `WAYKIN_SPEC.md` |
| P0.3 | Hero + pillars | `README.md` |
| P0.4 | Presentation stack narrative | `ARCHITECTURE.md` (intro / primary systems) |
| P0.5 | User-facing terms | `docs/legal/TERMS.md` |
| P0.6 | Agent pack one-liner | `skills/**/references/REPO_CONTEXT.md`, `.grok/skills/**/REPO_CONTEXT.md` |
| P0.7 | Audio skill wording | `skills/waykin-audio/SKILL.md` — audio = channel not genus |
| P0.8 | Pointer from freeze + continuation | `AR_MVP_FREEZE.md`, `CONTINUATION_PLAN.md` → this plan + map |
| P0.9 | Design YAML flags | e.g. `LIRA_ANIMATION_PLAN.md` `audio_first` → document historical / `ar_designed` |
| P0.10 | Code comments only | `AppAudioCuePlayer.swift`, `project.yml` — “pocket-safe audio” not “product is audio-first” |

### Acceptance

```bash
# After Phase 0, product-identity hits should be gone or historical:
rg -n -i 'audio-first|audio first' --glob '!**/receipts/**' 
# Allowed: historical ADR notes, "PRIOR", or pocket-audio reliability wording clearly not product genus
```

- Document authority order unchanged  
- No Swift behavior change required in Phase 0  
- `make validate` still green if code comments-only  

### Exit criteria

Binding docs no longer define Waykin as audio-first; AR is primary **designed** session surface; audio remains a required **supporting** presentation system.

---

## Phase 1 — Evidence (no feature expansion)

**Objective:** Prove AR quality claims are honest before UX defaults hard to AR.

| ID | Task | Evidence |
| -- | ---- | -------- |
| P1.1 | Keep integration/soak tests green on tip | CI / local `make test` |
| P1.2 | Indoor AR smoke human receipt | `INDOOR_AR_HYBRID_SMOKE.md` |
| P1.3 | Outdoor #41 re-walk COH | Outdoor receipt on tip SHA |
| P1.4 | Continuity notes reviewed | `ok_present` / re-plant rates |

### Exit criteria

- No new outdoor PASS claim without receipt  
- Failures filed as defects (freeze allows defects)  

---

## Phase 2 — AR-default session UX (Ring B)

**Objective:** Product *feels* like an AR app when the device can do AR.

**Requires:** Phase 0 merged + GitHub issue unfreezing **UX-only** items (not new mechanics).

**IA conflicts to close:** [`../design/AR_SESSION_IA_CONFLICTS.md`](../design/AR_SESSION_IA_CONFLICTS.md) (especially C2 exclusive Lira, C3 session root, C4 map modality, C9 fallback).

| ID | Task | Constraint |
| -- | ---- | ---------- |
| P2.1 | Default present AR when capability available at walk start (or stronger primary CTA) | Mirrored Pause/End; no swipe-dismiss trap (#126) |
| P2.2 | First-class fallback when camera denied/unsupported | 2D presence + copy; walk still succeeds |
| P2.3 | Compact HUD over AR | Bond, path phrase, pressure, continuity — presentation only |
| P2.4 | Entry flow polish | Settings / permission / re-open AR |
| P2.5 | Demo parity | Deterministic; AR optional if no camera in sim |

### Acceptance

- Walk completable without AR  
- Walk with AR: spawn/update/clear still via mapper  
- Isolation script pass  
- No new `ARWorldCommand` cases unless separate issue  
- UI change receipt if material (`UI_CHANGE_VALIDATION_RECEIPT.md`)  

### Exit criteria

Capability-available devices land in AR as the normal active session; fallback path documented and tested.

---

## Phase 3 — Controlled AR polish (optional)

Only after Phase 2, still presentation-only:

| ID | Examples | Still forbidden |
| -- | -------- | --------------- |
| P3.1 | Placement coach marks | Gameplay hooks |
| P3.2 | Degraded-tracking UX copy/visuals | Tracking as truth |
| P3.3 | Art package swaps per #220 process | Hero-only runtime without issue |
| P3.4 | Performance LOD tuning | New companion mechanics |

Each item needs its own issue citing `AR_MVP_FREEZE.md` exception scope.

---

## Phase 4 — Architecture expansions (optional, high risk)

**Do not schedule by default.** Requires ADR + binding scope edit.

| Candidate | Why risky |
| --------- | --------- |
| Continuous walker re-anchor | Contradicts #125 world-plant decision |
| AR-owned encounter logic | Breaks presentation≠gameplay |
| Multi-entity environment sim | Scope + freeze |
| Glasses-required mode | Explicit non-goal today |

---

## Dependency graph

```text
Phase 0 (law)
    │
    ▼
Phase 1 (evidence) ── parallel with early design mocks
    │
    ▼
Phase 2 issue filed (UX unfreeze scope)
    │
    ▼
Phase 2 implementation PRs (small, testable)
    │
    ▼
Phase 3 optional polish issues
    │
    ▼
Phase 4 only if product ratifies
```

## PR slicing rules (don’t break the repo)

1. **One concern per PR** (law vs UX vs mesh vs evidence).  
2. **No Core AR imports** — enforced by isolation script.  
3. **Prefer adapter/UX changes** over experience rewrites.  
4. **Keep Demo CI-green** without camera.  
5. **Cite freeze issue** on any `App/AR/**` feature diff.  
6. **Update map/plan version** when phases complete.

## Rollback

| If | Then |
| -- | ---- |
| Phase 0 confuses external readers | Revert docs PR; map remains historical |
| Phase 2 harms completion rate | Feature-flag default AR; keep optional cover |
| Continuity regresses outdoors | Defect fix under freeze; disable default AR |

## Success metrics (product)

| Metric | Signal |
| ------ | ------ |
| Identity coherence | Binding docs + README + skills agree |
| AR-native feel | Capability-available sessions open AR by default (Phase 2) |
| Architecture integrity | Isolation + soak + no gameplay-from-tracking |
| Honesty | Outdoor claims match receipts |

## References

- Map: [`../design/AR_PRODUCT_REDESIGN_MAP.md`](../design/AR_PRODUCT_REDESIGN_MAP.md)  
- Inventory: [`../design/AR_SYSTEM_INVENTORY.md`](../design/AR_SYSTEM_INVENTORY.md)
- Session IA conflicts: [`../design/AR_SESSION_IA_CONFLICTS.md`](../design/AR_SESSION_IA_CONFLICTS.md)  
- Freeze: [`../design/AR_MVP_FREEZE.md`](../design/AR_MVP_FREEZE.md)  
- Walk mapping: [`../design/REAL_WALK_TO_AR_MAPPING.md`](../design/REAL_WALK_TO_AR_MAPPING.md)  
- UIUX: [`../design/WAYKIN_UIUX_SPEC.md`](../design/WAYKIN_UIUX_SPEC.md)  
