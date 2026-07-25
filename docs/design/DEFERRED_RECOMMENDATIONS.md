# Deferred recommendations (parked)

```yaml
document_id: WAYKIN-DEFERRED-RECS-001
created: 2026-07-20
status: PARKED
reason: Device evidence lane (indoor smoke + outdoor #41); eng + Hallmark UI shipped
main_tip_at_park: f0e6762
main_tip_at_refresh: d7954ac
refresh_date: 2026-07-25
marketing_version: "0.9.0"
build_number: "2"
```

Parked after UI waves, AR mesh/device stack, Hallmark polish (#236), and internal TF version cut (#237). **On tip `d7954ac`:** artist package + DCC path shipped; Phase A laptop validate **PASS** on ancestor `3cc8ac2`; indoor/outdoor human receipts PENDING. Outdoor **#41** remains first for COH.

## Top parked item — outdoor device

| Priority | Item | Notes |
| -------- | ---- | ----- |
| **1** | **[#41](https://github.com/scrimshawlife-ctrl/Waykin/issues/41) outdoor AR re-walk** | Daylight physical iPhone; COH PASS/PARTIAL/FAIL; tip SHA at walk time (`d7954ac` preferred; scaffold `OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md`) |

### Outdoor packet (when resuming #41)

1. Install tip on device (not sim only).
2. World plant + re-plant / camera loss (#125 mitigations).
3. A1 head · A2 core · A3 filament readability in sun/glare.
4. Hero-skinned mesh + **DCC** motion (`dcc` / clip ids on Motion line) still legible.
5. Reduce Motion + live form (skin) swap.
6. Route create + map presentation still sane.
7. COH receipt with **OBSERVED** notes — no outdoor quality PASS without it.

## After outdoor (or if still blocked)

| Priority | Recommendation | Why |
| -------- | -------------- | --- |
| 2 | ~~Sim screenshot matrix~~ | **Done** #194 |
| 3 | Device **indoor** AR smoke | **Armed** — fill `INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md` |
| 4 | ~~Internal TF version cut 0.9.0 (2)~~ | **Done** eng (#237); **upload** still human |
| 5 | Freehand weight paint | Only if outdoor shows joint tearing |
| 6 | Slim package further | Optional; base ~5 MB + clips |
| 7 | RC/FUTURE features | Directors, Watch, Path/Health v2 — need promotion |
| 8 | Orc/FutureSelf cleanup | Migration issue + Codable tests |

## Explicit non-priorities while parked

- Re-authoring armature/skin “because we can”
- Claiming outdoor AR quality without #41
- Expanding AR under freeze without issue
- Marketplace / multiplayer / per-skin unique meshes
- Reintroducing Meshy walk as default runtime USDZ

## Related shipped ladder (context only)

- Mid-LOD: artist blend + DCC clips · evidence `ARTIST_BLEND_HERO_DCC_MID_LOD`
- Hallmark presentation polish (#236): Trail featured, single state chip, LiraMaterial tokens
- Phase A: `PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md`

---

**Resume trigger:** Human says “outdoor #41” or “indoor smoke” or “resume deferred recs.”  
**Live board:** [ACTIVE_WORK.md](../collaboration/ACTIVE_WORK.md)
