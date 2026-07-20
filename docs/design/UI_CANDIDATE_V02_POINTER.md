# UI candidate package pointer (active pivot)

```yaml
document_id: WAYKIN-UI-CANDIDATE-POINTER-001
status: ACTIVE_PIVOT
date: 2026-07-20
package: WK_EXPORT_CANDIDATE_v0.2
design_root: /Users/appliedalchemylabs/Waykin-Design
candidate: 11_Approved-Exports/CANDIDATE_v0.2/
approved_for_export: false
integrated: false
```

## Source of truth (design)

Sibling package **Waykin-Design** (not auto-merged into app):

| Start | Path |
| ----- | ---- |
| Package README | `Waykin-Design/11_Approved-Exports/CANDIDATE_v0.2/README.md` |
| Integration order | `…/docs/PHASE_4_INTEGRATION_RUNBOOK.md` |
| Checklist | `…/INTEGRATION_CHECKLIST.md` |
| Handoffs HO-001–005 | `Waykin-Design/ENGINEERING_HANDOFF.md` + candidate `docs/ENGINEERING_HANDOFF.md` |
| Tokens | `…/tokens/WK_TOKENS_v0.2.json` |
| Swift reference | `…/theme_maps/WK_Tokens_SwiftUI_Reference.swift` |
| UI board | `…/ui/WK_UI_Production_Board_v0.2.html` |
| Components | `…/ui/WK_UI_Component_Library_v0.2.md` |
| Icons | `…/icons/` + `WK_ICON_MANIFEST_v0.2.json` |
| Brand | `…/brand/` Bond Filament mark + app icon |

In-repo UIUX (older / complementary):

- [WAYKIN_UIUX_SPEC.md](WAYKIN_UIUX_SPEC.md)
- [WAYKIN_UIUX_SPEC_MOCKUPS.html](WAYKIN_UIUX_SPEC_MOCKUPS.html)
- [docs/assets/BRAND_GUIDE.md](../assets/BRAND_GUIDE.md)

Prefer **CANDIDATE_v0.2** when the two diverge on tokens, chrome density, or screen graph.

## App already partial

| Area | Status in Waykin app |
| ---- | -------------------- |
| Echo tokens day/night | **Partial** — `App/Theme/WKTokens.swift` cites `WK_TOKENS_v0.2` |
| `WKTheme` injector | **Present** |
| Reduce motion (session + AR) | **Partial / substantial** |
| Lira companion stills + AR mid-LOD | **Shipped** (separate art ladder) |
| Full icon set from candidate | **Audit vs** `WKIcons.swift` + SVG import |
| Screen graph (Home→…→Bond) | **Partial** — product screens exist; align to Stage 6 IDs |
| Mode cards Trail/Race/Hunt | **Product modes exist**; match component library |
| Bond viz (orbital, not XP) | **Check vs** bond summary UI |

## Phase 4 integration order (from runbook)

1. Tokens + type + day/night (align/verify HO-001)  
2. Home + Begin + minimal settings  
3. Active session + pause + safety pause  
4. Companion presence chrome  
5. Mode selection + prep  
6. Sanctuary + summary + bond  
7. Skins polish  
8. Full icon set  
9. Onboarding / permissions / safety brief  

## Must not

- Fitness dashboard home  
- Map-as-default  
- Social / multiplayer chrome  
- XP-bar bond  
- Marketplace  

## Parked elsewhere

AR outdoor + size/DCC follow-ups: [DEFERRED_RECOMMENDATIONS.md](DEFERRED_RECOMMENDATIONS.md)
