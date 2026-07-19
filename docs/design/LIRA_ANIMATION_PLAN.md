# Lira Animation Plan (Draft)

```yaml
document_id: WAYKIN-LIRA-ANIM-PLAN-001
version: 0.1
status: DRAFT
companion: Lira
style: spectral_living_familiar
direction: DIRECTION_ACCEPTED
audio_first: true
outdoor_qa: NOT_COMPUTABLE
```

## Purpose

Define how Lira **moves** across session UI and AR without expanding product scope (one companion, audio-first, no multiplayer/marketplace).

This plan binds animation to existing state machines:

| Domain | Pose / state source |
| ------ | ------------------- |
| Session 2D | `LiraSessionPose` ← `CompanionPresencePresentation` |
| AR mid-LOD | `CompanionPresentationState` ← behaviors / commands |
| Audio | Cue kinds already drive presence language |

## Principles

1. **Audio leads.** Motion supports path awareness; it does not invent new gameplay loops.
2. **Anchors stay readable.** A1 head · A2 chest ember · A3 filament must remain identifiable under motion.
3. **Reduce motion is first-class.** Every clip has a static still or ≤120ms crossfade fallback.
4. **One rig.** Dawn / Veil / Rupture share timing and bones; materials only differ.
5. **Hunter without gore.** Pressure = echo delay, crouch, cool filament — not teeth/blood/shake-cam.
6. **Bounded cost.** Prefer root + 3–5 local channels over full body mocap until USDZ sculpt exists.

## LOD motion ladder

| LOD | Surface | Motion language | Status |
| --- | ------- | --------------- | ------ |
| **Glyph** | Chips / icons | None or 1-frame core pulse | Stills shipped |
| **Session mid** | Home + active walk | Still swap + soft pulse/orbit | Stills + light SwiftUI pulse |
| **AR mid** | RealityKit companion | Root pose table + local A2/A3 idle | Root transforms shipped |
| **AR hero** (later) | Optional USDZ | Skeletal clips or RealityKit AnimationLibrary | Not started |
| **Marketing hero** | Promo | Optional, out of runtime loop | Optional |

## Session 2D animation (priority 1)

### Current

- Pose resolved per presentation → spectral still image.
- Soft scale pulse on `animationKey` (honors Reduce Motion).
- Pressure ring stroke + bond orbit geometry.

### Planned clips (still-based, no sheet required)

| Clip ID | Trigger | Motion | Duration | Reduced motion |
| ------- | ------- | ------ | -------- | -------------- |
| `S_pose_crossfade` | Pose change | Opacity crossfade between stills | 180–280ms | Hard cut or 80ms |
| `S_core_pulse` | Idle / bond | A2-scale 1.0↔1.06 on still or orbit | 1.6s loop | Static |
| `S_filament_drift` | Guide / follow | Subtle offset of filament via Canvas overlay only if still lacks motion | 2.4s loop | Off |
| `S_manifest` | Opening / manifesting | Opacity 0→1 + scale 0.92→1 | 700ms | ≤120ms fade |
| `S_hunter_echo` | Pursuit close | Delayed second silhouette 40–80ms, cool fringe | While pressure | Static hunter still |
| `S_bond_orbit` | Bond event | Existing bond ring spin | 1.2s | Static ring |

### Implementation notes

- Prefer **still crossfade** over re-introducing Canvas puppet except as fallback.
- Do not animate layout of Pause/End; keep 48pt chrome stable.
- Skin change: crossfade still only; no mesh morph.

### Exit criteria (session)

- [ ] Pose transitions never blank the presence frame
- [ ] Reduce Motion disables loops; one-shot fades ≤120ms
- [ ] UI tests still find `waykin.session.presence` with pose a11y value

## AR mid-LOD animation (priority 2)

### Current

`ARWorldCommandRenderer.applyPresentation` sets absolute root:

| State | Intent |
| ----- | ------ |
| idle | Neutral plant |
| follow | Slight forward + yaw |
| investigate | Lean / crouch scale |
| alert | Rear / grow |
| celebrate | Lift + spin window |

### Planned channels (procedural entity first)

