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
            var root = Self.normalizeRoot(loaded)
            var promoted = false
            if !Self.hasRequiredNodes(root) {
                root = Self.promoteIncompleteHierarchy(root)
                promoted = true
            }
            guard Self.hasRequiredNodes(root) else {
                clearTemplate(reason: .procedural, note: "hierarchy_invalid")
                return
            }
            Self.normalizeVisualHeight(root, targetHeightMeters: 0.72)
            template = root
            source = .usdz(url.lastPathComponent)
            preserveAuthoredMaterials = promoted || Self.looksLikeTexturedStaticMesh(root)
            if preserveAuthoredMaterials {
                loadNote = "usdz_active_meshy_textured_static"
            } else {
                loadNote = "usdz_active_artist_blend_hero_dcc_mid_lod"
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
        _ = reason
    }

    /// Sync spawn used by the renderer. Clones USDZ template when preloaded; else procedural.
    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        if let template {
            let clone = template.clone(recursive: true)
            clone.name = CompanionEntityFactory.rootName
            // Keep Meshy PBR textures; only paint procedural/artist multi-part meshes.
            if !preserveAuthoredMaterials {
                Self.applySkin(skin, to: clone)
            }
            let scale = configuration.companionHeightMeters / 0.72
            clone.scale = SIMD3<Float>(repeating: scale)
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

    /// Meshy image-to-3d (and similar) ships a single textured mesh without A1–A3 names.
    /// Promote into the semantic hierarchy so puppet animation can bind to joints.
    static func promoteIncompleteHierarchy(_ root: Entity) -> Entity {
        guard !hasRequiredNodes(root) else { return root }

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

        // Empty transform anchors for A1–A3 + required chrome (puppet / motion targets).
        let markerOffsets: [String: SIMD3<Float>] = [
            "Head": SIMD3(0, 0.42, 0.10),
            "LeftEar": SIMD3(-0.10, 0.50, 0.04),
            "RightEar": SIMD3(0.10, 0.50, 0.04),
            "Tail": SIMD3(0, 0.18, -0.28),
            "Filament": SIMD3(0, 0.26, -0.22),
            "CoreGlow": SIMD3(0, 0.30, 0.06),
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
            halo.position = SIMD3(0, 0.32, 0.06)
            root.addChild(halo)
        }
        return root
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

    /// Heuristic: single-mesh textured exports (Meshy) vs multi-part procedural/artist.
    static func looksLikeTexturedStaticMesh(_ root: Entity) -> Bool {
        var modelCount = 0
        func walk(_ entity: Entity) {
            if entity is ModelEntity { modelCount += 1 }
            for child in entity.children { walk(child) }
        }
        walk(root)
        // Meshy static: one mesh + empty markers. Artist rig: many named model parts.
        return modelCount <= 2
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
