# Lira AR production sculpt plan

```yaml
document_id: WAYKIN-LIRA-AR-SCULPT-001
version: 0.1
date: 2026-07-23
status: AUTHORIZED_ISSUE
issue: 220
authority: SUPPORTING_ART_TRACK
ar_freeze: package_swap_via_issue_220
replaces_interim: MESHY_TEXTURED_STATIC_V1
direction_lock: ART_DIRECTION_SIGN_OFF spectral Living Familiar
```

## Decision

Pursue a **hand-authored (or artist-directed) mid-LOD sculpt** as the default AR package for Lira. Meshy image-to-3d / walk exports are **interim only** and do not satisfy brand silhouette.

Session **spectral stills** remain the 2D direction lock. AR sculpt must **rhyme** with stills (A1–A3), not invent a second creature.

## Problem (OBSERVED history)

| Era | Package | Operator read |
| --- | ------- | ------------- |
| Pre-Meshy | ~5.6 KB sphere prim USDZ | “Blob / new art not used” |
| Main tip | Meshy textured static ~10 MB | Textured but **not** icon/still silhouette |
| #217 | Meshy skinned walk ~18.5 MB | Better load path; **still Meshy auto mesh** |

Procedural Living Familiar (sphere-rig) remains permanent **soft fallback** when package fails.

## Non-goals

- Hero marketing sculpt as runtime default  
- Per-skin unique meshes (one rig, three material climates)  
- Outdoor #41 COH from this work alone  
- Expanding AR gameplay beyond presentation package  

## Identity gates (must pass before ship)

| Gate | Criteria |
| ---- | -------- |
| **G-A1** | Tapered non-canid head; readable at 64px |
| **G-A2** | Chest bond core present every idle/follow frame |
| **G-A3** | Filament/plume present; not a stump |
| **G-S** | Side + front proportions within proportion sheet ratios |
| **G-H** | Hunter language possible without gore (cool filament OK) |
| **G-B** | Not a smooth featureless blob or stock animal |

Source of truth:

- `Waykin-Design/05_Companion/production/WK_COMPANION_ProportionSheet_v0.2.svg`
- `Waykin-Design/05_Companion/production/WK_COMPANION_Production_Rig_Brief_v0.2.md`
- Session stills: Dawn Guide / Hunter / Sanctuary as comparison

## Pipeline (existing)

```text
Proportion sheet + stills (direction)
        ↓
Blender sculpt mid-LOD (~0.72 m)
        ↓
Semantic renames (Body, Head, Filament, CoreGlow, …)
        ↓
scripts/export_lira_blend_to_usdz.sh  (armature / skin / clips as needed)
        ↓
App/Resources/Lira_AR_Base.usdz
  + Companion/Lira mirror
  + docs/assets/companion/ar mirror
        ↓
check_lira_usdz_integrity.sh + catalog evidence class
```

Working files:

| File | Role |
| ---- | ---- |
| `ArtSource/Companion/Lira/lira.blend` | Primary art source in repo |
| `~/Desktop/lira.blend` | Operator desktop twin (same family) |
| `ArtSource/Companion/Lira/Lira_AR_Base_*.blend` | Prior pipeline intermediates |
| `scripts/export_lira_blend_to_usdz.sh` | Preferred export |
| `scripts/check_lira_usdz_integrity.sh` | Triple package + budget |

**Do not** treat `asset/lira-handsculpted-mid-lod` as done — that path shipped a primitive stub under a sculpt name.

## Evidence class

Propose: **`ARTIST_SCULPT_MID_LOD_V1`**

Update together:

- `LiraARAssetCatalog.packagedEvidenceClass`
- `EXPORT_OK`
- `App/Resources/Companion/Lira/README.md`
- Loader `loadNote` / LOD strings if needed
- Unit tests that hard-code `MESHY_TEXTURED_STATIC_V1`

## Budget

| Cap | Rule |
| --- | ---- |
| Hard | ≤ 20 MB runtime package (integrity fail) |
| Soft | ≤ 12 MB preferred (WARN above) |
| Texture | Prefer 1K–2K albedo; avoid accidental 4K re-import |

## AR freeze compliance

`AR_MVP_FREEZE.md` lists hand-sculpted hero as non-goal under blind expansion. **Issue #220** authorizes a **bounded package replacement** so brand AR presentation matches direction lock. Allowed paths:

- `App/Resources/**` USDZ + mirrors  
- Catalog / integrity / export scripts as needed  
- Minimal loader notes for new evidence class  

Not allowed without new issues: new AR gameplay states, multi-companion, hero-only marketing runtime.

## Suggested PR sequence

1. **Docs** (this plan + ACTIVE_WORK intake) — this PR  
2. **Art** — blend + USDZ triple + evidence class  
3. **Optional** — DCC idle/walk clips if stills motion insufficient  
4. **Indoor smoke** — silhouette row OBSERVED on device  

Parallel OK with #217 device AR/audio.

## Exit

Close #220 when acceptance criteria pass on a named tip with package tests green and indoor or sim LOD receipt shows non-procedural sculpt class.
