# Packaged Lira AR USDZ

```yaml
evidence_class: MESHY_EMBER_FOX_WALK_V1
file: Lira_AR_Base.usdz
runtime_size: ~20MB_ember_fox_walk
mesh_authority_pr: 246
supersedes: ARTIST_BLEND_HERO_DCC_MID_LOD
```

Primary: `App/Resources/Lira_AR_Base.usdz` (bundled via xcodegen)  
Mirror: `App/Resources/Companion/Lira/Lira_AR_Base.usdz`  
Docs mirror: `docs/assets/companion/ar/Lira_AR_Base.usdz`  

Current runtime package is the **Ember Fox** walk USDZ shipped by **PR #246**. The three tracked copies must remain **byte-identical**.

Do **not** re-import or replace this mesh without an explicit asset issue. Closed PRs **#242** and **#243** are superseded; do not force-merge them.

## Integrity

```bash
./scripts/check_lira_usdz_integrity.sh
# or
make check-lira-usdz
```

Marker: `docs/assets/companion/ar/artist/EXPORT_OK` — `MESHY_EMBER_FOX_WALK_V1`.  
Validation: `usdchecker --arkit` PASS on package (see EXPORT_OK).

## Runtime

1. AR attach → `LiraARAssetLoader.preloadFromBundle()` (versioned async template load)
2. Spawn may use **procedural Living Familiar** only as a bounded fallback while the package decodes
3. When decode completes, **authored Ember Fox** replaces the fallback in-place
4. Scene-owned anchors are explicitly detached so replacement leaves **one** companion
5. Embedded walk cycle targets the **skeleton**; scale/ground contact follow measured contract
6. State updates must not overwrite the imported asset’s canonical base transform

## Per-state clip sidecars

`App/Resources/Companion/Lira/Clips/Lira_{Idle,Follow,Investigate,Alert,Celebrate,Spawn}.usdz`

These remain bundled for catalog/fallback paths. While an authored walk clip is present on the Ember Fox rig, `LiraSkeletalPlayer` stands down for conflicting multi-part DCC binding (see EXPORT_OK). Per-state authored clips return when a compatible rig ships — add incrementally; **never** replace the base mesh merely to add clips.

## Historical note

The retired **artist-blend / DCC mid-LOD** package (`ARTIST_BLEND_HERO_DCC_MID_LOD`, ~5 MB) was the previous default. It is **not** the active runtime. Historical receipts and Phase A notes that pin artist-blend SHAs (`3cc8ac2`, `d7954ac`) remain historical evidence only.
