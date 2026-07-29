# Lira AR reference assets

| File | Role |
| ---- | ---- |
| `Lira_AR_Base.usdz` | Packaged Ember Fox runtime (same bytes as app; `MESHY_EMBER_FOX_WALK_V1`) |
| `artist/EXPORT_OK` | Evidence marker for current package |
| `src/Lira_AR_Base.usda` | Historical/generated source path; not the current Ember Fox default |

Runtime: `App/Resources/Lira_AR_Base.usdz` (+ nested mirror)
Loader: `LiraARAssetLoader` (async template + procedural fallback + live replace)
Authority: PR #246
Spec: `docs/design/LIRA_AR_PRODUCTION_RIG.md`
