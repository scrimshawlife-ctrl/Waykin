# Lira AR assets (drop-in)

```yaml
lod: AR_mid
companion: Lira
rig: Living_Familiar
skins: [Dawn, Veil, Rupture] # materials only — one mesh
```

## Current runtime

1. On AR attach, `LiraARAssetLoader.preloadFromBundle()` tries this folder.
2. If `Lira_AR_Base.usdz` loads **and** required nodes validate → clones for spawn.
3. Otherwise **procedural** Living Familiar mid-LOD (`CompanionEntityFactory`).

Spectral 2D stills cover session UI. Animation roadmap: `docs/design/LIRA_ANIMATION_PLAN.md`.

## Artist USDZ (optional production mesh)

Place a single shared rig file here:

```text
Lira_AR_Base.usdz
```

### Requirements

| Rule | Detail |
| ---- | ------ |
| Root | Entity named `LiraRoot` (or re-root on import) |
| A1 | Node `Head` — tapered non-canid |
| A2 | Node `CoreGlow` — chest bond ember |
| A3 | Node `Filament` — trailing plume |
| Required | Also: `Body`, `LeftEar`, `RightEar`, `Tail`, `GroundShadow`, `StatusIndicator` |
| Skins | Same mesh; materials remapped at runtime for Dawn/Veil/Rupture |
| Scale | ~0.7 m tall at unit scale (factory height config applies) |
| Hunter | No gore / teeth / blood geometry |

### Masters (repo)

Procedural-compatible reference USD sketch:

`docs/assets/companion/ar/Lira_AR_Base.usdz`

Session stills (signed direction):

`docs/assets/companion/generated/`

## Status

- 2D spectral pack: **DIRECTION_ACCEPTED**
- AR mesh: **PROCEDURAL_MID** until artist USDZ lands
