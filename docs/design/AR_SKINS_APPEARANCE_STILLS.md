# AR Skins, Appearance Force, Session Stills (Issue #63)

```yaml
issue: 63
status: IN_APP_PRESENTATION
outdoor_qa: NOT_COMPUTABLE
sim_preflight: scripts/sim_walk_preflight.sh
```

## 1. AR factory skins

`CompanionEntityFactory(skin:)` applies Dawn / Veil / Rupture UIKit palettes.
`ARWorldCommandRenderer.companionSkin` + AR sheet pass selected form from Home.

## 2. Appearance force

Settings → Appearance: Auto / Day / Night
`preferredColorScheme` from `AppearancePreference` (UserDefaults).
Echo night is not invert of day.

## 3. Session stills

Asset catalog `LiraStills/*` PNG masters (from SVG).
`LiraStillCatalog` prefers still when present; else Canvas puppet.

| Still | Pose | Skin |
| ----- | ---- | ---- |
| Lira_Session_Guide_Dawn | guide | dawn |
| Lira_Session_Hunter_Dawn | hunter | dawn |
| Lira_Session_Sanctuary_Dawn | sanctuary | dawn |
| Lira_Session_Guide_Veil | guide | veil |
| Lira_Session_Guide_Rupture | guide | rupture |

## 4. Simulator walk

```bash
./scripts/sim_walk_preflight.sh
```

Writes receipt under `docs/design/receipts/SIM_PREFLIGHT_*` with evidence_class `OBSERVED_IN_SIMULATOR_ONLY`.
