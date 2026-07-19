# App Icon + Lira Echo Materials Import (Issue #55)

```yaml
issue: 55
phase: 4_step_3
status: IN_APP_PRESENTATION
depends_on: [50, 52]
companion_name: Lira
waykin_core_touched: false
outdoor_qa: NOT_COMPUTABLE
production_sculpted_mesh: false
```

## What shipped

| Item | Path |
| ---- | ---- |
| App Icon asset catalog | `App/Resources/Assets.xcassets/AppIcon.appiconset/` |
| Icon rasters (docs copy) | `docs/assets/brand/production/appicon-rasters/` |
| project.yml AppIcon | `ASSETCATALOG_COMPILER_APPICON_NAME` |
| AR Lira Echo materials | `App/AR/Companion/CompanionEntityFactory.swift` |
| Session Lira silhouette | `App/Theme/LiraPresenceSilhouette.swift` |
| Outdoor QA checklist | `docs/design/OUTDOOR_QA_CHECKLIST.md` |

## Identity anchors (Lira)

| ID | Meaning | AR entity | Session UI |
| -- | ------- | --------- | ---------- |
| A1 | Head geometry | `Head` (+ ears) | Silhouette head |
| A2 | Chest bond core | `CoreGlow` | Bond gold core |
| A3 | Trailing filament | `Filament` + `Tail` plume | Filament strokes |

## Honesty

- Procedural AR body remains a **placeholder**, not production art
- Outdoor checklist is empty until a human device walk
- Store marketing screenshots not produced here
