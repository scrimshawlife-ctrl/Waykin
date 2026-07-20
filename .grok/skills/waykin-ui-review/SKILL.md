---
name: waykin-ui-review
description: >
  Review Waykin SwiftUI screens against product UI law, tokens, a11y, and
  UI_ENGINEERING_PRACTICE. Use when /waykin-ui-review, UI review, SwiftUI
  hierarchy, Dynamic Type, or HIG check for Waykin.
metadata:
  short-description: "Waykin SwiftUI / UX review"
  pack: waykin-skill-pack
  version: "1.0.0"
---

# waykin-ui-review

Review **Waykin** presentation only. Authority order:

1. `docs/governance/DOCUMENT_AUTHORITY.md`
2. `docs/design/WAYKIN_UIUX_SPEC.md` (product surfaces, Demo/Real, AR modality, B7)
3. `docs/design/UI_ENGINEERING_PRACTICE.md` + `UI_CHANGE_VALIDATION_RECEIPT.md`
4. `docs/design/UI_CANDIDATE_V02_POINTER.md` (tokens when diverging)
5. Apple HIG — only where not overridden by product law

## 0. Scope inventory

List App screens from code (do not invent):

```bash
cd "$(git rev-parse --show-toplevel)"
rg -n 'struct \w+View|navigationDestination|fullScreenCover|sheet' App --glob '*.swift' | head -80
```

Canonical product surfaces: **Home, Active Session, Summary, Memory, Settings, Onboarding, AR cover, Session map**.

## 1. Product law checks (blocking if regressed)

| Law | Check |
|-----|--------|
| Begin Walk primary | Real walk CTA dominant; Demo secondary + labeled |
| Modality | push = lifecycle; sheet = Settings; fullScreenCover = AR |
| One companion | Lira presence; no dual animating entities |
| Walking only | No run/bike MVP contracts |
| Presentation truth | No invented Bond/path/state |
| Tokens | Echo day/night via `App/Theme/WKTokens.swift` — night not invert |

## 2. Per-screen evaluation

For each changed or requested screen, score:

1. **Hierarchy** — one primary action; glance order (session: state → metric → exception → Pause → End)
2. **Spacing** — `WKTokens.Space` / minTouch 48
3. **Dynamic Type** — no fixed-size primary text
4. **Contrast** — day mist / night indigo-earth; Increase Contrast if materials
5. **A11y** — labels; non-color state; VO order identity→presence→phrase→metrics→status→controls→map
6. **Motion** — Reduce Motion stops continuous decoration
7. **Performance** — high-rate updates via presentation snapshots; avoid full-tree invalidation
8. **HIG** — system nav/sheets first

Read concrete files: `App/WaykinApp.swift`, `App/CompanionPresenceView.swift`, `App/Theme/*`, `App/Onboarding/*`, `App/SessionMapViews.swift`.

## 3. Output

```markdown
## Waykin UI review
- SHA:
- Screens reviewed:

### Blocking (must fix)
- file:line — issue — fix

### Important
- ...

### Suggestions
- ...

### Product-law compliance
| Rule | Status |
|------|--------|
| Begin Walk primary | PASS/FAIL |
| AR full-screen cover | PASS/FAIL |
| Demo labeled | PASS/FAIL |

### Evidence class for any visual claim
OBSERVED (code/sim) | NOT_COMPUTABLE (outdoor/device)
```

Recommend **concrete code** changes (identifiers, token names). No generic “improve spacing” without a file path.