# Deferred recommendations (parked)

```yaml
document_id: WAYKIN-DEFERRED-RECS-001
created: 2026-07-20
status: PARKED
reason: Device evidence lane (indoor Ember Fox smoke + outdoor #41); eng mesh/runtime shipped
main_tip_at_park: f0e6762
main_tip_at_refresh: 7df3a16
refresh_date: 2026-07-29
companion_runtime: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
gameplay_pressure_pr: 248
marketing_version: "0.9.0"
build_number: "2"
```

Parked after UI waves, Ember Fox mesh/runtime (**#246**), real-walk pressure (**#248**), Hallmark polish (#236), and internal TF version metadata cut (#237). **On tip `7df3a16`:** packaged Ember Fox is the authoritative runtime; artist-blend/DCC mid-LOD is **superseded**. Pre-mesh Phase A on `3cc8ac2` / tip `d7954ac` is **historical**. Indoor/outdoor human receipts on the post-mesh tip remain PENDING. Outdoor **#41** remains first for COH. TestFlight archive remains held by **#247** until device confirms authored mesh replacement.

## Top parked item — outdoor device

| Priority | Item | Notes |
| -------- | ---- | ----- |
| **1** | **[#41](https://github.com/scrimshawlife-ctrl/Waykin/issues/41) outdoor AR re-walk** | Daylight physical iPhone; COH PASS/PARTIAL/FAIL; tip SHA at walk time (`7df3a16` preferred). Pre-mesh scaffold `OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md` is **historical** — re-scaffold for the install tip. |

### Outdoor packet (when resuming #41)

1. Install tip on device (not sim only); record exact SHA.
2. World plant + re-plant / camera loss (#125 mitigations).
3. Ember Fox silhouette + ground contact readability in sun/glare.
4. Authored walk cycle on skeleton still legible while moving; animation pause when stationary if implemented.
5. Reduce Motion + live form (skin) swap.
6. Route create + map presentation still sane.
7. Separate mesh/runtime notes from world-event variety under #248 pressure (do not retune density from sparse alone).
8. COH receipt with **OBSERVED** notes — no outdoor quality PASS without it.

## After outdoor (or if still blocked)

| Priority | Recommendation | Why |
| -------- | -------------- | --- |
| 2 | ~~Sim screenshot matrix~~ | **Done** #194 |
| 3 | Device **indoor** Ember Fox smoke | **Armed** — fallback→authored replace, single anchor, skeleton walk |
| 4 | ~~Ember Fox mesh/runtime eng~~ | **Done** #246 on main |
| 5 | ~~Real-walk pressure curve~~ | **Done** #248 (gameplay, not AR) |
| 6 | Close or re-scope **#247** TF hold | Device OBSERVED authored mesh; then revalidate RC |
| 7 | Internal TF archive | Only after #247 + fresh validate on archive SHA |
| 8 | Recover #245 redesign docs on current main | SUPPORTING only; do not merge stale branch |
| 9 | Phase 0 product-law AR/audio identity | Before AR session redesign implementation |
| 10 | Per-state clips on Ember Fox skeleton | Incremental; never replace base mesh just to add clips |
| 11 | RC/FUTURE features | Directors, Watch, Path/Health v2 — need promotion |
| 12 | Orc/FutureSelf cleanup | Migration issue + Codable tests |

## Explicit non-priorities while parked

- Replacing or re-importing the Ember Fox mesh “because we can”
- Merging closed mesh PRs #242 / #243
- Claiming outdoor AR quality without #41
- Expanding AR under freeze without issue (except approved mesh/runtime defects)
- Marketplace / multiplayer / per-skin unique meshes
- Treating PR #245 supporting redesign docs as binding law

## Related shipped ladder (context only)

- Current runtime: Ember Fox package + async replace · evidence `MESHY_EMBER_FOX_WALK_V1` · PR #246
- Superseded mid-LOD: artist blend + DCC clips · evidence `ARTIST_BLEND_HERO_DCC_MID_LOD` · **historical**
- Hallmark presentation polish (#236): Trail featured, single state chip, LiraMaterial tokens
- Pre-mesh Phase A (historical): `PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md`

---

**Resume trigger:** Human says “outdoor #41” or “indoor smoke” or “resume deferred recs.”  
**Live board:** [ACTIVE_WORK.md](../collaboration/ACTIVE_WORK.md)
