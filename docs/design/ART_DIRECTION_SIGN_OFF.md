# Lira Art Direction Sign-off

```yaml
document_id: WAYKIN-ART-SIGN-OFF-001
date: 2026-07-19
product: Waykin
companion: Lira
style: spectral_living_familiar
anti: [pokemon, mascot, canid_clone, creature_collectible]
status: DIRECTION_ACCEPTED
outdoor_qa: NOT_COMPUTABLE
```

## Decision

The **spectral Living Familiar** generated pack is accepted as the locked visual direction for Lira in-app presentation (session stills + glyphs).

| Gate | Result | Notes |
| ---- | ------ | ----- |
| G1 Silhouette | **PASS** | Recognizable tapered head + chest ember + filament across 7 poses |
| G2 Anchors A1–A3 | **PASS** | Present on all 21 stills + glyphs |
| G3 Hunter | **PASS** | Echo/pressure language; no gore/teeth/blood |
| G4 Reduced motion | **PASS** | Static stills per state (no motion dependency) |
| G5 Skins | **PASS** | Dawn / Veil / Rupture same character, material climate only |
| G6 App wire | **PASS** | `LiraStills` 7×3 + glyphs; Canvas puppet fallback only if missing |
| G7 Outdoor | **DEFERRED** | Device walk still required for glare/GPS claims |

## Locked constraints

- Product name **Lira**; one companion; no marketplace multi-companion.
- Audio-first; stills support presence, not gameplay expansion.
- Night climate is indigo-earth Echo, not inverted day mist.
- AR mid-LOD may remain procedural until sculpted USDZ lands; stills direction is binding for materials and silhouette.

## Not claimed

- Hand-painted hero finality
- Outdoor daylight/night street readability
- Physical AR tracking quality

## Evidence paths

- Masters: `docs/assets/companion/generated/`
- App: `App/Resources/Assets.xcassets/LiraStills`, `LiraGlyph`
- Spec: `docs/design/GENERATED_LIRA_ART.md`
