import Combine
import RealityKit
import UIKit

/// Async USDZ preload + sync spawn for Lira AR mid-LOD.
///
/// Default remains procedural Living Familiar until a valid packaged
/// `Lira_AR_Base.usdz` is present **and** hierarchy validation passes.
@MainActor
final class LiraARAssetLoader {
    enum Source: Equatable, Sendable {
        case procedural
        case usdz(String)
    }

    private(set) var source: Source = .procedural
    /// Why the last preload chose procedural or USDZ (#133 outdoor QA).
    private(set) var loadNote: String = "not_attempted"
    /// When true, `makeLira` keeps authored PBR/textures (Meshy static mesh).
    private(set) var preserveAuthoredMaterials = false
    /// True when the packaged USDZ ships its own skeletal clip (UsdSkel walk cycle).
    /// The renderer must not install puppet clips over it, and `makeLira` loops it.
    private(set) var hasAuthoredAnimation = false
    private var template: Entity?
    var skin: LiraSkin = .dawn

    /// Load optional artist USDZ. Safe to call repeatedly.
    ///
    /// - Parameter usdzURL: Defaults to the packaged catalog URL. Pass `nil` (or an
    ///   unreadable URL) from tests to exercise procedural fallback without requiring
    ///   the app bundle to omit `Lira_AR_Base.usdz`.
    func preloadFromBundle(usdzURL: URL? = LiraARAssetCatalog.baseUSDZURL) async {
        guard let url = usdzURL else {
            clearTemplate(reason: .procedural, note: "no_packaged_url")
            return
        }
        do {
            let loaded = try await Self.loadEntity(from: url)
            // Skinned/animated exports (Meshy walk cycle) must NOT be reparented:
            // pulling the mesh out of its SkelRoot severs skinning and kills the clip.
            let clipCount = Self.animationClipCount(loaded)
            if Self.animationHost(loaded) != nil {
                let animatedRoot = Self.adoptAnimatedHierarchy(loaded, skin: skin)
                guard Self.hasRequiredNodes(animatedRoot) else {
                    clearTemplate(reason: .procedural, note: "animated_hierarchy_invalid")
                    return
                }
                if let body = animatedRoot.findEntity(named: "Body") {
                    // Scale an inner node rather than Body itself: per-frame local motion
                    // resets Body.scale to 1 for static-mesh puppets, which would silently
                    // undo height normalization. (Root scale is owned by `makeLira`.)
                    let target = body.children.first(where: { Self.hasModelGeometry($0) }) ?? body
                    Self.normalizeVisualHeight(target, targetHeightMeters: 0.72)
                }
                if Self.isAuthoredBodyStaticMesh(animatedRoot) {
                    Self.plantBodyOnGround(animatedRoot)
                    Self.layoutSpectralFXAnchors(on: animatedRoot)
                }
                template = animatedRoot
                source = .usdz(url.lastPathComponent)
                preserveAuthoredMaterials = true
                hasAuthoredAnimation = true
                loadNote = "usdz_active_animated_skelanim:clips=\(clipCount)"
                return
            }

            var root = Self.normalizeRoot(loaded)
            var promoted = false
            if !Self.hasRequiredNodes(root) {
                root = Self.promoteIncompleteHierarchy(root, skin: skin)
                promoted = true
            } else if Self.looksLikeTexturedStaticMesh(root) {
                // Named hierarchy but empty FX markers — still install spectral layer.
                Self.installSpectralFX(on: root, skin: skin)
            }
            guard Self.hasRequiredNodes(root) else {
                clearTemplate(reason: .procedural, note: "hierarchy_invalid")
                return
            }
            // Height from Body mesh only when possible — FX discs shouldn't inflate bounds.
            if let body = root.findEntity(named: "Body") {
                Self.normalizeVisualHeight(body, targetHeightMeters: 0.72)
            } else {
                Self.normalizeVisualHeight(root, targetHeightMeters: 0.72)
            }
            // Place A2/A3/shadow from Body bounds after scale (Meshy static mesh).
            if Self.isAuthoredBodyStaticMesh(root) {
                Self.plantBodyOnGround(root)
                Self.layoutSpectralFXAnchors(on: root)
            }
            template = root
            source = .usdz(url.lastPathComponent)
            // After FX install, model count is high — use promote flag + Body-only mesh heuristic.
            preserveAuthoredMaterials = promoted
                || Self.isAuthoredBodyStaticMesh(root)
            if preserveAuthoredMaterials {
                loadNote = "usdz_active_meshy_textured_static:clips=\(clipCount)"
            } else {
                loadNote = "usdz_active_artist_blend_hero_dcc_mid_lod:clips=\(clipCount)"
            }
        } catch {
            clearTemplate(reason: .procedural, note: "load_error")
        }
    }

