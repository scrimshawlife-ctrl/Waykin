# Lira Cosmetics Skins + Home Presence (Issue #61)

```yaml
issue: 61
status: IN_APP_PRESENTATION
skins: [Dawn, Veil, Rupture]
mechanics: cosmetic_only
marketplace: false
outdoor_qa: deferred
```

## What shipped

| Item | Path |
| ---- | ---- |
| Skin enum + materials | `App/Theme/LiraSkin.swift` |
| Figure respects skin | `LiraSessionFigure` |
| Home presence + picker | `HomeView` |
| Persistence | `UserDefaults` key `waykin.lira.skin` |
| Tests | `AppTests/LiraSkinTests.swift` |

## Rules

- Same poses and A1–A3 anchors for all skins
- Dawn is default
- No unlock economy / paywall
- Hunter language remains echo/asymmetry (skin only shifts materials)

## User surface

Home → Form row (Dawn / Veil / Rupture) → selection updates session Lira immediately.
