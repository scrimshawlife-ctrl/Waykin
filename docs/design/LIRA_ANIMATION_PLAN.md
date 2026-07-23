# Lira Animation Plan (Draft)

```yaml
document_id: WAYKIN-LIRA-ANIM-PLAN-001
version: 0.7
status: MESHY_STATIC_MESH_PUPPET
companion: Lira
style: spectral_living_familiar
direction: DIRECTION_ACCEPTED
audio_first: true
outdoor_qa: NOT_COMPUTABLE
session_ambient_motion: SHIPPED
route_polyline_reveal: SHIPPED
skeletal_animation_library: JOINT_HIERARCHY_SHIPPED
static_mesh_body_centric_puppet: SHIPPED
blender_armature_rigid_bind: SHIPPED
heat_map_auto_weights: SHIPPED
hero_region_weights: SHIPPED
dcc_action_clips: SHIPPED
generated_mid_lod_usdz: SHIPPED_V1_2
artist_blend_armature_usdz: SHIPPED_V1
artist_blend_skinned_usdz: SHIPPED_V1
meshy_textured_static_usdz: SHIPPED_V1
runtime_animation_resource_clips: SHIPPED
procedural_mesh_mid_lod: SHIPPED
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
| **AR mid** | RealityKit companion | Root pose + A1 head + A2 breath + A3 multi-seg sway + ears/tail/bob + hunter echo + spawn | **Procedural channels shipped** |
| **AR mid mesh** | Procedural factory | `LiraMeshGeometry` MeshDescriptor (tapered head, sensor blades, filament segments) | **Shipped** |
| **AR mid clips** | Runtime `AnimationResource` | `LiraARAnimationLibrary` FromToBy (optional lab / one-shot) | **Shipped** |
| **AR mid skeletal** | Joint-hierarchy puppet | `LiraSkeletalAnimationLibrary` + `LiraSkeletalPlayer` (default on spawn) | **Shipped** |
| **AR hero** (later) | Optional USDZ | DCC skinned skeletal / bone export | **Not shipped** (DCC) |
| **Marketing hero** | Promo | Optional, out of runtime loop | Quality-pass stills optional |

## Session 2D animation (priority 1)

### Current

- Pose resolved per presentation → spectral still image.
- Soft scale pulse on `animationKey` (honors Reduce Motion).
- Pressure ring stroke + bond orbit geometry.

### Planned clips (still-based, no sheet required)

| Clip ID | Trigger | Motion | Duration | Reduced motion | Status |
| ------- | ------- | ------ | -------- | -------------- | ------ |
| `S_pose_crossfade` | Pose change | Opacity crossfade between stills | 180–280ms | Hard cut or 80ms | **Shipped** |
| `S_core_pulse` | Idle / bond | Presence scale pulse + period helper | 1.6s loop | Static | **Shipped** |
| `S_filament_drift` | Guide / follow / bond / sanctuary | Still offset + ambient pulse via TimelineView | 2.4s / 1.6s | Off | **Shipped** (#157) |
| `S_manifest` | Opening / manifesting | Opacity 0→1 + scale 0.92→1 | 700ms | ≤120ms fade | **Shipped** |
| `S_hunter_echo` | Pursuit close | Delayed second silhouette, cool fringe | While pressure | Static hunter still | **Shipped** |
| `S_bond_orbit` | Bond event | Bond ring continuous spin 1.2s | Loop while bond | Static ring | **Shipped** |

### Implementation notes

- Prefer **still crossfade** over re-introducing Canvas puppet except as fallback.
- Do not animate layout of Pause/End; keep 48pt chrome stable.
- Skin change: crossfade still only; no mesh morph.

### Exit criteria (session)

- [x] Pose transitions never blank the presence frame (crossfade keep previous still)
- [x] Reduce Motion disables ambient loops; one-shot fades ≤120ms (helpers + figure)
- [x] UI tests still find `waykin.session.presence` with pose a11y value

## AR mid-LOD animation (priority 2)

### Current

`ARWorldCommandRenderer.applyPresentation` owns **scale**, status indicator, materials,
and local joint motion. Root **position / orientation** are owned by
`advanceCompanionFollow` (world-space walk) and must not be re-applied on state change
(that would snap Lira back to the anchor origin).

| State | Presentation intent (scale / FX; not root plant) |
| ----- | ------ |
| idle | Neutral scale |
| follow | Slight grow |
| investigate | Lean / crouch scale |
| alert | Rear / grow |
| celebrate | Lift scale window |

### Planned channels (procedural entity first)

| Channel | Nodes | Behaviors | Status |
| ------- | ----- | --------- | ------ |
| **Root plant** | `LiraRoot` | Existing state table; `rootPlantEase` helper | **Shipped** |
| **A2 breath** | `CoreGlow`, `CoreHalo` | Idle scale loop | **Shipped** |
| **A3 sway** | `Filament` + `FilamentBase/Mid/Tip` | Base orientation + phase-shifted segment pitch | **Shipped** |
| **Head attention** | `Head` | Yaw/pitch by state | **Shipped** |
| **Ears / tail** | `LeftEar`, `RightEar`, `Tail` | Flutter / sway | **Shipped** |
| **Body bob** | `Body` | Soft vertical rest+offset (includes ground offset) | **Shipped** |
| **Hunter echo** | `HunterEcho` node | Only in alert | **Shipped** |
| **Spawn coalesce** | Whole root | Scale settle on spawn | **Shipped** |
| **Celebrate** | Root | Bounded duration (reducer) | **Shipped** |
| **Runtime clips** | Optional bind targets | `LiraARAnimationLibrary` (idle/follow/alert/celebrate/spawn) | **Shipped** (lab / single-node) |
| **Skeletal puppet** | Joint paths on `LiraRoot` | `LiraSkeletalPlayer` multi-joint groups; default driver when installed | **Shipped** |
| **Blender armature** | `LiraArmature` + USD Skeleton | Bone hierarchy (`build_lira_armature.py`) | **Shipped** |
| **Heat-map auto-skin** | Body/Head/ears/legs weights | `skin_lira_armature.py` ARMATURE_AUTO | **Shipped** |
| **Hand-painted skin** | Artist paint pass | Hero close-up weights | **Not shipped** |

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
| U1a | Joint-hierarchy skeletal AnimationLibrary + player (**shipped** — puppet bind paths) |
| U1a+ | Blender `LiraArmature` + USD Skeleton (**shipped**) |
| U1a++ | Auto-weight heat-map skin on Body/Head/ears/legs (**shipped**) |
| U1b | Author idle / walk / alert clips in DCC; optional hand-painted weights |
| U2 | RealityKit playback mapped from `CompanionPresentationState` (**shipped** for puppet) |
| U3 | Skin materials remain runtime remap; clips shared (**shipped**) |

Procedural pure-function locals remain the fallback when `skeletalPlaybackEnabled` is false or install fails.

### Exit criteria (AR)

- [x] `make validate` + AR embodiment tests stay green (deterministic presentation)
- [x] No animation after `clearSession` (`skeletalPlayer.clear()`)
- [x] Skin swap materials only; skeletal clips by presentation state
- [x] LOD label reflects procedural vs USDZ (`waykin.ar.canonical.lod`)

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
| **A3** | Hunter echo (AR + session) | **Done** (indoor) |
| **A4** | Spawn coalesce (scale factor) | **Done** (indoor; root pose snaps) |
| **A4b** | MeshDescriptor mid-LOD + multi-seg filament + ears/tail/bob | **Done** (`LiraMeshGeometry` + factory) |
| **A4c** | Runtime `AnimationResource` clip library | **Done** (`LiraARAnimationLibrary`) |
| **A5** | Joint-hierarchy skeletal AnimationLibrary + player | **Done** (`LiraSkeletal*` + renderer default) |
| **A5+** | Session ambient drift/pulse + route polyline reveal | **Done** (#157) |
| **A5b** | Blender armature on artist multi-mesh | **Done** (`LiraArmature` + export) |
| **A5c** | Heat-map auto-weights (merge torso + ARMATURE_AUTO) | **Done** (`skin_lira_armature.py`) |
| **A5d** | Hero region weight paint (reproducible) | **Done** (`paint_lira_hero_weights.py`) |
| **A5e** | DCC action clips + hybrid runtime player | **Done** (`author_lira_armature_clips` + DCC overlay) |
| **A5f** | Meshy static mesh body-centric puppet style | **Done** (`PuppetStyle.staticMesh` + Body bob/lean) |
| **A5g** | Spectral FX layer (A2/A3/shadow) + hybrid clips | **Done** (`installSpectralFX` + body+FX groups) |
| **A6** | Outdoor motion QA notes | Device walk (#41) |

## Test strategy

| Layer | Approach |
| ----- | -------- |
| Unit | Pose resolve unchanged; presentation vectors stay absolute-assertable |
| Loader | Template clone independent; fallback procedural |
| UI | Presence a11y value; no hang on rapid pose changes |
| Determinism | Replay/soak suites must not depend on animation wall-clock |

Prefer **injectable clocks** or discrete `advance(by:)` (already used for celebrate) over `DispatchQueue` sleeps.

## Resolved decisions (non-outdoor)

1. **Session stills:** pure crossfade forever (no flipbook). Ambient drift/pulse is separate and Reduce-Motion gated.
2. **Celebrate:** AR skeletal celebrate clip + session bond orbit only (no shared flipbook).
3. **Procedural fallback:** permanent safety net forever when USDZ missing/invalid (`LiraARAssetLoader`).

## Open (device / artist)

1. Outdoor motion QA (#41)
2. Freehand tablet weight logs (optional artist pass beyond hero region paint)
3. Outdoor motion QA (#41)

## Related docs

- [ART_DIRECTION_SIGN_OFF.md](ART_DIRECTION_SIGN_OFF.md)
- [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md)
- [GENERATED_LIRA_ART.md](GENERATED_LIRA_ART.md)
- [LIRA_PRODUCTION_ART_PIPELINE.md](LIRA_PRODUCTION_ART_PIPELINE.md)