    /// iOS 18+: async Entity init. iOS 17: LoadRequest bridge (deployment target 17).
    private static func loadEntity(from url: URL) async throws -> Entity {
        if #available(iOS 18.0, *) {
            return try await Entity(contentsOf: url)
        }
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = Entity.loadAsync(contentsOf: url)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { entity in
                        continuation.resume(returning: entity)
                        cancellable?.cancel()
                    }
                )
        }
    }

    /// Test / lab injection of a validated hierarchy (skips bundle I/O).
    func installTemplateForTesting(_ entity: Entity, label: String = "test.usdz") {
        let root = Self.normalizeRoot(entity)
        precondition(Self.hasRequiredNodes(root), "test template missing required Lira nodes")
        template = root
        source = .usdz(label)
        loadNote = "usdz_active_test_template"
    }

    func clearTemplate(reason: Source = .procedural, note: String = "cleared") {
        template = nil
        source = .procedural
        loadNote = note
        preserveAuthoredMaterials = false
        hasAuthoredAnimation = false
        _ = reason
    }

    /// Sync spawn used by the renderer. Clones USDZ template when preloaded; else procedural.
    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        if let template {
            let clone = template.clone(recursive: true)
            clone.name = CompanionEntityFactory.rootName
            // Keep Meshy PBR textures; spectral FX (A2/A3/shadow) still follow skin climate.
            if preserveAuthoredMaterials {
                Self.applySpectralFXSkin(skin, to: clone)
            } else {
                Self.applySkin(skin, to: clone)
            }
            let scale = configuration.companionHeightMeters / 0.72
            clone.scale = SIMD3<Float>(repeating: scale)
            if hasAuthoredAnimation {
                Self.playAuthoredAnimation(on: clone)
            }
            return clone
        }
        return CompanionEntityFactory(skin: skin).makeLira(configuration: configuration)
    }

    /// Operator-facing LOD line (AR chrome + field receipts). Includes fallback reason.
    var activeLODDescription: String {
        switch source {
        case .procedural:
            return "procedural_living_familiar_mid (\(loadNote))"
        case .usdz(let name):
            if loadNote.contains("test_template") {
                return "artist_usdz:\(name) (\(loadNote))"
            }
            if loadNote.contains("animated_skelanim") {
                return "animated_usdz:\(name) (\(loadNote))"
            }
            if loadNote.contains("meshy_textured") {
                return "meshy_usdz:\(name) (\(loadNote))"
            }
            if loadNote.contains("artist_blend") || loadNote.contains("armature") {
                return "artist_blend_usdz:\(name) (\(loadNote))"
            }
            return "generated_usdz:\(name) (\(loadNote))"
        }
    }

    // MARK: - Hierarchy

    static func hasRequiredNodes(_ root: Entity) -> Bool {
        CompanionEntityFactory.requiredNodeNames.allSatisfy { root.findEntity(named: $0) != nil }
    }

    /// Prefer an entity named `LiraRoot`; otherwise wrap contents under a new root.
    static func normalizeRoot(_ loaded: Entity) -> Entity {
        if loaded.name == CompanionEntityFactory.rootName {
            return loaded
        }
        if let nested = loaded.findEntity(named: CompanionEntityFactory.rootName) {
            nested.removeFromParent()
            return nested
        }
        let root = Entity()
        root.name = CompanionEntityFactory.rootName
        // Move children under LiraRoot without losing geometry.
        let children = Array(loaded.children)
        for child in children {
            child.removeFromParent()
            root.addChild(child)
        }
        return root
    }

    /// Total animation clips RealityKit exposed across the loaded subtree.
    /// Surfaced in `loadNote` so a field receipt distinguishes "USD import produced no
    /// clips" from "clips imported but never played" — two very different bugs.
    static func animationClipCount(_ root: Entity) -> Int {
        var total = root.availableAnimations.count
        for child in root.children {
            total += animationClipCount(child)
        }
        return total
    }

    /// First entity in the subtree that owns RealityKit animation clips, if any.
    /// USD `SkelAnimation` surfaces as `availableAnimations` on the owning entity.
    static func animationHost(_ root: Entity) -> Entity? {
        if !root.availableAnimations.isEmpty { return root }
        for child in root.children {
            if let found = animationHost(child) { return found }
        }
        return nil
    }

    /// Adopt a skinned/animated USDZ **without moving any geometry**.
    ///
    /// `promoteIncompleteHierarchy` reparents meshes under a fresh `Body`, which breaks
    /// `SkelRoot -> Mesh` binding (and therefore skinning + the authored clip). Here we
    /// only *rename* the geometry container to `Body` and hang the semantic markers off
    /// the root as siblings, so the rig and its animation stay exactly as authored.
    static func adoptAnimatedHierarchy(_ loaded: Entity, skin: LiraSkin) -> Entity {
        let root = loaded
        root.name = CompanionEntityFactory.rootName

        // Name the existing geometry container "Body" — never reparent it.
        if root.findEntity(named: "Body") == nil,
           let container = root.children.first(where: { hasModelGeometry($0) }) {
            container.name = "Body"
        }

        let markerOffsets: [String: SIMD3<Float>] = [
            "Head": SIMD3(0, 0.42, 0.10),
            "LeftEar": SIMD3(-0.10, 0.50, 0.04),
            "RightEar": SIMD3(0.10, 0.50, 0.04),
            "Tail": SIMD3(0, 0.18, -0.28),
            "Filament": SIMD3(0, 0.28, -0.20),
            "CoreGlow": SIMD3(0, 0.32, 0.12),
            "GroundShadow": SIMD3(0, 0.01, 0),
            "StatusIndicator": SIMD3(0, 0.58, 0),
        ]
        for name in CompanionEntityFactory.requiredNodeNames where root.findEntity(named: name) == nil {
            let marker = Entity()
            marker.name = name
            if let offset = markerOffsets[name] { marker.position = offset }
            root.addChild(marker)
        }
        if root.findEntity(named: "CoreHalo") == nil {
            let halo = Entity()
            halo.name = "CoreHalo"
            halo.position = SIMD3(0, 0.34, 0.12)
            root.addChild(halo)
        }
        if root.findEntity(named: LiraARMotion.hunterEchoNodeName) == nil {
            let echo = Entity()
            echo.name = LiraARMotion.hunterEchoNodeName
            echo.position = SIMD3(0.04, 0.28, -0.08)
            echo.isEnabled = false
            root.addChild(echo)
        }

        installSpectralFX(on: root, skin: skin)
        return root
    }

    /// Loop the authored skeletal clip on a freshly cloned companion.
    static func playAuthoredAnimation(on clone: Entity) {
        guard let host = animationHost(clone),
              let clip = host.availableAnimations.first else { return }
        host.playAnimation(clip.repeat(), transitionDuration: 0.2, startsPaused: false)
    }

    /// Meshy image-to-3d (and similar) ships a single textured mesh without A1–A3 names.
    /// Promote into the semantic hierarchy so puppet animation can bind to joints,
    /// then install spectral FX (A2 ember, A3 filament, ground shadow) so anchors
    /// remain readable without destroying authored PBR on Body.
    static func promoteIncompleteHierarchy(
        _ root: Entity,
        skin: LiraSkin = .dawn
    ) -> Entity {
        guard !hasRequiredNodes(root) else {
            // Hierarchy already complete but may still need FX on empty markers.
            installSpectralFX(on: root, skin: skin)
            return root
        }

        var modelEntities: [Entity] = []
        func collectModels(_ entity: Entity) {
            if entity is ModelEntity {
                modelEntities.append(entity)
            }
            for child in entity.children {
                collectModels(child)
            }
        }
        collectModels(root)

        if root.findEntity(named: "Body") == nil {
            let body = Entity()
            body.name = "Body"
            for model in modelEntities {
                // Keep geometry; reparent under Body for a single visual mass.
                if model.parent?.name != "Body" {
                    model.removeFromParent()
                    body.addChild(model)
                }
            }
            // Also reparent remaining non-material transform containers that still hold meshes.
            root.addChild(body)
        }

        // Transform anchors for A1–A3 + chrome (puppet bind targets).
        let markerOffsets: [String: SIMD3<Float>] = [
            "Head": SIMD3(0, 0.42, 0.10),
            "LeftEar": SIMD3(-0.10, 0.50, 0.04),
            "RightEar": SIMD3(0.10, 0.50, 0.04),
            "Tail": SIMD3(0, 0.18, -0.28),
            "Filament": SIMD3(0, 0.28, -0.20),
            "CoreGlow": SIMD3(0, 0.32, 0.12),
            "GroundShadow": SIMD3(0, 0.01, 0),
            "StatusIndicator": SIMD3(0, 0.58, 0),
        ]
        for name in CompanionEntityFactory.requiredNodeNames {
            if root.findEntity(named: name) == nil {
                let marker = Entity()
                marker.name = name
                if let offset = markerOffsets[name] {
                    marker.position = offset
                }
                root.addChild(marker)
            }
        }
        // Optional joint used by skeletal ambient clips.
        if root.findEntity(named: "CoreHalo") == nil {
            let halo = Entity()
            halo.name = "CoreHalo"
            halo.position = SIMD3(0, 0.34, 0.12)
            root.addChild(halo)
        }
        if root.findEntity(named: LiraARMotion.hunterEchoNodeName) == nil {
            let echo = Entity()
            echo.name = LiraARMotion.hunterEchoNodeName
            echo.position = SIMD3(0.04, 0.28, -0.08)
            echo.isEnabled = false
            root.addChild(echo)
        }

        installSpectralFX(on: root, skin: skin)
        return root
    }

    /// Whether `node` already has ModelEntity geometry (self or descendants).
    static func hasModelGeometry(_ node: Entity) -> Bool {
        if node is ModelEntity { return true }
        return node.children.contains { hasModelGeometry($0) }
    }

    /// Attach Living Familiar spectral FX under empty promote markers.
    /// Does not touch Body-authored Meshy mesh.
    static func installSpectralFX(on root: Entity, skin: LiraSkin = .dawn) {
        let palette = CompanionEntityFactory.SkinPalette(skin: skin)

        if let core = root.findEntity(named: "CoreGlow"), !hasModelGeometry(core) {
            let ember = fxModel(
                name: "CoreGlowMesh",
                mesh: LiraMeshGeometry.sphere(radius: 0.038, segments: 12, rings: 10),
                color: palette.bondCore,
                roughness: 0.15,
                metallic: 0.25
            )
            core.addChild(ember)
        }

        if let halo = root.findEntity(named: "CoreHalo"), !hasModelGeometry(halo) {
            let shell = fxModel(
                name: "CoreHaloMesh",
                mesh: LiraMeshGeometry.sphere(radius: 0.052, segments: 12, rings: 10),
                color: palette.bondCore.withAlphaComponent(0.32),
                roughness: 0.85
            )
            halo.addChild(shell)
        }

        if let filament = root.findEntity(named: "Filament"), !hasModelGeometry(filament) {
            filament.orientation = simd_quatf(
                angle: LiraARMotion.filamentBasePitch,
                axis: simd_normalize(SIMD3<Float>(1, 0.12, 0))
            )
            let base = fxModel(
                name: LiraARMotion.filamentBaseName,
                mesh: LiraMeshGeometry.filamentSegment(),
                color: palette.filament.withAlphaComponent(0.92),
                roughness: 0.28
            )
            base.scale = SIMD3<Float>(0.02, 0.02, 0.08)
            base.position = [0, 0, -0.06]
            let mid = fxModel(
                name: LiraARMotion.filamentMidName,
                mesh: LiraMeshGeometry.filamentSegment(),
                color: palette.filament.withAlphaComponent(0.9),
                roughness: 0.26
            )
            mid.scale = SIMD3<Float>(0.016, 0.016, 0.09)
            mid.position = [0, 0, -0.20]
            let tip = fxModel(
                name: LiraARMotion.filamentTipName,
                mesh: LiraMeshGeometry.filamentSegment(),
                color: palette.fringe.withAlphaComponent(0.85),
                roughness: 0.22
            )
            tip.scale = SIMD3<Float>(0.012, 0.012, 0.07)
            tip.position = [0, 0, -0.36]
            filament.addChild(base)
            filament.addChild(mid)
            filament.addChild(tip)
        }

        if let shadow = root.findEntity(named: "GroundShadow"), !hasModelGeometry(shadow) {
            let disc = fxModel(
                name: "GroundShadowMesh",
                mesh: LiraMeshGeometry.sphere(radius: 0.16, segments: 12, rings: 8),
                color: palette.shadow,
                roughness: 1
            )
            disc.scale = SIMD3<Float>(1.4, 0.012, 0.95)
            shadow.addChild(disc)
        }

        if let indicator = root.findEntity(named: "StatusIndicator"), !hasModelGeometry(indicator) {
            let bead = fxModel(
                name: "StatusIndicatorMesh",
                mesh: LiraMeshGeometry.sphere(radius: 0.018, segments: 8, rings: 6),
                color: palette.indicator,
                roughness: 0.25
            )
            indicator.addChild(bead)
            indicator.isEnabled = false
        }

        if let echo = root.findEntity(named: LiraARMotion.hunterEchoNodeName), !hasModelGeometry(echo) {
            let ghost = fxModel(
                name: "HunterEchoMesh",
                mesh: LiraMeshGeometry.sphere(radius: 0.12, segments: 10, rings: 8),
                color: palette.body.withAlphaComponent(0.2),
                roughness: 0.8
            )
            ghost.scale = SIMD3<Float>(0.65, 1.2, 0.9)
            echo.addChild(ghost)
            echo.isEnabled = false
        }
    }

    private static func fxModel(
        name: String,
        mesh: MeshResource,
        color: UIColor,
        roughness: Float = 0.35,
        metallic: Float = 0
    ) -> ModelEntity {
        let material = SimpleMaterial(
            color: color,
            roughness: .float(roughness),
            isMetallic: metallic > 0.05
        )
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }

    /// Paint only spectral FX nodes (A2/A3/shadow/chrome). Never touches Body Meshy mesh.
    static func applySpectralFXSkin(_ skin: LiraSkin, to root: Entity) {
        let palette = CompanionEntityFactory.SkinPalette(skin: skin)
        let fxSemantic: Set<String> = [
            "CoreGlow", "CoreHalo", "Filament",
            LiraARMotion.filamentBaseName, LiraARMotion.filamentMidName, LiraARMotion.filamentTipName,
            "GroundShadow", "StatusIndicator", LiraARMotion.hunterEchoNodeName,
            "CoreGlowMesh", "CoreHaloMesh", "GroundShadowMesh", "StatusIndicatorMesh", "HunterEchoMesh"
        ]

        func paint(_ entity: Entity, underBody: Bool) {
            let hereUnderBody = underBody || entity.name == "Body"
            // Authored mesh under Body stays as-is.
            if !hereUnderBody, let model = entity as? ModelEntity {
                let semantic = semanticName(for: entity)
                let key = fxSemantic.contains(entity.name) || fxSemantic.contains(semantic)
                    ? (fxSemantic.contains(entity.name) ? entity.name : semantic)
                    : semantic
                if fxSemantic.contains(entity.name) || fxSemantic.contains(semantic) {
                    let paintKey: String
                    switch entity.name {
                    case "CoreGlowMesh": paintKey = "CoreGlow"
                    case "CoreHaloMesh": paintKey = "CoreHalo"
                    case "GroundShadowMesh": paintKey = "GroundShadow"
                    case "StatusIndicatorMesh": paintKey = "StatusIndicator"
                    case "HunterEchoMesh": paintKey = LiraARMotion.hunterEchoNodeName
                    default: paintKey = key
                    }
                    let c = color(for: paintKey, palette: palette)
                    let roughness: Float
                    let metallic: Float
                    switch paintKey {
                    case "CoreGlow", "CoreHalo":
                        roughness = paintKey == "CoreHalo" ? 0.85 : 0.15
                        metallic = paintKey == "CoreGlow" ? 0.25 : 0
                    case "Filament", LiraARMotion.filamentBaseName, LiraARMotion.filamentMidName, LiraARMotion.filamentTipName:
                        roughness = 0.26
                        metallic = 0
                    case "GroundShadow":
                        roughness = 1
                        metallic = 0
                    default:
                        roughness = 0.4
                        metallic = 0
                    }
                    let alphaColor: UIColor
                    switch paintKey {
                    case "CoreHalo":
                        alphaColor = c.withAlphaComponent(0.32)
                    case LiraARMotion.filamentTipName:
                        alphaColor = palette.fringe.withAlphaComponent(0.85)
                    case LiraARMotion.hunterEchoNodeName:
                        alphaColor = palette.body.withAlphaComponent(0.2)
                    case "Filament", LiraARMotion.filamentBaseName, LiraARMotion.filamentMidName:
                        alphaColor = c.withAlphaComponent(0.9)
                    default:
                        alphaColor = c
                    }
                    model.model?.materials = [
                        SimpleMaterial(
                            color: alphaColor,
                            roughness: .float(roughness),
                            isMetallic: metallic > 0.05
                        )
                    ]
                }
            }
            for child in entity.children {
                paint(child, underBody: hereUnderBody)
            }
        }
        paint(root, underBody: false)
    }

    /// Scale visual content so bounds height ≈ target (handles feet-scale Meshy exports).
    static func normalizeVisualHeight(_ root: Entity, targetHeightMeters: Float) {
        let bounds = root.visualBounds(relativeTo: nil)
        let height = bounds.extents.y
        guard height.isFinite, height > 0.05 else { return }
        let factor = targetHeightMeters / height
        guard factor.isFinite, factor > 0.01, abs(factor - 1) > 0.05 else { return }
        root.scale *= factor
    }

    /// Shift Body so the lowest bound sits on y≈0 (Meshy meshes are often origin-centered).
    static func plantBodyOnGround(_ root: Entity) {
        guard let body = root.findEntity(named: "Body") else { return }
        let bounds = body.visualBounds(relativeTo: root)
        let minY = bounds.center.y - bounds.extents.y * 0.5
        guard minY.isFinite else { return }
        if abs(minY) > 0.001 {
            body.position.y -= minY
        }
    }

    /// Position spectral FX anchors from Body visual bounds so A2/A3 sit on the mesh.
    /// Call after height normalize + `plantBodyOnGround`. No-op without Body geometry.
    static func layoutSpectralFXAnchors(on root: Entity) {
        guard let body = root.findEntity(named: "Body") else { return }
        let bounds = body.visualBounds(relativeTo: root)
        let e = bounds.extents
        let c = bounds.center
        guard e.y.isFinite, e.y > 0.05 else { return }

        let minY = c.y - e.y * 0.5
        let maxY = c.y + e.y * 0.5
        // Chest ember slightly forward of torso center (A2).
        let chestY = minY + e.y * 0.52
        let chestZ = c.z + e.z * 0.22
        let headY = minY + e.y * 0.88
        let backZ = c.z - e.z * 0.35

        root.findEntity(named: "CoreGlow")?.position = SIMD3(c.x, chestY, chestZ)
        root.findEntity(named: "CoreHalo")?.position = SIMD3(c.x, chestY + 0.01, chestZ)
        root.findEntity(named: "Head")?.position = SIMD3(c.x, headY, c.z + e.z * 0.15)
        root.findEntity(named: "LeftEar")?.position = SIMD3(c.x - e.x * 0.22, headY + 0.04, c.z + e.z * 0.05)
        root.findEntity(named: "RightEar")?.position = SIMD3(c.x + e.x * 0.22, headY + 0.04, c.z + e.z * 0.05)
        root.findEntity(named: "Tail")?.position = SIMD3(c.x, minY + e.y * 0.35, backZ)
        root.findEntity(named: "Filament")?.position = SIMD3(c.x, minY + e.y * 0.48, backZ)
        root.findEntity(named: "GroundShadow")?.position = SIMD3(c.x, 0.008, c.z)
        root.findEntity(named: "StatusIndicator")?.position = SIMD3(c.x, maxY + 0.04, c.z)
        root.findEntity(named: LiraARMotion.hunterEchoNodeName)?.position = SIMD3(
            c.x + e.x * 0.15,
            chestY,
            c.z - e.z * 0.15
        )
    }

    /// Heuristic: single-mesh textured exports (Meshy) vs multi-part procedural/artist.
    /// Ignores spectral FX under CoreGlow/Filament/etc.
    static func looksLikeTexturedStaticMesh(_ root: Entity) -> Bool {
        isAuthoredBodyStaticMesh(root)
    }

    /// True when visual mass is under Body and Head is not a real mesh part.
    static func isAuthoredBodyStaticMesh(_ root: Entity) -> Bool {
        guard let body = root.findEntity(named: "Body") else { return false }
        guard hasModelGeometry(body) else { return false }
        if let head = root.findEntity(named: "Head"), hasModelGeometry(head) {
            return false
        }
        return true
    }

    static func applySkin(_ skin: LiraSkin, to root: Entity) {
        let palette = CompanionEntityFactory.SkinPalette(skin: skin)
        func paint(_ entity: Entity) {
            if let model = entity as? ModelEntity {
                let semantic = semanticName(for: entity)
                let color = color(for: semantic, palette: palette)
                let roughness: Float
                let metallic: Float
                switch semantic {
                case "CoreGlow", "CoreHalo":
                    roughness = 0.15
                    metallic = 0.2
                case "Filament", "FilamentTip", "FilamentBase", "FilamentMid":
                    roughness = 0.28
                    metallic = 0
                case "GroundShadow":
                    roughness = 1
                    metallic = 0
                default:
                    roughness = 0.5
                    metallic = 0
                }
                model.model?.materials = [
                    SimpleMaterial(
                        color: color,
                        roughness: .float(roughness),
                        isMetallic: metallic > 0.05
                    )
                ]
            }
            for child in entity.children {
                paint(child)
            }
        }
        paint(root)
    }

    /// Map USD nested mesh names (Sphere_*, Lira_*) back to semantic paint keys.
    private static func semanticName(for entity: Entity) -> String {
        let name = entity.name
        if CompanionEntityFactory.requiredNodeNames.contains(name)
            || ["CoreHalo", "FilamentTip", "FilamentBase", "FilamentMid", "Chest", "Haunch", "Snout", "HunterEcho"].contains(name)
        {
            return name
        }
        // Walk parents for a known semantic joint / part name.
        var parent = entity.parent
        while let p = parent {
            if CompanionEntityFactory.requiredNodeNames.contains(p.name)
                || ["CoreHalo", "FilamentTip", "FilamentBase", "FilamentMid", "Chest", "Haunch", "Snout"].contains(p.name)
            {
                return p.name
            }
            parent = p.parent
        }
        // Artist extras
        if name.contains("Ear") || name.hasPrefix("Lira_InnerEar") { return name.contains("R") ? "RightEar" : "LeftEar" }
        if name.hasPrefix("Lira_Eye") || name.hasPrefix("Lira_Temple") || name.hasPrefix("Lira_Forehead") {
            return "Head"
        }
        if name.hasPrefix("Lira_Leg") || name.hasPrefix("Lira_Paw") { return "Body" }
        return name
    }

    private static func color(
        for name: String,
        palette: CompanionEntityFactory.SkinPalette
    ) -> UIColor {
        switch name {
        case "CoreGlow", "CoreHalo":
            return palette.bondCore
        case "Filament", "FilamentTip", "FilamentBase", "FilamentMid":
            return palette.filament
        case "Tail":
            return palette.fringe
        case "GroundShadow":
            return palette.shadow
        case "StatusIndicator":
            return palette.indicator
        case "LeftEar", "RightEar", "Chest", "Haunch":
            return palette.bodySecondary
        case "HunterEcho":
            return palette.hunterFilament
        default:
            return palette.body
        }
    }
}
