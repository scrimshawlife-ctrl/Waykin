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

## How this fits other UI docs

| Need | Document | Class |
|---|---|---|
| **Product surfaces** (Home/Demo/Real, AR, B7 crosswalk, components) | **This file** | DESIGN_REFERENCE |
| Tokens / candidate chrome package | [`UI_CANDIDATE_V02_POINTER.md`](UI_CANDIDATE_V02_POINTER.md) | ACTIVE_PIVOT |
| SwiftUI practice, DoD, prohibited patterns | [`UI_ENGINEERING_PRACTICE.md`](UI_ENGINEERING_PRACTICE.md) | SUPPORTING |
| Material UI PR evidence template | [`UI_CHANGE_VALIDATION_RECEIPT.md`](UI_CHANGE_VALIDATION_RECEIPT.md) | SUPPORTING |
| Outdoor physical proof | [`OUTDOOR_QA_CHECKLIST.md`](OUTDOOR_QA_CHECKLIST.md), #41 | Evidence gate |
| Conflicts | [`DOCUMENT_AUTHORITY.md`](../governance/DOCUMENT_AUTHORITY.md) | Binding precedence |

Engineering practice docs **must not** override screen contracts, Demo/Real priority, AR modality, or companion state meaning defined here. Walking remains the only primary activity unless product scope documents change.

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

> **Historical audit snapshot** from the outdoor PARTIAL / pre–#126 era. **Do not treat open High rows as current main truth.** Remediation status is in the right column; live backlog is B12.

| ID | Severity | Finding | Status on main |
|---|---|---|---|
| A2-1 | **High** | Four state vocabularies with no canonical crosswalk. | **Mitigated** — B7 + `CompanionPresentationMatrix` |
| A2-2 | **High** | Home demo-primary CTA inverted product priority (#126). | **Fixed** — real Begin Walk primary; Demo secondary |
| A2-3 | **High** | AR swipe-dismissible sheet covering Pause/End (#126). | **Fixed** — fullScreenCover + mirrored controls |
| A2-4 | Medium | Empty `docs/assets/screenshots/`. | **Partial** — capture script + sim home capture; expand day/night optional |
| A2-5 | Medium | Dual icon raster authority. | **Documented** — BRAND_GUIDE icon authority (#150) |
| A2-6 | Low | Sheet vs cover modality implicit. | **Documented** — B2 modality rule; AR is cover |
| A2-7 | Low | Debug/UI-test blocks on Home. | Open polish; flag-gated |

---

# Part B — Comprehensive UI/UX Design

**Visual companions (SIMULATOR / concept class, not outdoor proof):**
- HTML mockup page: [`WAYKIN_UIUX_SPEC_MOCKUPS.html`](WAYKIN_UIUX_SPEC_MOCKUPS.html)
- Day/night PNG renders: [`docs/assets/mockups/uiux-spec-v0.1/`](../assets/mockups/uiux-spec-v0.1/)
- PDF companion: [`WAYKIN_UIUX_SPEC_VISUAL_COMPANION.pdf`](WAYKIN_UIUX_SPEC_VISUAL_COMPANION.pdf)

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
7. ~~Sim screenshot matrix day/night × home/session/summary~~ — **done tooling + set** (#194; AR frame still manual/sim-only)

## Ratification asks

1. Bless the crosswalk table (B7) as canonical, including `Rival` reserved — **code authority already cites it**.
2. Bless the modality rule (B2) — **AR cover + settings sheet shipped**.
3. ~~Home CTA inversion (#126)~~ — **done**.
4. Screenshot set — scaffolding + one sim capture shipped; optional expansion under existing capture script.
