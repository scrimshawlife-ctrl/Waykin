# Waykin Comprehensive UI/UX Specification

```yaml
document_id: WAYKIN-UIUX-SPEC-001
version: 0.1
date: 2026-07-20
issue: 132
status: PROPOSED            # proposes; product owner ratifies
authority: DESIGN_REFERENCE  # implementation only via bounded issues
depends_on: [WK_TOKENS_v0.2, BRAND_GUIDE, ART_DIRECTION_SIGN_OFF, Issue_126_audit]
companion: Lira
```

This document is two things: (A) the audit of every design doc, asset, and
shipped surface as of `main@ee17f5a`, and (B) the comprehensive UI/UX design
that unifies them. Nothing here authorizes implementation by itself — each
change ships as a bounded issue.

---

# Part A — Audit

## A1. Inventory

- **59 markdown documents** (8 root contracts, 26 design docs, canonical/
  collaboration/decision layers)
- **86 asset files**: Echo brand production set (app icon SVG + full raster
  ladder, Bond Filament marks), 21 generated Lira session stills (7 states ×
  3 skins) + 3 glyphs + hero, 21 session-still SVG sources, architecture
  diagrams, hero banners
- **Shipped UI surfaces**: Home, Active Session (demo + real), Session
  Summary, Memory History, Settings sheet, AR session cover (canonical), AR
  Lab (engineering target), glasses glance adapter (flag-off)

**Strengths worth naming:** the Echo token system is genuinely locked and
enforced (day/night non-inverted, tests assert hex parity); the art
direction is signed off with gates; accessibility is a shipped contract,
not an aspiration; every visual claim is evidence-classed. Few codebases
this age have design law this strong.

## A2. Findings (gaps and inconsistencies)

