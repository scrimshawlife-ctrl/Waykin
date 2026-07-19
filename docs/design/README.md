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
| [GENERATED_LIRA_ART.md](GENERATED_LIRA_ART.md) | AI-generated spectral Lira art pack |
| [OUTDOOR_QA_CHECKLIST.md](OUTDOOR_QA_CHECKLIST.md) | Device outdoor checks |
| [OUTDOOR_QA_RECEIPT_TEMPLATE.md](OUTDOOR_QA_RECEIPT_TEMPLATE.md) | Fillable evidence receipt |
| [SIMULATOR_PREFLIGHT.md](SIMULATOR_PREFLIGHT.md) | Sim-only preflight |
| [SIM_CHECKLIST_AUTOMATION.md](SIM_CHECKLIST_AUTOMATION.md) | Manual S1–S8 → automated tests |
| [ART_DIRECTION_SIGN_OFF.md](ART_DIRECTION_SIGN_OFF.md) | Spectral Lira direction accepted |
| [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md) | AR mid-LOD + USDZ async load |
| [LIRA_ANIMATION_PLAN.md](LIRA_ANIMATION_PLAN.md) | Session + AR animation draft plan |
| [receipts/](receipts/) | Filled outdoor / sim receipts |

## Recommended order

1. Simulator preflight — **automated**
2. Sim checklist S1–S8 — **automated**
3. Spectral art direction — **DIRECTION_ACCEPTED**
4. AR mid-LOD Living Familiar — **procedural shipped**; USDZ slot ready
5. Outdoor walk + receipt — **deferred** (device required)
6. Optional: sculpted `Lira_AR_Base.usdz` artist mesh
