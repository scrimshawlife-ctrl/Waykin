# Phase A pre-device gates receipt

```yaml
document_id: WAYKIN_PHASE_A_PREDEVICE
date_utc: 2026-07-24T02:59:15Z
main_tip_sha: f061b4e6b94c650b8df6d2ff28cbc050b5da7ffd
main_tip_short: f061b4e
environment: laptop + iOS_Simulator_iPhone_17
not: outdoor_#41
not: indoor_physical_device
```

| Gate | Result |
|------|--------|
| `make check-lira-usdz` | **PASS** (triple 5099386 bytes; 6 sidecars; animated joint curves) |
| `make validate` | **PASS** (126 package tests + WaykinApp build) |
| Sim DCC composition | **OBSERVED** (see log below) |
| Outdoor #41 | **NOT_COMPUTABLE** |

Sim binding line (from `testDCCClipSidecarCompositionBindsStateClips`):

```
WAYKIN_SIM_DCC_COMPOSITION: loadNote=usdz_active_artist_blend_hero_dcc_mid_lod:clips=0;sidecar=6 | sidecarNote=sidecars_found=6;mapped=6;keys=alert,celebrate,follow,idle,investigate,spawn | mapped=6 | libraryKeys=alert,celebrate,follow,idle,investigate,spawn | clipSource=dcc | sourceDescription=dcc:multiPart:6_clips | entityClips=6
```

## Next (human)

1. Indoor smoke — [INDOOR_AR_HYBRID_SMOKE.md](../INDOOR_AR_HYBRID_SMOKE.md) + PENDING receipt on tip
2. Internal TF — [TESTFLIGHT_RC_CHECKLIST.md](../TESTFLIGHT_RC_CHECKLIST.md)
3. Outdoor #41 when daylight
