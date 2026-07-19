# Indoor Simulator Smoke Receipt

```yaml
document_id: WAYKIN-INDOOR-SIM-SMOKE
date_utc: 2026-07-19T22:59:57Z
git_sha: de70e4fd0645767c1074aca5ed7d57ce77e96b0b
git_short: de70e4f
evidence_class: OBSERVED_IN_SIMULATOR_ONLY
outdoor_qa: NOT_COMPUTABLE
focus: indoor
```

## Automated results (iPhone 17 Pro)

| Suite | Result |
| ----- | ------ |
| make validate / sim_walk_preflight | PASS |
| swift package tests (60) | PASS |
| WaykinUITests (12) | PASS |
| Demo begin / pause / end | PASS |
| Home skins + settings appearance | PASS |
| AR companion form label | PASS |
| Accessibility largest text + presence a11y | PASS |

## Indoor motion shipped at this tip

| ID | Feature |
| -- | ------- |
| C1 | Session still crossfade |
| C2 | AR CoreGlow breath + Filament sway |
| C3 | Hunter echo (session + AR) |
| C4 | Spawn coalesce |
| Polish | Bond orbit spin + manifesting fade/scale |

## Explicitly not claimed

- Outdoor glare / night street readability
- GPS integrity / physical walk
- Device AR tracking quality
- Artist-sculpted USDZ as runtime default

## Operator notes

Indoor presentation loop is green under automated sim coverage. Outdoor remains deferred by product choice.