| ID | Severity | Finding |
|---|---|---|
| A2-1 | **High** | **Four state vocabularies with no canonical crosswalk.** Presentation (`idle/follow/investigate/alert/celebrate`), art stills (`Dormant/Manifesting/Guide/Bond/Hunter/Rival/Sanctuary`), pursuit (`inactive/noticed/approaching/close/fading`), path relation (`establishing/onPath/strained/offPath/recovered`). Each is internally consistent; the *mapping between them* lives only in scattered code. Design drift is inevitable without one table. → Part B7 supplies it. |
| A2-2 | **High** | **Home inverts the product's own priority** (Issue #126): demo walk is the prominent CTA; the real walk — the product — is an unstyled link below Memory History. |
| A2-3 | **High** | **AR modality contradicts walk ergonomics**: swipe-dismissible sheet covering Pause/End (#126), compounding the #125 continuity recovery loop. |
| A2-4 | Medium | `docs/assets/screenshots/` is empty (README only) — no canonical screen captures exist anywhere; reviews and pitches rebuild mental screenshots from code. |
| A2-5 | Medium | Icon raster authority is dual: `docs/assets/brand/production/appicon-rasters/` and the compiled `App/Resources/Assets.xcassets`. Functional, but no doc states which is source-of-truth (proposal: SVG master → docs rasters are reference; xcassets is build truth). |
| A2-6 | Low | Modality inconsistency: Summary is a push, Settings and AR are sheets, AR Lab is a separate target. Workable, but the rule ("pushes for flow, sheets for asides, covers for immersion") is implicit. |
| A2-7 | Low | Debug/UI-test text blocks share layout space with product UI on Home (flag-gated, but they shape the layout file's readability and tempt drift). |

---

# Part B — Comprehensive UI/UX Design

## B1. Design principles (derived from locked brand + product law)

1. **Pocket-first.** The phone is not the product; the walk is. Every
   screen assumes glances, one hand, sunlight, motion. Audio is the primary
   channel; the screen confirms, never demands.
2. **Calm authority.** Pressure is expressed as *presence* (ring geometry,
   thickness, wording) — never alarm color alone, never flash, never panic
   copy. End is always a calm, guilt-free act (H2/H3 in the outdoor
   checklist are product law).
3. **One companion, one truth.** Lira is singular and persistent. UI never
   duplicates her (presence surface OR AR, never both animating at once).
   Presentation layers may interpret canonical state; they never invent it.
4. **Evidence-gated polish.** No claim outruns its receipt. Simulator
   evidence styles the defaults; outdoor receipts tune them.
5. **Night is its own place.** Indigo-earth, not inverted mist. Surfaces
   feel warmer and closer at night; hierarchy identical.

## B2. Information architecture

```
Home ─────────────┬─ Begin Walk (REAL — primary)
                  ├─ Demo Walk (secondary, engineering/preview)
                  ├─ Lira presence (skin, bond, last memory)
                  ├─ Memory History (push)
                  └─ Settings (sheet)
Active Session ───┬─ Presence surface (Lira, phrase, status, metrics)
                  ├─ Controls: Pause/Resume · End
                  ├─ GPS chip · compact map (+trace)
                  └─ AR (full-screen cover, controls mirrored)
Session Summary ──┴─ closing phrase · memory · receipts → Home
```

Modality rule (makes A2-6 explicit): **push** = walk lifecycle flow
(session, summary, history). **Sheet** = asides that pause nothing
(settings). **Full-screen cover** = immersion that must not dismiss by
accident (AR). No third level of navigation anywhere.

## B3. Home (redesign — folds in #126)

Order, top to bottom:

1. **Identity row** — wordmark small; Settings gear trailing.
2. **Lira card** — skin-correct still (Dormant when idle), bond filament
   progress, last memory line. This card is the emotional anchor; it is
   *not* a button (Lira is not a menu).
3. **Begin Walk** — the real walk. Primary prominent CTA, guide teal,
   ≥56 pt, full width. Starts permission flow with inline state feedback
   *on the button* (requesting → denied guidance → active), replacing the
   easily-missed status text (audit #126-5).
4. **Demo Walk** — secondary bordered button, explicitly labeled "Demo".
   Identifier `waykin.beginWalk` stays bound to demo for test continuity.
5. **Memory History** — tertiary, below the fold is acceptable.

Empty states: no memories yet → the Lira card carries a first-walk
invitation line instead of a blank.

## B4. Active Session (consolidation, not redesign)

The shipped session screen is fundamentally right. Spec changes only:

- **AR entry** moves beside the controls row (one-handed reach; it is the
  most-used button under #125's recovery reality).
- **AR presents as full-screen cover** with `interactiveDismissDisabled`,
  explicit ✕, and **Pause/End mirrored in AR chrome** — the walk is always
  controllable without leaving immersion.
- GPS chip and map stay exactly as shipped (#121/#123).
- Presence surface remains the a11y-contracted component (identity →
  presence → phrase → metrics → status; non-color channels; reduce-motion
  static). This contract is now *spec law*, not just test law.

## B5. Session Summary

Keep: closing phrase, memory text, calm single exit. Add (bounded
candidates): bond delta with filament mark animation (static under reduce
motion), walk stats row reusing session metric components, skin-correct
Lira still in Sanctuary or Bond pose per outcome.

## B6. AR surface

- One entity, always (registry semantics already enforce this).
- Chrome: top status strip (tracking state · Lira state · ✕), bottom
  mirrored Pause/End. Nothing else. The world is the UI.
- Continuity messaging: while #125 is open, when the companion is not
  visible (tracking loss/behind you), chrome shows a quiet directional
  hint ("Lira is behind you" / "looking for the ground") sourced from
  existing diagnostics — no new gameplay truth.

## B7. Canonical state crosswalk (resolves A2-1)

**Code authority:** `CompanionPresentationMatrix` + `LiraSessionPose.resolve` + `PathAudioCoupling` (see also `REAL_WALK_TO_AR_MAPPING.md`). This table is the design mirror.

| Canonical driver | Core behavior | AR string | Art still | Audio cue | Pressure ring |
|---|---|---|---|---|---|
| no event + moving | follow | follow | **Guide** | (behavior/event only) | calm |
| no event + paused | observe | investigate | **Guide**/dormant | quiet_shift on transition | calm |
| quietInterval / rest | rest | idle | **Sanctuary** (dormant if paused) | quiet_shift | calm |
| lead / companionMovesAhead / pursuitFades | lead | follow + far/ahead | **Guide** | companion_ahead / pursuit_release | fading on fade |
| drawNear / companionDrawsNear | drawNear | follow | **Bond** | companion_near | calm |
| bondMoment / celebrate | drawNear/celebrate | celebrate | **Bond** | bond_motif | calm |
| observe / distantPresence / familiarPlaceStirs | observe | investigate | **Guide**/manifesting lean | quiet_shift / distant | low |
| pursuitBegins / intensifies | follow | alert | **Hunter** | distant / pursuit_pressure | rising/thick |
| path strained (pursuit quiet) | unchanged | investigate | **Rival** lean | quiet_shift `path:strained` | integrity |
| path offPath (pursuit quiet) | unchanged | alert | **Hunter** lean | quiet_shift `path:offPath` | integrity |
| path recovered | unchanged | (matrix) | (matrix) | pursuitRelease `path:recovered` | ease |

Rules: art stills follow presence resolver priority (opening → pursuit → event → path → behavior). `Rival` remains reserved as a dedicated runtime driver; path lean may use rival/hunter stills only as *presentation* pressure.

## B8. Component library (as-built + gaps)

Shipped and spec-blessed: presence surface, phrase line, Path status chip,
GPS chip, metric pair, compact map (+trace), WKIconLabel controls, Lira
card/stills, bond filament mark, pressure ring. Gap candidates (each a
bounded issue): unified chip component (GPS/path/audio currently
hand-rolled thrice), inline-feedback button (Home CTA states), toast-free
status pattern (no toasts exist — keep it that way; status lives in
chips and phrases).

## B9. Motion language

Bounded pulses only (existing 1.6 s / 2.8 s rest), one-shot transitions
≤0.6 s ease, map camera 0.6 s ease. **Reduce Motion: every continuous
animation stops; state changes stay perceptible via geometry/text/still
swaps.** No parallax, no springs over 1.0 damping, no full-screen motion,
ever (H-pass law).

## B10. Accessibility contract (consolidated, already shipped)

Traversal: identity → presence → phrase → metrics → status → controls →
map. Values are human sentences; no raw enums, no coordinates, no debug
tokens; singular/plural correctness; ≥48 pt controls; non-color state
channels (ring thickness + text + still); VoiceOver-redundant phrase
suppression. Physical VoiceOver/outdoor evidence stays NOT_COMPUTABLE
until receipts say otherwise.

## B11. Forward surfaces (presentation seams only)

- **Glasses glance** (shipped, flag-off): phrase + pressure + metrics as
  2D HUD lines; same crosswalk table drives it; no new vocabulary.
- **Watch (reference-only)**: the glance contract is the Watch contract —
  design once, render twice.
- **AI Directors (RC)**: dialogue proposals render through the existing
  phrase line; Pathfinder intents through Path status + map. No new
  surfaces required — this is the point of the seam discipline.

## B12. Implementation backlog (bounded issue candidates, priority order)

1. ~~Home CTA inversion + AR full-screen~~ — **done** (#126 / PR #146)
2. ~~AR continuity hint chrome~~ — **done** (#147)
3. ~~Summary polish~~ — **done** (#148)
4. ~~Chip component unification~~ — **done** (#149)
5. ~~Icon authority + screenshot scaffolding~~ — **done** (#150)
6. Outdoor re-walk Pass COH (#41) — **device / daylight**
7. Optional: expand sim screenshot set (day/night × session/AR) under #150 script

## Ratification asks

1. Bless the crosswalk table (B7) as canonical, including `Rival` reserved.
2. Bless the modality rule (B2).
3. Confirm Home CTA inversion fix proceeds under #126 (already claimed).
4. Confirm screenshot set (backlog 3) as a new bounded issue.
