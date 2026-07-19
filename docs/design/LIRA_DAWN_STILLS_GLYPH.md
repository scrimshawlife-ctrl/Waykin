# Dawn Session Stills + Glyph LOD (Issue #66)

```yaml
issue: 66
status: IN_APP_PRESENTATION
skin: Dawn
lod: [session_mid_stills, glyph]
outdoor_qa: deferred
```

## Dawn session stills (complete)

| Pose | Asset |
| ---- | ----- |
| Guide | `Lira_Session_Guide_Dawn` |
| Rival | `Lira_Session_Rival_Dawn` |
| Hunter | `Lira_Session_Hunter_Dawn` |
| Sanctuary | `Lira_Session_Sanctuary_Dawn` |
| Bond | `Lira_Session_Bond_Dawn` |
| Dormant | `Lira_Session_Dormant_Dawn` |
| Manifesting | `Lira_Session_Manifesting_Dawn` |

Plus Veil/Rupture guide stills (existing).

## Glyph

`Lira_Glyph_Dawn` — used on Home bond row. Procedural fallback for non-Dawn skins.

## Wiring

`LiraStillCatalog` + `LiraSessionFigure` prefer stills when present.
