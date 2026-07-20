# Waykin UI Engineering Practice

```yaml
document_id: WAYKIN-UI-ENGINEERING-PRACTICE-001
version: 1.0
status: CURRENT
authority: SUPPORTING
maturity: CURRENT
scope: iPhone App presentation (SwiftUI) for the walking MVP
depends_on:
  - docs/governance/DOCUMENT_AUTHORITY.md
  - docs/SOLO_MVP_SCOPE.md
  - docs/design/WAYKIN_UIUX_SPEC.md
  - docs/design/UI_CANDIDATE_V02_POINTER.md
  - ARCHITECTURE.md
companion:
  - docs/design/UI_CHANGE_VALIDATION_RECEIPT.md
source: Distilled best practices from PR #169; product surface law remains in WAYKIN_UIUX_SPEC
```

**This document is process and architecture practice.** It does **not** redefine product screens, Lira states, Demo vs Real, AR chrome, or Echo tokens.

When anything here conflicts with a higher-authority source, follow [`DOCUMENT_AUTHORITY.md`](../governance/DOCUMENT_AUTHORITY.md). Prefer the narrower walking MVP over broader interaction patterns.

---

## 1. Document map (what to open for what)

| Need | Open first | Authority |
|---|---|---|
| What screens mean, Lira/Demo/Real/AR, B7 crosswalk | [`WAYKIN_UIUX_SPEC.md`](WAYKIN_UIUX_SPEC.md) | DESIGN_REFERENCE (product UI) |
| Tokens, chrome density, candidate board | [`UI_CANDIDATE_V02_POINTER.md`](UI_CANDIDATE_V02_POINTER.md) | ACTIVE_PIVOT for design package |
| Core vs App vs presentation ownership | [`ARCHITECTURE.md`](../../ARCHITECTURE.md) | Binding |
| Outdoor / physical proof | [`OUTDOOR_QA_CHECKLIST.md`](OUTDOOR_QA_CHECKLIST.md), issue #41 | Evidence gate |
| Material UI PR evidence | [`UI_CHANGE_VALIDATION_RECEIPT.md`](UI_CHANGE_VALIDATION_RECEIPT.md) | SUPPORTING checklist |
| How to structure views and state | **This file** | SUPPORTING |

Do **not** invent a second “canonical UI law” tree. Product look-and-feel and companion truth live in the UIUX spec and code (`CompanionPresentationMatrix`, presence resolvers). This file only constrains *how* App presentation is implemented and reviewed.

---

## 2. Scope hard limits (MVP)

- Primary activity: **walking**. Do not expand UI contracts or validation matrices to running, cycling, or multi-sport until product scope promotes them.
- One companion (Lira). Presentation interprets canonical state; it never invents bond, pursuit, or path truth.
- Demo sessions must remain visually and verbally distinguishable from real walks.
- Outdoor readability, AR tracking quality, battery, and real GPS are **not** proven by green CI or simulator alone.

---

## 3. Layer boundaries (App presentation)

Align with binding architecture: **WaykinCore owns semantic gameplay truth.** App owns adapters and presentation.

```text
WaykinCore (domain)
  movement, path progress, companion runtime, events, audio cue intent, memory
        ↓
App model / session controllers
  lifecycle, permissions, adapters, navigation, presentation snapshots
        ↓
SwiftUI views
  layout, controls, a11y, animation, dispatch of user intents
```

### Views must not

- Calculate bond progression or invent companion behavior from ad-hoc booleans.
- Decide movement-sample acceptance or path integrity.
- Coordinate HealthKit, location, audio, persistence, or AR adapters directly from a button closure without going through the application action surface.
- Assert product capabilities that adapters have not actually enabled.

### Views may own only ephemeral UI state

Sheet visibility, confirmation dialogs, focus, local disclosure, short-lived animation phase, uncommitted draft input.

Canonical session, permission, navigation destination, companion, and persistence state belong in application models—not duplicated into loosely synced `@State` flags.

---

## 4. Presentation snapshots

Compress high-rate or multi-source domain state into **immutable, screen-specific** values before the view tree.

Properties of a good snapshot:

- `Equatable` and cheap to compare.
- Already formatted for display (human strings, not raw enums or coordinates in user-facing fields).
- Derived from one canonical source (or a documented pure function of that source).
- Safe to pass into previews and UI tests without live adapters.

Prefer explicit enums with associated values for session lifecycle (preparing / active / paused / ending / completed / failed) over interlocking booleans.

When presentation and domain disagree, **domain wins**; fix the snapshot derivation.

---

## 5. Product surface contracts (summary only)

Full screen design remains in [`WAYKIN_UIUX_SPEC.md`](WAYKIN_UIUX_SPEC.md). Practice rules that implementers must not regress:

| Surface | Practice rule |
|---|---|
| **Home** | One high-emphasis CTA: real **Begin Walk**. Demo is secondary and labeled Demo. Lira card is presence, not a menu. |
| **Active session** | Glance hierarchy: companion/session state → primary metric → material signal exception → Pause/Resume → End. No dense feeds. |
| **AR** | Full-screen cover; Pause/End mirrored; no accidental swipe-dismiss of the walk. Continuity hints are presentation of existing diagnostics only. |
| **Settings** | Sheet from Home; does not own walk lifecycle. |
| **Summary / Memory** | Calm reflection; single clear exit; no raw diagnostics. |
| **Map** | Supporting context only; must never obscure Pause/End. |

