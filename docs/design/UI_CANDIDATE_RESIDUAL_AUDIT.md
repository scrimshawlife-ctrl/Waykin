# UI CANDIDATE_v0.2 residual audit

```yaml
document_id: WAYKIN-UI-CANDIDATE-RESIDUAL-001
version: 1.0
date: 2026-07-20
status: CURRENT
authority: SUPPORTING
issue: 194
main_tip_at_audit: 5619244 (capture set); land with issue #194
depends_on:
  - docs/design/UI_CANDIDATE_V02_POINTER.md
  - docs/design/WAYKIN_UIUX_SPEC.md
  - docs/design/UI_ENGINEERING_PRACTICE.md
  - docs/design/ui_candidate_v0.2/WK_TOKENS_v0.2.json
```

**Purpose:** Record what remains of Phase 4 candidate integration after waves already on main, without claiming outdoor proof or authorizing a full re-skin.

Evidence labels: `OBSERVED` / `INFERRED` / `NOT_COMPUTABLE`.

---

## 1. Summary

| Area | Status | Evidence |
|---|---|---|
| Echo day/night color tokens | **Aligned** (core semantic hex) | OBSERVED vs `WK_TOKENS_v0.2.json` + `App/Theme/WKTokens.swift` |
| Spacing / radius / motion numbers | **Aligned** | OBSERVED numeric parity |
| Typography primary (DM Sans) | **Partial** — system + `WaykinDisplay` splash face; DM Sans not bundled | OBSERVED code + font assets |
| Core Echo icons (`WKIcon`) | **Shipped** (31 template icons) | OBSERVED `WKIcons.swift` |
| Full candidate SVG icon pack | **Not imported 1:1** | INFERRED — app uses SwiftUI shapes, not full design-package SVG set |
| Screen graph (walk loop) | **Shipped** Home → Session → Summary → Memory | OBSERVED UI + UI tests |
| Mode cards Trail/Race/Hunt as product modes | **Presentation labels only** — MVP remains single walk activity | OBSERVED SOLO_MVP + UIUX |
| Bond viz orbital (non-XP) | **Partial** — bond filament / summary; not full production-board orbital | INFERRED vs candidate board |
| Onboarding / legal / safety | **Shipped** | OBSERVED onboarding flow |
| Sim screenshot matrix day/night × surfaces | **Shipped tooling + set** (issue #194) | OBSERVED under `docs/assets/screenshots/` |
| Outdoor day/night contrast | **NOT_COMPUTABLE** | #41 |

---

## 2. Token parity (OBSERVED)

Compared `docs/design/ui_candidate_v0.2/WK_TOKENS_v0.2.json` to `App/Theme/WKTokens.swift`.

### Colors (sample anchors)

| Role | Candidate | App | Match |
|---|---|---|---|
| Day background primary | `#E4E8EC` | `Day.background` | Yes |
| Day surface primary | `#F7F5F2` | `Day.surface` | Yes |
| Day text primary | `#141820` | `Day.textPrimary` | Yes |
| Day guide | `#3F8F8A` | `Day.guide` | Yes |
| Day bond | `#D4A45A` | `Day.bond` | Yes |
| Night background primary | `#12151C` | `Night.background` | Yes |
| Night surface primary | `#1E2430` | `Night.surface` | Yes |
| Night text primary | `#E6EAF0` | `Night.textPrimary` | Yes |
| Night guide | `#4A9E98` | `Night.guide` | Yes |
| Safety pause day/night | `#5F7F72` / `#6F8F82` | matches | Yes |

Night is **not** an invert of day (indigo-earth surfaces). Unit tests assert selected hex parity (`WKSessionChromeTests`).

### Spacing / radius / motion

| Token | Candidate | App |
|---|---|---|
| xs–3xl scale | 4…48 | `Space.xs`…`xxxl` same numbers |
| screen margin x | 24 | `screenMarginX` 24 |
| min touch | 48 | `minTouch` 48 |
| radius medium | 14 | `Radius.medium` 14 |
| standard motion | 220 ms | `Motion.standard` 0.22 s |

**Residual:** candidate `background.night.deep` (`#0C0E12`) and some text soft aliases are not all exposed as named app tokens; not required for shipped screens.

---

## 3. Typography residual

| Spec | App | Residual action |
|---|---|---|
| DM Sans primary | Not packaged | Keep system UI font for body; do **not** claim DM Sans until OFL package is deliberately bundled |
| Display brand face | `WaykinDisplay-Regular` (splash + `WaykinTypography`) | Done (#184) |
| Dynamic Type | System styles + tests smoke | Continue via UI practice receipt |

No change required for MVP unless product prioritizes DM Sans licensing + bundle.

---

## 4. Icons residual

`WKIcon` cases (31): home, beginSession, companion, bond, history, settings, pause, resume, stop, companionAhead/Behind, caution, sanctuary, audio, haptics, safetyPause, trackingLoss, routeCertainty, trail, race, hunt, guide, rival, hunter, dormant, recovering, bonded, location, battery, motion, permissionRequired.

| Residual | Priority | Notes |
|---|---|---|
| Import missing candidate SVGs only if a shipped screen needs a symbol not covered | Low | Prefer existing shapes |
| Trail/Race/Hunt icons present | — | Do not promote to new MVP activity modes |

---

## 5. Screen graph residual

| Candidate stage | App | Residual |
|---|---|---|
| Launch / splash | Time-aware splash (#184) | Optional polish only |
| Home + Begin + Demo | Shipped (Begin primary) | None for product law |
| Active session + pause | Shipped | AR outdoor #41 |
| Summary + bond + memory | Shipped | Optional filament animation polish (UIUX B5) |
| Settings | Sheet | None blocking |
| Session selection Trail/Race/Hunt | **Out of MVP product scope** as separate activities | Keep presentation only |

---

## 6. Evidence artifacts

| Artifact | Class |
|---|---|
| `docs/assets/screenshots/sim_*/` | SIMULATOR |
| This audit | SUPPORTING documentation |
| Outdoor COH | Still #41 — do not upgrade from this audit |

---

## 7. Recommended next residuals (ordered)

1. Keep sim matrix current after material UI PRs (`WAYKIN_CAPTURE_FULL=1 ./scripts/capture_sim_screenshots.sh`).
2. Indoor device smoke of AR hybrid chrome when phone available (still not outdoor).
3. #41 daylight outdoor when human resumes.
4. Optional: DM Sans bundle or extra icon SVGs only with a dedicated issue.

## Explicit non-work

- Second design authority tree
- CloudKit / WP-DB6 without product need
- Expanding AR under freeze
- Claiming outdoor contrast PASS from this audit
