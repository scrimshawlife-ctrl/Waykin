# Waykin AR System Inventory

```yaml
document_id: WAYKIN-AR-SYSTEM-INVENTORY-001
version: 1.1
date: 2026-07-29
status: SUPPORTING
parent: docs/design/AR_PRODUCT_REDESIGN_MAP.md
recovered_on: main_after_freeze_249
companion_runtime: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
does_not_override: [SOLO_MVP_SCOPE, WAYKIN_SPEC, AR_MVP_FREEZE]
```

Complete file-level map of AR-related code and contracts. Paths relative to repo root.

**Runtime note (post-#246):** packaged companion is **Ember Fox** (`MESHY_EMBER_FOX_WALK_V1`) with versioned async template load, procedural fallback, live authored replacement, and explicit scene-anchor detach. Artist-blend / DCC mid-LOD is **historical**, not the active default.

## 1. Core (platform-neutral semantics)

| Path | Role |
| ---- | ---- |
| `Sources/WaykinCore/Presentation/ARPresentationContracts.swift` | `ARCapabilityState`, `CompanionPresentation`, `DiscoveryPresentation`, `ThreatPresentation`, `ARWorldCommand` |
| `Sources/WaykinCore/Presentation/SpatialIntent.swift` | Placement mode, distance band, bearing, scale, persistence hints |
| `Sources/WaykinCore/Engines/CompanionPresentationMatrix.swift` | Shared behavior + distance + AR behavior strings |
| `Sources/WaykinCore/Engines/AudioExperienceLayer.swift` | Semantic cue kinds; AR presentation-transition cues when higher priority silent |
| `Sources/WaykinCore/Path/PathAudioCoupling.swift` | Path soft cues onto same cue kinds |
| `Sources/WaykinCore/Experiences/Experiences.swift` | `CompanionWalkExperience` — walk loop; **does not** emit `ARWorldCommand` |
| `Sources/WaykinCore/Experiences/ExperienceProtocol.swift` | Experience protocol surface |
| `Sources/WaykinCore/Diagnostics/AudioPlaybackDiagnostic.swift` | Audio diagnostics |

**Isolation rule:** no ARKit, RealityKit, MapKit, or audio filenames under `Sources/WaykinCore`.

## 2. App orchestration

| Path | Role |
| ---- | ---- |
| `App/WaykinApp.swift` | `WaykinAppModel`: walk/demo lifecycle, `emitARWorldCommands`, attach/detach handler, `showsARCompanion` fullScreenCover |
| `App/AppAudioCuePlayer.swift` | Cue kind → WAV + AVAudioSession |
| `App/CompanionPresenceView.swift` | 2D presence surface |
| `App/SessionMapPresentation.swift` | Map presentation state |
| `App/SessionMapViews.swift` | Session map UI |
| `App/WalkRoutePlanning.swift` | Route planning presentation helpers |

## 3. App AR stack (`App/AR/`)

### Session & commands

| Path | Role |
| ---- | ---- |
| `App/AR/CanonicalARWorldCommandMapper.swift` | Companion/pursuit/event/path → `[ARWorldCommand]`; stable discovery/threat UUIDs |
| `App/AR/CanonicalARSessionView.swift` | Production AR SwiftUI + `CanonicalARSessionRuntime`; command attach protocol |
| `App/AR/ARWorldCommandRenderer.swift` | Execute spawn/update/remove/clear; escort mode; skins |
| `App/AR/ARPlacementResolver.swift` | World-plane plant; assumed-ground placement fallback when raycast fails; camera fallback; continuity re-plant |
| `App/AR/ARSessionCoordinator.swift` | ARSession lifecycle |
| `App/AR/ARCapabilityMonitor.swift` | World tracking support + camera auth → capability |
| `App/AR/AREntityRegistry.swift` | Entity ID registry |
| `App/AR/ARContinuityHint.swift` | Continuity HUD copy |
| `App/AR/WaykinARView.swift` | `ARView` representable shell |

### Companion visuals

| Path | Role |
| ---- | ---- |
| `App/AR/Companion/CompanionEntityFactory.swift` | Procedural Living Familiar (bounded load fallback only) |
| `App/AR/Companion/CompanionPresentationState.swift` | Renderer state enum + reducer |
| `App/AR/Companion/CompanionVisualConfiguration.swift` | Visual config payload |
| `App/AR/Companion/LiraARAssetLoader.swift` | Versioned async USDZ template load; procedural fallback; live authored replace; base-transform preserve |
| `App/AR/Companion/LiraARAssetCatalog.swift` | Bundled asset names + `MESHY_EMBER_FOX_WALK_V1` evidence class |
| `App/AR/Companion/LiraARAnimationLibrary.swift` | Non-skeletal animation helpers |
| `App/AR/Companion/LiraARMotion.swift` | Ambient motion pure functions |
| `App/AR/Companion/LiraMeshGeometry.swift` | Procedural mesh descriptors (fallback path) |
| `App/AR/Companion/LiraSkeletalRig.swift` | Joint hierarchy contract |
| `App/AR/Companion/LiraSkeletalAnimationLibrary.swift` | Skeletal clips |
| `App/AR/Companion/LiraSkeletalPlayer.swift` | RealityKit skeletal driver; authored walk targets skeleton; stands down multi-part DCC when authored clip active |

### Diagnostics & lab

| Path | Role |
| ---- | ---- |
| `App/AR/Diagnostics/` | AR diagnostic recorder / validation hooks |
| `App/AR/Debug/` | AR lab / debug surfaces |
| `ARLab/` (target) | Isolated engineering target (if present) |

## 4. Assets

| Path | Role |
| ---- | ---- |
| `App/Resources/Lira_AR_Base.usdz` | **Ember Fox** packaged runtime (primary; xcodegen) |
| `App/Resources/Companion/Lira/Lira_AR_Base.usdz` | Nested mirror (byte-identical) |
| `docs/assets/companion/ar/Lira_AR_Base.usdz` | Docs mirror (byte-identical) |
| `docs/assets/companion/ar/artist/EXPORT_OK` | Evidence marker `MESHY_EMBER_FOX_WALK_V1` |
| `App/Resources/Companion/Lira/Clips/*.usdz` | Six per-state sidecars (catalog/fallback; not bound while authored walk active) |
| `App/Resources/Assets.xcassets/LiraStills/**` | Session 2D stills matrix |
| `App/Resources/Assets.xcassets/LiraGlyph/**` | Glyphs |
| `App/Resources/Audio/**` | Produced WAV cues |
| `ArtSource/**` | Artist provenance sources (historical packages may remain; not runtime default) |

## 5. Tests / gates (AR-related)

| Area | Examples (names may evolve) |
| ---- | --------------------------- |
| Package mesh scale | `LiraPackagedMeshScaleTests` |
| Skinned USDZ | `LiraSkinnedUSDZTests` |
| Embodiment / motion | `ARCompanionEmbodimentTests`, `LiraARMotionTests` |
| World event pressure | `WorldEventCadenceTests` (gameplay; PR #248) |
| Integration | `CanonicalARRuntimeIntegrationTests` |
| Real walk handler | `RealMovementSessionTests` (handler batches) |
| Soak / replay | `ARCommandReplaySoakTests` |
| Isolation | `scripts/check_core_framework_isolation.sh` |
| USDZ integrity | `make check-lira-usdz` / `scripts/check_lira_usdz_integrity.sh` |
| CI | `validate`, `swift-package`, `native-ios` |

**Superseded mesh PRs:** #242 / #243 closed; do not merge. Mesh authority: **#246**.

## 6. Lifecycle mapping (commands)

| Walk event | Commands |
| ---------- | -------- |
| Demo/real start | `spawnCompanion` |
| Accepted tick / demo advance | `updateCompanion` (+ discovery/threat per pursuit/event) |
| End / fail / clear | `clearSession` |

Stable IDs: discovery `…D15C`, threat `…7A11` (see mapper).

## 7. Presentation triangle (shared matrix)

| Concern | Owner |
| ------- | ----- |
| Behavior vocabulary | `CompanionPresentationMatrix` |
| AR behavior strings | same (`idle` / `follow` / `investigate` / `alert` / `celebrate`) |
| 2D pose lean | same → presence stills |
| Audio soft coupling | `AudioExperienceLayer` + path coupling after event/behavior silence |

## 8. Docs that govern this inventory

| Doc | Governs |
| --- | ------- |
| `docs/design/AR_MVP_FREEZE.md` | What may change in `App/AR/**` |
| `docs/design/REAL_WALK_TO_AR_MAPPING.md` | Emission rules |
| `docs/design/AR_PRODUCT_REDESIGN_MAP.md` | Product redesign envelope |
| `docs/plans/AR_APP_REDESIGN_PLAN.md` | Phased work |
| `ARCHITECTURE.md` | Ownership |
| `WAYKIN_SPEC.md` | Product contract |
