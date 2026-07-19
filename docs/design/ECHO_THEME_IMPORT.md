# Echo Theme Import (Issue #50)

```yaml
issue: 50
phase: 4_step_1
status: IN_APP_PRESENTATION
source_package: Waykin-Design CANDIDATE_v0.2
token_version: WK_TOKENS_v0.2
companion_name: Lira
waykin_core_touched: false
outdoor_qa: NOT_COMPUTABLE
outdoor_protocol: docs/design/OUTDOOR_QA_CHECKLIST.md
receipt_template: docs/design/OUTDOOR_QA_RECEIPT_TEMPLATE.md
```

## What shipped

| Item | Path |
| ---- | ---- |
| Theme tokens | `App/Theme/WKTokens.swift` |
| Presence / session chrome | `App/CompanionPresenceView.swift` |
| Home / Active / Summary wiring | `App/WaykinApp.swift` |
| Brand guide update | `docs/assets/BRAND_GUIDE.md` |
| Focused tests | `AppTests/WKTokensTests.swift` |

## Explicitly deferred

- Full icon SVG set
- Production companion art / skins
- AR entity material rewrite
- Bond Filament app-icon store sizes
- Claiming APPROVED_FOR_EXPORT or INTEGRATED

## Next slices

1. Icons (pause, ahead/behind, bond, caution, modes)
2. Brand mark + app icon
3. Presence polish against behavior/pursuit mapping
