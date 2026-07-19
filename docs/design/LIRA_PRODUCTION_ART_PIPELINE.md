# Lira Production Art Pipeline

```yaml
document_id: WAYKIN-LIRA-ART-PIPELINE-001
version: 0.1
date: 2026-07-19
status: PRODUCTION_SPEC
companion_product_name: Lira
visual_family: Living_Familiar
brand_climate: Echo_B
current_app_state: spectral_stills_direction_accepted_ar_procedural_mid
direction_lock: Echo + Lira spectral Living Familiar (DIRECTION_ACCEPTED)
```

## Purpose

Move Lira from **procedural Echo placeholder** (session silhouette + AR sphere-rig) to **production-quality art** without expanding product scope.

Authoritative product rules: one companion, audio-first, no multi-companion, no marketplace-driven skins, hunter without gore.

## Current state (OBSERVED in app)

| Surface | Implementation | Status |
| ------- | -------------- | ------ |
| Session presence | Spectral stills 7×3 via `LiraStillCatalog` | DIRECTION_ACCEPTED |
| AR entity | Living Familiar mid-LOD `CompanionEntityFactory` + USDZ slot | Procedural mid shipped |
| Icons / brand | Echo icons + Bond Filament + AppIcon | Production candidate |
| Tokens | `WKTokens` v0.2 day/night | In app |

Exploration rasters in Waykin-Design `05_Companion/recommended/` remain **reference only**.

## Identity anchors (non-negotiable)

| ID | Name | Production rule |
| -- | ---- | --------------- |
| **A1** | Head geometry | Tapered non-canid; recognizable at 64px |
| **A2** | Chest bond core | Amber / bond gold emitter; all states |
| **A3** | Trailing filament | Plume/stream; cool under hunter |
| A4 | Ear/sensor pair | Soft offset; preferred |
| A5 | Glow rhythm | Chest pulse by state; preferred |

**Recognition test:** A1+A2+A3 alone identify Lira at glyph scale without color.

## LOD ladder

| LOD | Use | Deliverable |
| --- | --- | ----------- |
| **Hero** | Marketing / unlock (later) | High-detail stills; optional |
| **Session mid** | Active walk UI | Simplified body + fringe; matches silhouette language |
| **AR session** | RealityKit mid | Low-poly / bone puppet; same anchors |
| **Glyph** | Icons / chips | Head + chest + tail only |

MVP ships **session mid + AR session + glyph**. Hero can wait.

## State library (must ship)

| State | Visual contract | Hunter note |
| ----- | --------------- | ----------- |
| Dormant | Compact, dim core | — |
| Manifesting | Coalesce 700ms; reduced ≤120ms | — |
| Guide | Open, ahead, warm-teal fringe | — |
| Rival | Forward coil, copper edge | — |
| Hunter | Low stalk, delayed echo, cool filament, asymmetry | No gore/teeth/red-only |
| Sanctuary | Settled, soft warm | — |
| Bond update | Ring/orbit near chest | Not XP bar |

Map app runtime where possible:

| App / Core signal | Art lean |
| ----------------- | -------- |
| lead / ahead audio | Guide |
| drawNear / celebrate | Bond warmth |
| rest | Sanctuary lean |
| pursuit noticed→close | Hunter pressure (geometry + echo) |
| inactive quiet | Guide / idle |

## Skin set (cosmetic only)

| Skin | Default | Role |
| ---- | ------- | ---- |
| **Dawn** | Yes | Invitation, first bond |
| **Veil** | No | Liminal, higher echo |
| **Rupture** | No | Fracture FX capped |

Rules: one rig; no new mechanics; front/rear turnarounds required for production.

Skin materials: Waykin-Design `06_Skins/shared/WK_SKIN_Contract_v0.2.yaml`.

## Single-developer pipeline

