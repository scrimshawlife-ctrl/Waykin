# Waykin Design Continuation Plan

```yaml
document_id: WAYKIN-CONTINUATION-001
version: 0.1
date: 2026-07-19
status: ACTIVE
main_sha_at_draft: e4536a4
audio_first: true
outdoor_qa: DEFERRED
```

## Where we are (shipped)

| Track | Status | Evidence |
| ----- | ------ | -------- |
| Echo tokens / icons / app icon | Shipped | PRs #51–#56 |
| Session stills 7×3 spectral pack | **DIRECTION_ACCEPTED** | #71–#73, sign-off |
| Sim preflight + S1–S8 automation | Shipped | #75, #77 |
| AR Living Familiar mid-LOD | Procedural shipped | #79 |
| USDZ async load + fallback | Shipped | #81 |
| Animation plan (draft) | Doc only | `LIRA_ANIMATION_PLAN.md` |
| Outdoor OBSERVED walk | **Blocked** | Needs device |

## Goals (do not expand)

- One companion **Lira**; no marketplace / multiplayer / map combat UI
- Audio-first; presentation supports presence
- WaykinCore isolation unchanged
- No false outdoor claims

## Continuation backlog (ordered)

### Wave 1 — Motion that users see in session (now)

| ID | Work | Owner slice | Exit |
| -- | ---- | ----------- | ---- |
| **C1 / A1** | Session still **crossfade** on pose/skin change + Reduce Motion contract | App UI | **Done** |
| **C2 / A2** | AR procedural **A2 breath + A3 sway** (bounded loops) | App AR | **Done** |
| **C3 / A3** | Hunter **echo** pass (session still overlay + AR ghost) | App | No gore; pressure only |
| **C4 / A4** | Spawn coalesce + AR state easing (≤250ms) | App AR | Replay/soak still pass |

### Wave 2 — Production mesh (when artist ready)

| ID | Work | Exit |
| -- | ---- | ---- |
| **C5** | Drop sculpted `Lira_AR_Base.usdz` with A1–A3 names | Loader `source == .usdz` in sim |
| **C6 / A5** | Optional AnimationLibrary clips on USDZ | Mapped from `CompanionPresentationState` |
| **C7** | Keep procedural as permanent debug fallback | Already designed |

### Wave 3 — Device evidence (blocked on hardware)

| ID | Work | Exit |
| -- | ---- | ---- |
| **C8** | Outdoor walk + `OUTDOOR_QA_RECEIPT` | Day+night OBSERVED |
| **C9 / A6** | Outdoor motion notes (glare, pulse readability) | Receipt fields filled |
| **C10** | Issue #41 physical AR | Named device build |

### Wave 4 — Polish (optional)

| ID | Work |
| -- | ---- |
| **C11** | Hand-painted still pass on top of spectral direction |
| **C12** | Hero marketing stills beyond Guide Dawn |
| **C13** | Reduced-motion-specific still variants only if needed |

## This iteration

1. **C1 / A1** — session still crossfade — **done**
2. **C2 / A2** — AR A2 breath + A3 sway — **done**
3. Continuation plan recorded in design index
4. Next code slice: **C3 / A3** hunter echo
5. Outdoor and USDZ sculpt remain deferred

## Non-goals this iteration

- Outdoor walk
- Artist sculpt
- New gameplay states
- Flipbook multi-frame stills (plan Q1: pure crossfade)

## Success metrics

- `make validate` PASS
- WaykinUITests presence identifiers unchanged
- Reduce Motion: no looping pulse; pose change ≤80ms fade or cut
- Normal motion: ~220ms ease-in-out still crossfade

## Related

- [LIRA_ANIMATION_PLAN.md](LIRA_ANIMATION_PLAN.md)
- [ART_DIRECTION_SIGN_OFF.md](ART_DIRECTION_SIGN_OFF.md)
- [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md)
- [OUTDOOR_QA_CHECKLIST.md](OUTDOOR_QA_CHECKLIST.md)
