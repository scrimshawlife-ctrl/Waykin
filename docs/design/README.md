# Waykin Design Integration Docs

Visual system imports and production follow-ons for the app repository.

## AR product redesign (SUPPORTING — recovered post-freeze)

| Doc | Purpose | Class |
| --- | ------- | ----- |
| [AR_PRODUCT_REDESIGN_MAP.md](AR_PRODUCT_REDESIGN_MAP.md) | Master map: identity, architecture envelope, freeze rings, target IA | SUPPORTING / NEAR_TERM |
| [AR_SYSTEM_INVENTORY.md](AR_SYSTEM_INVENTORY.md) | File-level AR / presentation inventory (Ember Fox runtime) | SUPPORTING |
| [AR_SESSION_IA_CONFLICTS.md](AR_SESSION_IA_CONFLICTS.md) | Active Session IA conflicts (C1–C11) | SUPPORTING |
| [PRODUCT_VISION_NORTH_STAR.md](PRODUCT_VISION_NORTH_STAR.md) | Long-term multi-activity / worldbuilding / creators vision | REFERENCE_ONLY / FUTURE |
| [../canonical/MVP_TO_VISION_LADDER.md](../canonical/MVP_TO_VISION_LADDER.md) | Gated R0–R8 MVP → vision ladder | SUPPORTING |
| [../plans/AR_APP_REDESIGN_PLAN.md](../plans/AR_APP_REDESIGN_PLAN.md) | Phased plan (Phase 0 law → evidence → AR-default UX) | SUPPORTING |

**Authority:** these docs **do not** override binding product law or AR MVP freeze. Phase 0 binding edits are a separate PR. Implementation waits for freeze + device honesty (see CONTINUATION_PLAN).

**Operator direction (intent):** design for **AR** as primary session surface when capable; movement remains gameplay authority; audio is supporting/fallback. Binding docs may still say audio-first until Phase 0.

## UI product vs engineering practice

| Doc | Purpose | Class |
| --- | ------- | ----- |
| [WAYKIN_UIUX_SPEC.md](WAYKIN_UIUX_SPEC.md) | Product UI surfaces, Demo/Real, AR modality, B7 crosswalk | DESIGN_REFERENCE |
| [UI_CANDIDATE_V02_POINTER.md](UI_CANDIDATE_V02_POINTER.md) | Design package tokens/chrome integration | ACTIVE_PIVOT |
| [UI_ENGINEERING_PRACTICE.md](UI_ENGINEERING_PRACTICE.md) | Supporting SwiftUI practice, DoD, prohibited patterns | SUPPORTING |
| [UI_CHANGE_VALIDATION_RECEIPT.md](UI_CHANGE_VALIDATION_RECEIPT.md) | Material UI PR / RC evidence checklist | SUPPORTING |
| [UI_CANDIDATE_RESIDUAL_AUDIT.md](UI_CANDIDATE_RESIDUAL_AUDIT.md) | CANDIDATE_v0.2 residual vs shipped app | SUPPORTING |
| [DEBUG_OPERATOR_CONTINUATION.md](DEBUG_OPERATOR_CONTINUATION.md) | Operator debug D5–D7 plan (map/persistence/font) | SUPPORTING |
| [INDOOR_AR_HYBRID_SMOKE.md](INDOOR_AR_HYBRID_SMOKE.md) | Indoor device Ember Fox AR smoke (fallback→authored replace) | Evidence protocol |
| [OUTDOOR_QA_CHECKLIST.md](OUTDOOR_QA_CHECKLIST.md) | Outdoor device UI checks (#41) | Evidence gate |
| [TESTFLIGHT_RC_CHECKLIST.md](TESTFLIGHT_RC_CHECKLIST.md) | Internal TestFlight / RC engineering checklist | SUPPORTING |

## Integration and art track

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
| [OUTDOOR_SESSION_PACKET.md](OUTDOOR_SESSION_PACKET.md) | Operator runbook (UI + AR #41) |
| [OUTDOOR_QA_CHECKLIST.md](OUTDOOR_QA_CHECKLIST.md) | Device outdoor UI checks |
| [OUTDOOR_QA_RECEIPT_TEMPLATE.md](OUTDOOR_QA_RECEIPT_TEMPLATE.md) | Fillable evidence receipt |
| [SIMULATOR_PREFLIGHT.md](SIMULATOR_PREFLIGHT.md) | Sim-only preflight |
| [SIM_CHECKLIST_AUTOMATION.md](SIM_CHECKLIST_AUTOMATION.md) | Manual S1–S8 → automated tests |
| [ART_DIRECTION_SIGN_OFF.md](ART_DIRECTION_SIGN_OFF.md) | Spectral Lira direction accepted |
| [LIRA_AR_PRODUCTION_RIG.md](LIRA_AR_PRODUCTION_RIG.md) | AR mid-LOD + USDZ async load |
| [LIRA_AR_SCULPT_PLAN.md](LIRA_AR_SCULPT_PLAN.md) | **Production sculpt** AR package (issue #220; replace Meshy interim) |
| [LIRA_ANIMATION_PLAN.md](LIRA_ANIMATION_PLAN.md) | Session + AR animation draft plan |
| [CONTINUATION_PLAN.md](CONTINUATION_PLAN.md) | Freeze-then-build continuation (device evidence → optional redesign) |
| [AR_MVP_FREEZE.md](AR_MVP_FREEZE.md) | AR presentation frozen for engineering |
| [REAL_WALK_TO_AR_MAPPING.md](REAL_WALK_TO_AR_MAPPING.md) | Real/demo walk → AR commands |
| [PATHFINDING.md](PATHFINDING.md) | Semantic path progress + summary surfacing |
| [HEALTHKIT.md](HEALTHKIT.md) | Optional HealthKit enrichment + energy bias |
| [EVENT_WEIGHT_TUNING.md](EVENT_WEIGHT_TUNING.md) | Companion-first defaultRules light tune |
| [receipts/](receipts/) | Filled outdoor / sim / indoor smoke receipts |
| [receipts/samples/](receipts/samples/) | Field-test JSON format samples (not device PASS) |

## Recommended order (2026-07-25)

1. Design / presentation / AR mid-LOD / Hallmark polish — **complete on main** (see CONTINUATION_PLAN v4.1)
2. **AR-F freeze** — maintenance/defects only unless #41 or scoped issue
3. Path + HealthKit v1.1 — **shipped**; do not expand without promotion
4. **Indoor device smoke** — human PENDING receipt
5. **Internal TestFlight** — 0.9.0 (2); archive when signing ready
6. **Outdoor #41** — daylight COH; not inventable from sim