```text
1. Lock silhouette + proportion sheet (side/front/rear)
   Source: Waykin-Design/05_Companion/production/WK_COMPANION_ProportionSheet_v0.2.svg
2. Build 2D bone puppet OR low-poly mesh with A1–A3 attachments
3. Pose library for 7 states (session mid + reduced-motion stills)
4. Hunter pass + human gore review
5. Material variants Dawn / Veil / Rupture on same rig
6. Export:
   - PNG/WebP session atlas or per-state stills
   - Optional USDZ / RealityKit mesh for AR
   - Glyph 64/128
7. Import into App/Resources; replace Canvas silhouette and/or factory mesh
8. Outdoor QA receipt (device)
```

### Suggested file names (app import)

```text
App/Resources/Companion/Lira/
  Lira_Session_Guide.png
  Lira_Session_Rival.png
  Lira_Session_Hunter.png
  Lira_Session_Sanctuary.png
  Lira_Session_Dormant.png
  Lira_Session_Manifesting.png
  Lira_Session_Bond.png
  Lira_Session_*_ReducedMotion.png
  Lira_Glyph_64.png
  Lira_AR_Base.usdz          # optional
  skins/dawn|veil|rupture/
```

### Naming contract

```text
Lira_{LOD}_{State}[_{Skin}][_{Variant}].{ext}
LOD: Session | AR | Glyph | Hero
State: Dormant | Manifesting | Guide | Rival | Hunter | Sanctuary | Bond
Skin: Dawn | Veil | Rupture (omit = base Dawn materials)
Variant: ReducedMotion | EchoOffset | …
```

## Acceptance gates (art)

| Gate | Criteria |
| ---- | -------- |
| G1 Silhouette | Same being at 64px across 7 states |
| G2 Anchors | A1–A3 present in every production still |
| G3 Hunter | Echo/asymmetry only; gore review signed |
| G4 Reduced motion | Static still per state |
| G5 Skins | Dawn default; Veil/Rupture same rig |
| G6 App wire | Session replaces Canvas; AR optional mesh swap |
| G7 Outdoor | QA receipt day+night OBSERVED (separate protocol) |

## Anti-patterns

- Dog/wolf clone proportions
- Cute mascot that kills uncanny pole
- Horror hunter / teeth / blood
- XP-bar bond visualization
- Unique mesh per skin
- Fitness-dashboard chrome in hero frames

## Effort estimate (solo)

| Phase | Time | Output |
| ----- | ---- | ------ |
| Proportion lock + 3 views | 2–4 days | Sheet final |
| Session mid pose set (7) | 1–2 weeks | Stills/puppet |
| AR low-poly | 3–7 days | Mesh or keep factory until ready |
| Skins Dawn-only first | 2–4 days | Materials |
| Veil + Rupture | +1 week | Optional if time-cut |

**Time-cut MVP art:** Dawn session mid Guide + Hunter + Sanctuary + Glyph only.

## Ownership

| Role | Responsibility |
| ---- | -------------- |
| Product | Accept gates; outdoor walk |
| Art / design | Rig, poses, skins |
| Engineering | Import assets; wire LODs; reduced-motion |
| Human reviewer | Gore pass; INTEGRATED flag |

## Related documents

| Doc | Role |
| --- | ---- |
| `OUTDOOR_QA_CHECKLIST.md` | Device walk checks |
| `OUTDOOR_QA_RECEIPT_TEMPLATE.md` | Fillable evidence |
| `SIMULATOR_PREFLIGHT.md` | What sim can prove |
| Waykin-Design `05_Companion/production/*` | Rig brief + proportion sheet |
| Waykin-Design `06_Skins/*` | Skin contract |

## Definition of done (art program)

```yaml
proportion_sheet_final: true
seven_states_session_mid: true
reduced_motion_stills: true
hunter_gore_review: true
dawn_skin_on_rig: true
app_session_uses_production_art: true
outdoor_qa_receipt: OBSERVED # separate human step
integrated_flag: human_only
```
