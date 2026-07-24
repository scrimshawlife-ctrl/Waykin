# Deferred recommendations (parked)

```yaml
document_id: WAYKIN-DEFERRED-RECS-001
created: 2026-07-20
status: PARKED
reason: Device evidence lane (indoor smoke + outdoor #41); eng DCC path shipped
main_tip_at_park: f0e6762
main_tip_at_refresh: f061b4e
refresh_date: 2026-07-24
```

Parked after UI waves and AR mesh/device stack. **On tip `f061b4e`:** artist package (#222), device AR/audio/follow (#217), composition (#224), DCC bake/export (#226 → `clipSource=dcc` sim). Outdoor **#41** remains first for COH. Next: indoor smoke on tip, then outdoor when daylight.

## Top parked item — outdoor device

| Priority | Item | Notes |
| -------- | ---- | ----- |
| **1** | **[#41](https://github.com/scrimshawlife-ctrl/Waykin/issues/41) outdoor AR re-walk** | Daylight physical iPhone; COH PASS/PARTIAL/FAIL; tip SHA at walk time (`f061b4e`+) |

### Outdoor packet (when resuming #41)

1. Install tip on device (not sim only).
2. World plant + re-plant / camera loss (#125).
3. A1 head · A2 core · A3 filament readability in sun/glare.
4. Hero-skinned mesh + **DCC** motion (`dcc` / clip ids on Motion line) still legible.
5. Reduce Motion + live form (skin) swap.
6. Route create + map presentation still sane.
7. COH receipt with OBSERVED notes — no outdoor quality PASS without it.

## After outdoor (or if still blocked)

| Priority | Recommendation | Why |
| -------- | -------------- | --- |
| 2 | ~~Sim screenshot matrix (day/night × home/session/summary)~~ | **Done** issue #194 tooling + SIMULATOR set; AR frame still optional/manual |
| 3 | Device **indoor** AR smoke (`dcc` / clip ids / plant / audio) | **Armed** — [`INDOOR_AR_HYBRID_SMOKE.md`](INDOOR_AR_HYBRID_SMOKE.md) + `scripts/indoor_ar_smoke_prep.sh`; human rows PENDING on tip |
| 4 | Freehand weight paint pass | Only if outdoor shows joint tearing |
| 5 | ~~DCC runtime composition~~ | **Done** PR #224 |
| 6 | ~~DCC bake / RK binding (`mapped>=3`)~~ | **Done** PR #226 (closes #225); device quality still #41 |
| 7 | Slim package further | Optional; already ~5 MB base + ~0.7 MB/clip |
| 8 | RC/FUTURE features | Directors, Watch, Path/Health v2 — need promotion |
| 9 | Orc/FutureSelf cleanup | Dedicated migration issue + Codable tests |

## Explicit non-priorities while parked

- Re-authoring armature/skin “because we can”
- Claiming outdoor AR quality without #41
- Expanding AR under freeze without issue
- Marketplace / multiplayer / per-skin unique meshes
- Reintroducing Meshy walk as default runtime USDZ

## Related shipped AR ladder (context only)

- Mid-LOD: GENERATED → artist blend → armature → auto-skin → hero paint → DCC clips  
- Evidence: `ARTIST_BLEND_HERO_DCC_MID_LOD`  
- Runtime: composition path + baked joint timeSamples (sim `clipSource=dcc`)  
- Non-outdoor polish: reduce motion, live skin, skinned tests, integrity check  

---

**Resume trigger:** Human says “outdoor #41” or “indoor smoke” or “resume deferred recs.”
