# Full Lira Session Still Matrix (Issue #68)

```yaml
issue: 68
status: IN_APP_PRESENTATION
skins: [Dawn, Veil, Rupture]
poses: [Guide, Rival, Hunter, Sanctuary, Bond, Dormant, Manifesting]
count: 21
glyphs: [Dawn, Veil, Rupture]
outdoor_qa: deferred
```

## Naming

```text
Lira_Session_{Pose}_{Skin}
Lira_Glyph_{Skin}
```

## Coverage

| Pose \\ Skin | Dawn | Veil | Rupture |
| ------------ | ---- | ---- | ------- |
| Guide | yes | yes | yes |
| Rival | yes | yes | yes |
| Hunter | yes | yes | yes |
| Sanctuary | yes | yes | yes |
| Bond | yes | yes | yes |
| Dormant | yes | yes | yes |
| Manifesting | yes | yes | yes |

## Runtime

`LiraStillCatalog.imageName(pose:skin:)` always returns a name for the 3×7 matrix.
`LiraSessionFigure` uses the still when the asset is in the catalog; otherwise Canvas puppet.
