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
    private var template: Entity?
    var skin: LiraSkin = .dawn

    /// Load optional artist USDZ. Safe to call repeatedly.
    ///
    /// - Parameter usdzURL: Defaults to the packaged catalog URL. Pass `nil` (or an
    ///   unreadable URL) from tests to exercise procedural fallback without requiring
    ///   the app bundle to omit `Lira_AR_Base.usdz`.
    func preloadFromBundle(usdzURL: URL? = LiraARAssetCatalog.baseUSDZURL) async {
        guard let url = usdzURL else {
            clearTemplate(reason: .procedural)
            return
        }
        do {
            let loaded = try await Self.loadEntity(from: url)
            let root = Self.normalizeRoot(loaded)
            guard Self.hasRequiredNodes(root) else {
                clearTemplate(reason: .procedural)
                return
            }
            template = root
            source = .usdz(url.lastPathComponent)
        } catch {
            clearTemplate(reason: .procedural)
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
    }

    func clearTemplate(reason: Source = .procedural) {
        template = nil
        source = .procedural
        _ = reason
    }

    /// Sync spawn used by the renderer. Clones USDZ template when preloaded; else procedural.
    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        if let template {
            let clone = template.clone(recursive: true)
            clone.name = CompanionEntityFactory.rootName
            Self.applySkin(skin, to: clone)
            let scale = configuration.companionHeightMeters / 0.72
            clone.scale = SIMD3<Float>(repeating: scale)
            return clone
        }
        return CompanionEntityFactory(skin: skin).makeLira(configuration: configuration)
    }

    var activeLODDescription: String {
        switch source {
        case .procedural:
            return "procedural_living_familiar_mid"
        case .usdz(let name):
            return "artist_usdz:\(name)"
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

    static func applySkin(_ skin: LiraSkin, to root: Entity) {
        let palette = CompanionEntityFactory.SkinPalette(skin: skin)
        func paint(_ entity: Entity) {
            if let model = entity as? ModelEntity {
                let color = color(for: entity.name, palette: palette)
                let roughness: Float
                let metallic: Float
                switch entity.name {
                case "CoreGlow":
                    roughness = 0.15
                    metallic = 0.2
                case "Filament", "FilamentTip":
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

    private static func color(
        for name: String,
        palette: CompanionEntityFactory.SkinPalette
    ) -> UIColor {
        switch name {
        case "CoreGlow", "CoreHalo":
            return palette.bondCore
        case "Filament", "FilamentTip":
            return palette.filament
        case "Tail":
            return palette.fringe
        case "GroundShadow":
            return palette.shadow
        case "StatusIndicator":
            return palette.indicator
        case "LeftEar", "RightEar", "Chest", "Haunch":
            return palette.bodySecondary
        default:
            return palette.body
        }
    }
}
