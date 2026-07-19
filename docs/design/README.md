# Waykin Design Integration Docs

Visual system imports and production follow-ons for the app repository.

| Doc | Purpose |
| --- | ------- |
| [ECHO_THEME_IMPORT.md](ECHO_THEME_IMPORT.md) | Tokens Phase 4 step 1 |
| [ECHO_ICONS_BRAND_IMPORT.md](ECHO_ICONS_BRAND_IMPORT.md) | Icons + Bond Filament |
| [APPICON_LIRA_ECHO_IMPORT.md](APPICON_LIRA_ECHO_IMPORT.md) | App Icon + Lira Echo placeholder |
| [LIRA_PRODUCTION_ART_PIPELINE.md](LIRA_PRODUCTION_ART_PIPELINE.md) | **Production art path for Lira** |
| [LIRA_SESSION_MID_PUPPET.md](LIRA_SESSION_MID_PUPPET.md) | Session-mid multi-pose puppet in app |
| [LIRA_SKINS_HOME.md](LIRA_SKINS_HOME.md) | Dawn/Veil/Rupture cosmetics + Home presence |
| [AR_SKINS_APPEARANCE_STILLS.md](AR_SKINS_APPEARANCE_STILLS.md) | AR skins, appearance force, stills, sim walk |
| [LIRA_DAWN_STILLS_GLYPH.md](LIRA_DAWN_STILLS_GLYPH.md) | Full Dawn stills + glyph LOD |
| [LIRA_FULL_STILL_MATRIX.md](LIRA_FULL_STILL_MATRIX.md) | Full Dawn/Veil/Rupture pose still matrix |
| [OUTDOOR_QA_CHECKLIST.md](OUTDOOR_QA_CHECKLIST.md) | Device outdoor checks |
| [OUTDOOR_QA_RECEIPT_TEMPLATE.md](OUTDOOR_QA_RECEIPT_TEMPLATE.md) | Fillable evidence receipt |
| [SIMULATOR_PREFLIGHT.md](SIMULATOR_PREFLIGHT.md) | Sim-only preflight |
| [receipts/](receipts/) | Filled outdoor receipts |

## Recommended order

1. Simulator preflight (`./scripts/sim_walk_preflight.sh`) — done in-repo
2. Outdoor walk + receipt — **deferred**
3. Production art pipeline session mid — **Dawn stills complete**
4. Glyph LOD — **shipped**
5. Veil/Rupture full pose stills — **shipped**
6. Next: outdoor walk when ready, or painted/sculpted rig when art exists
