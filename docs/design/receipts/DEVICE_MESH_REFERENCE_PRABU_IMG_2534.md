# Device mesh visual reference — Prabu indoor test (IMG_2534)

```yaml
document_id: WAYKIN-DEVICE-MESH-REF-PRABU-IMG-2534
date_local_observed_on_photo: "9:37"   # status bar only; full calendar date NOT_COMPUTABLE from image
evidence_class: OBSERVED
operator: Prabu
source_media: Messages attachment IMG_2534.heic → docs/design/receipts/evidence/IMG_2534_prabu_ember_fox_device.png
purpose: VISUAL_GOLD_STANDARD_FOR_AUTHORED_MESH
not: outdoor_COH
not: full_indoor_I1_I14_packet
```

## Purpose

Record **how the packaged companion mesh should look on device** after successful authored load, based on Prabu’s physical-device test screenshot. This is the freeze-lane **visual acceptance reference** for Ember Fox / authored USDZ — not procedural spheres, not artist-blend primitives.

## Source media

| Field | Value |
| ----- | ----- |
| Original | `IMG_2534.heic` (Messages attachment; HEIF) |
| Repo copy | [`evidence/IMG_2534_prabu_ember_fox_device.png`](evidence/IMG_2534_prabu_ember_fox_device.png) |
| Conversion | `sips -s format png` from HEIC (lossless-intent still; pixel 1179×2556) |
| Privacy | Indoor carpet / household objects; **no coordinates**; no face; OK as engineering evidence |

## OBSERVED (from screenshot)

### Companion appearance

- Single stylized **fox-like** companion on carpet (large upright ears, soft body, pale blue / cool-toned surface).
- Reads as **authored mesh**, not the multi-sphere procedural Living Familiar placeholder.
- Plausible ground contact relative to carpet (not grossly floating/sunk in the frame).
- Only **one** companion visible in frame.

### Operator chrome (DEBUG strip)

Readable fragments:

```text
active · follow · anim=PLAYING
animated_usdz:Lira_AR_Bas… animated_skelanim:clips=6
ok_present
```

| Signal | Interpretation |
| ------ | -------------- |
| `animated_usdz:Lira_AR_Bas…` | Authored package path active (not stuck on procedural-only) |
| `animated_skelanim:clips=6` | Skeletal animation path with clip count reported |
| `anim=PLAYING` | Animation not stuck off after plant |
| `active · follow` | Session active; companion presentation follow |
| `ok_present` | Continuity / presence healthy in strip |

### Session chrome

- Full-screen AR camera background (indoor room, mirror, carpet).
- Bottom **Pause** / **End** controls present.

## INFERRED

- Device path exercised a build where package load + skeletal animation were live (consistent with post-#246 runtime goals).
- This is the **intended product mesh look** for freeze acceptance and indoor smoke I5–I8 visual rows.

## NOT_COMPUTABLE (do not invent)

| Field | Reason |
| ----- | ------ |
| Exact install git SHA | Not visible in screenshot |
| Marketing version / build number | Not visible |
| Device model / iOS version | Not labeled |
| Time to fallback → replace | Not timed |
| Anchor count before/after replace | Not instrumented in photo |
| Outdoor quality | Indoor only |
| Audio / thermal / battery | Not evidenced |
| Whether this build equals freeze tip `7df3a16` / `ddb1438` | Unknown without operator note |

## Relation to freeze / #247

| Item | Status |
| ---- | ------ |
| Visual gold standard for authored mesh | **This photo** |
| Procedural-placeholder-only failure (#247) | Contradicted **for the unknown SHA Prabu tested** — authored mesh is on screen |
| Close #247 for freeze tip | **Not automatic** — needs OBSERVED on **exact archive/install SHA** (prefer `7df3a16` or later freeze tip) |
| Outdoor #41 | Unrelated; still open |
| Laptop baseline | Still `POST_EMBER_FOX_BASELINE_*` (sim/package only) |

## Acceptance use

When running indoor Ember Fox smoke on the freeze tip, compare:

1. Companion silhouette / style ≈ this reference (fox, not spheres).  
2. Operator strip shows `animated_usdz` (or equivalent authored class) and animation playing when moving/follow.  
3. Single companion after load/replace.

Mismatch → narrow defect issue; do not replace mesh without an asset issue.

## Explicit non-claims

- Does not by itself close #41.  
- Does not authorize TF archive without tip-bound SHA confirmation.  
- Does not promote redesign docs or product-law changes.

---

**Filed under freeze lane.** Live board: `docs/collaboration/ACTIVE_WORK.md`.