| Channel | Nodes | Behaviors |
| ------- | ----- | --------- |
| **Root plant** | `LiraRoot` | Existing state table; add ease-in-out 200ms (optional) |
| **A2 breath** | `CoreGlow`, `CoreHalo` | Idle emissive scale loop 1.8s |
| **A3 sway** | `Filament`, `FilamentTip` | Low-amplitude pitch/yaw noise; cool faster in alert |
| **Head attention** | `Head` | Yaw toward spatial intent when investigate |
| **Hunter echo** | Duplicate root or delayed `Body` opacity | Only in alert; ≤0.15 opacity ghost |
| **Spawn coalesce** | Whole root | Scale/opacity on first spawnCompanion |
| **Celebrate** | Root | Keep bounded duration; no infinite spin |

### Timing budget (AR)

| Event | Max motion | Notes |
| ----- | ---------- | ----- |
| State change | 250ms ease | Deterministic; no wall-clock sleeps in tests |
| Idle loops | 1.5–2.5s | Stop when Reduce Motion / backgrounded |
| Celebrate | Existing reducer window | Unchanged gameplay semantics |
| Clear / detach | 0ms snap | No stale tweens after clear |

### USDZ / skeletal (when mesh lands)

| Phase | Work |
| ----- | ---- |
| U0 | Hierarchy A1–A3 validated by `LiraARAssetLoader` (**shipped path**) |
| U1 | Author idle / walk / alert clips in DCC; export with same bone names |
| U2 | RealityKit `AnimationResource` playback mapped from `CompanionPresentationState` |
| U3 | Skin materials remain runtime remap; clips shared |

Until U1, **do not block** on skeletal; drive procedural locals.

### Exit criteria (AR)

- [ ] `make validate` + AR embodiment tests stay green (deterministic presentation)
- [ ] No animation after `clearSession`
- [ ] Skin swap does not restart unrelated clips mid-pose incorrectly
- [ ] LOD label reflects procedural vs USDZ (`waykin.ar.canonical.lod`)

## State mapping matrix

| App / Core signal | Session pose | AR presentation | Motion emphasis |
| ----------------- | ------------ | --------------- | --------------- |
| Opening | Manifesting | idle → follow | Coalesce |
| Lead / ahead | Guide | follow | Filament forward |
| Observe | Guide / Rival | investigate | Head yaw |
| Rest | Sanctuary | idle | Soft breath |
| Bond / celebrate | Bond | celebrate | Core + lift |
| Quiet interval | Dormant | idle | Dim core |
| Pursuit noticed | Rival | investigate | Copper edge (material) |
| Pursuit approaching/close | Hunter | alert | Crouch + echo |
| Pursuit fading | Sanctuary | idle / follow | Release tension |

## Anti-patterns

- Bouncy pet hop / mascot wave
- Pokémon-style attack flourishes
- Full-body dance blocking audio comprehension
- Screen shake for hunter
- Per-skin unique animation sets
- Animation that implies multiplayer or map combat

## Phased delivery

| Phase | Deliverable | Depends |
| ----- | ----------- | ------- |
| **A0** | This plan + USDZ load path | **Done** (#81) |
| **A1** | Session still crossfade + Reduce Motion contract | **Done** (`LiraSessionMotion` + figure blend) |
| **A2** | AR A2 breath + A3 sway (procedural) | **Done** (`LiraARMotion` + renderer advance) |
| **A3** | Hunter echo (AR + session) | A1–A2 |
| **A4** | Spawn coalesce + pose easing | A1–A2 |
| **A5** | USDZ AnimationLibrary (optional) | Artist mesh |
| **A6** | Outdoor motion QA notes | Device walk |

## Test strategy

| Layer | Approach |
| ----- | -------- |
| Unit | Pose resolve unchanged; presentation vectors stay absolute-assertable |
| Loader | Template clone independent; fallback procedural |
| UI | Presence a11y value; no hang on rapid pose changes |
| Determinism | Replay/soak suites must not depend on animation wall-clock |

Prefer **injectable clocks** or discrete `advance(by:)` (already used for celebrate) over `DispatchQueue` sleeps.

## Open questions

1. Should session stills ever use a short flipbook (3 frames) or stay pure crossfade?
2. Does celebrate remain AR-only spin, or also session bond orbit only?
3. When USDZ ships, do we freeze procedural as debug fallback forever? (**Recommend yes.**)

## Related docs

- [ART_DIRECTION_SIGN_OFF.md](ART_DIRECTION_SIGN_OFF.md)
- [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md)
- [GENERATED_LIRA_ART.md](GENERATED_LIRA_ART.md)
- [LIRA_PRODUCTION_ART_PIPELINE.md](LIRA_PRODUCTION_ART_PIPELINE.md)