Modality rule (product law): **push** = walk lifecycle; **sheet** = asides; **full-screen cover** = immersion that must not dismiss by accident.

---

## 6. Accessibility (structural, not a pass at the end)

Shipped contract (UIUX B10) remains authoritative for traversal and non-color channels. Additional practice:

- Prefer native SwiftUI accessibility APIs before custom `accessibility*` sprawl.
- Critical controls: ≥44×44 pt hit targets; active-session primary controls should generally exceed that; UIUX already targets ≥48 pt where shipped.
- No state communicated **only** by color, motion, haptics, or audio.
- Reduce Motion: continuous decorative animation stops; state change remains perceptible via text, geometry, or still swap.
- Dynamic Type: primary content must remain usable at largest accessibility sizes on the smallest supported phone.
- VoiceOver order follows product hierarchy (identity → presence → phrase → metrics → status → controls → map).

Physical VoiceOver and outdoor a11y remain **NOT_COMPUTABLE** until receipts say otherwise.

---

## 7. Tokens and visual system

- Prefer existing Echo / candidate tokens over new per-screen constants.
- Night is its own place (indigo-earth), not inverted day—see brand and UIUX B1.
- New token only when a stable semantic role repeats; do not mint hex for one-off polish.
- When candidate package and in-repo UIUX diverge on tokens or chrome density, follow [`UI_CANDIDATE_V02_POINTER.md`](UI_CANDIDATE_V02_POINTER.md) for integration work; do not fork a third token system in App views.

---

## 8. Engineering definition of done (material UI)

A material UI change is done only when:

1. It matches product surface law in [`WAYKIN_UIUX_SPEC.md`](WAYKIN_UIUX_SPEC.md) (or updates that spec in the same PR when the product design intentionally changes).
2. Presentation is derived from canonical state (no presentation drift).
3. Empty / loading / degraded / error / success paths that users can hit are defined and truthful.
4. Light / dark (and increased contrast if materials are used) are checked.
5. Dynamic Type and smallest supported layout do not clip primary actions or state.
6. Reduce Motion does not leave stranded continuous motion.
7. Automated coverage matches risk (unit for snapshot derivation; UI smoke for core flow when navigation or controls change).
8. Active-session or sensor-dependent changes have **physical-device** evidence (or explicit `NOT_COMPUTABLE` + residual risk).
9. No unsupported product claim (AR, HealthKit, glasses, outdoor quality, etc.).
10. Receipt template filled when required—see [`UI_CHANGE_VALIDATION_RECEIPT.md`](UI_CHANGE_VALIDATION_RECEIPT.md).

---

## 9. Prohibited patterns

Unless an approved issue explicitly allows an exception:

- Fixed-size text for primary content
- Icon-only **critical** controls during active session
- Color-only state communication
- Custom back gestures or hidden essential controls
- Auto-advancing critical content
- Non-dismissible blocking overlays without a recovery path
- Nested scroll views on core walk surfaces
- Arbitrary per-screen design tokens outside the theme layer
- Runtime truth duplicated into view-local flags
- Decorative animation that continues under Reduce Motion
- Unbounded map overlays or event feeds on the session screen
- User-facing raw diagnostic strings or coordinates
- Forced dark mode as a substitute for adaptive design
- Full-width edge-to-edge controls that ignore safe margins
- Claims that AR, glasses, HealthKit, or companion systems are active when adapters are off or unavailable
- Treating Demo metrics as real-walk evidence

---

## 10. Decision rubric

When two implementations both work, prefer the one that:

1. Reduces time to understand current state
2. Reduces interaction count
3. Uses a system convention
4. Remains usable without sight, color perception, precise touch, or audio alone
5. Degrades gracefully when adapters fail
6. Is easier to test deterministically
7. Adds less rendering and state complexity
8. Preserves Waykin identity without obscuring function

---

## 11. Change protocol

| Change type | Docs to touch |
|---|---|
| Product screen graph, Demo/Real, AR modality, B7-class state meaning | `WAYKIN_UIUX_SPEC.md` (+ mockups if layout changes) |
| Token / candidate chrome integration | Candidate pointer + import docs |
| Presentation architecture pattern (new snapshot style, new forbidden pattern) | This file |
| Outdoor / field claims | Outdoor QA docs + receipts; never this file alone |
| Scope expansion (e.g. run/cycle) | SOLO_MVP / product spec first—not a UI-only PR |

Material UI PRs should either update the relevant design doc or state why the existing contract still holds.

---

## 12. Explicit non-goals of this document

- Not a second product design system
- Not authorization to expand activity types
- Not a substitute for outdoor issue #41
- Not a mandate to rewrite shipped views into a new component framework
- Not a parallel `Docs/UI/` authority tree (supersedes PR #169’s structure)
