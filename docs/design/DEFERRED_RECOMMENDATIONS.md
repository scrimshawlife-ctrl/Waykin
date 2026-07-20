# Deferred recommendations (parked)

```yaml
document_id: WAYKIN-DEFERRED-RECS-001
created: 2026-07-20
status: PARKED
reason: Pivot to UI candidate integration (CANDIDATE_v0.2)
main_tip_at_park: f0e6762
```

Parked from post–`ARTIST_BLEND_HERO_DCC_MID_LOD` recommendations. Resume after UI integration waves (or in parallel only if blocking).

## Top parked item — outdoor device

| Priority | Item | Notes |
| -------- | ---- | ----- |
| **1** | **[#41](https://github.com/scrimshawlife-ctrl/Waykin/issues/41) outdoor AR re-walk** | Daylight physical iPhone; COH PASS/PARTIAL/FAIL; tip SHA at walk time |

### Outdoor packet (when resuming #41)

1. Install tip on device (not sim only).
2. World plant + re-plant / camera loss (#125).
3. A1 head · A2 core · A3 filament readability in sun/glare.
4. Hero-skinned mesh + hybrid motion (DCC/puppet) still legible.
5. Reduce Motion + live form (skin) swap.
6. Route create + map presentation still sane.
7. COH receipt with OBSERVED notes — no outdoor quality PASS without it.

## After outdoor (or if still blocked)

| Priority | Recommendation | Why |
| -------- | -------------- | --- |
| 2 | ~~Sim screenshot matrix (day/night × home/session/summary)~~ | **Done** issue #194 tooling + SIMULATOR set; AR frame still optional/manual |
| 3 | Device **indoor** AR smoke of DCC hybrid chrome (`dcc`/`hybrid`/`puppet`) | **Armed** — protocol [`INDOOR_AR_HYBRID_SMOKE.md`](INDOOR_AR_HYBRID_SMOKE.md) + `scripts/indoor_ar_smoke_prep.sh`; human device rows PENDING |
| 4 | Freehand weight paint pass | Only if outdoor shows joint tearing |
| 5 | Slim DCC package (~5MB → anim-only sidecars) | Size optimization |
| 6 | RC/FUTURE features | Directors, Watch, Path/Health v2 — need promotion |
| 7 | Orc/FutureSelf cleanup | Dedicated migration issue + Codable tests |

## Explicit non-priorities while parked

- Re-authoring armature/skin “because we can”
- Claiming outdoor AR quality without #41
- Expanding AR under freeze without issue
- Marketplace / multiplayer / per-skin unique meshes

## Related shipped AR ladder (context only)

- Mid-LOD: GENERATED → artist blend → armature → auto-skin → hero paint → DCC clips  
- Evidence: `ARTIST_BLEND_HERO_DCC_MID_LOD`  
- Non-outdoor polish: reduce motion, live skin, skinned tests, integrity check (#167/#168)

---

**Resume trigger:** Human says “outdoor #41” or “resume deferred recs.”
