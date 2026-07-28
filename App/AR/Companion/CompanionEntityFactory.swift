import RealityKit
import UIKit

@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"
    static let animatedMeshName = "LiraAnimatedMesh"
    private static var cachedAsset: Entity?

    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        if let asset = Self.loadAsset()?.clone(recursive: true) {
            return makeAssetLira(asset: asset, configuration: configuration)
        }
        return makeProceduralLira(configuration: configuration)
    }

    private static func loadAsset() -> Entity? {
        if let cachedAsset {
            return cachedAsset
        }
        guard let asset = try? Entity.load(named: "Lira_Walking") else {
            return nil
        }
        cachedAsset = asset
        return asset
    }

    private func makeAssetLira(
        asset: Entity,
        configuration: CompanionVisualConfiguration
    ) -> Entity {
        let root = Entity()
        root.name = Self.rootName

        asset.name = Self.animatedMeshName
        let bounds = asset.visualBounds(relativeTo: asset)
        let sourceHeight = max(bounds.extents.y, 0.001)
        let scale = configuration.companionHeightMeters / sourceHeight
        asset.scale = SIMD3<Float>(repeating: scale)
        asset.position = [
            -bounds.center.x * scale,
            configuration.groundOffsetMeters - bounds.min.y * scale,
            -bounds.center.z * scale,
        ]
        root.addChild(asset)

        addPresentationOverlays(to: root, configuration: configuration)
        return root
    }

    private func makeProceduralLira(configuration: CompanionVisualConfiguration) -> Entity {
        let root = Entity()
        root.name = Self.rootName

        let body = model(
            name: "Body",
            mesh: .generateSphere(radius: 0.18),
            color: UIColor(red: 0.30, green: 0.72, blue: 0.92, alpha: 1)
        )
        body.scale = SIMD3<Float>(0.9, 1.35, 0.72)
        body.position = [0, configuration.groundOffsetMeters + 0.28, 0]

        let head = model(
            name: "Head",
            mesh: .generateSphere(radius: 0.14),
            color: UIColor(red: 0.42, green: 0.86, blue: 1.0, alpha: 1)
        )
        head.position = [0, configuration.groundOffsetMeters + 0.54, 0.03]

        let leftEar = ear(name: "LeftEar", x: -0.08, y: configuration.groundOffsetMeters + 0.70)
        let rightEar = ear(name: "RightEar", x: 0.08, y: configuration.groundOffsetMeters + 0.70)

        let tail = model(
            name: "Tail",
            mesh: .generateSphere(radius: 0.14),
            color: UIColor(red: 0.25, green: 0.64, blue: 0.90, alpha: 1)
        )
        tail.scale = SIMD3<Float>(0.32, 1, 0.32)
        tail.position = [0, configuration.groundOffsetMeters + 0.30, -0.21]
        tail.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])

        let core = model(
            name: "CoreGlow",
            mesh: .generateSphere(radius: 0.055),
            color: UIColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 1)
        )
        core.position = [0, configuration.groundOffsetMeters + 0.34, 0.15]

        let shadow = model(
            name: "GroundShadow",
            mesh: .generateSphere(radius: 0.20),
            color: UIColor(white: 0.05, alpha: 0.65)
        )
        shadow.scale = SIMD3<Float>(1, 0.01, 1)
        shadow.position = [0, configuration.groundOffsetMeters, 0]

        let indicator = model(
            name: "StatusIndicator",
            mesh: .generateSphere(radius: 0.025),
            color: UIColor.white
        )
        indicator.position = [0, configuration.groundOffsetMeters + 0.77, 0]

        [shadow, body, head, leftEar, rightEar, tail, core, indicator].forEach {
            root.addChild($0)
        }
        root.scale = SIMD3<Float>(repeating: configuration.companionHeightMeters / 0.72)
        return root
    }

    /// Retained as an async-compatible entry point for callers that prepare entities off the render path.
    func makeLiraWithWalking(configuration: CompanionVisualConfiguration = .liraPlaceholder) async -> Entity {
        makeLira(configuration: configuration)
    }

    private func addPresentationOverlays(
        to root: Entity,
        configuration: CompanionVisualConfiguration
    ) {
        let height = configuration.companionHeightMeters
        let core = model(
            name: "CoreGlow",
            mesh: .generateSphere(radius: max(0.018, height * 0.045)),
            color: UIColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 1)
        )
        core.position = [0, configuration.groundOffsetMeters + height * 0.46, height * 0.18]

        let indicator = model(
            name: "StatusIndicator",
            mesh: .generateSphere(radius: max(0.012, height * 0.025)),
            color: .white
        )
        indicator.position = [0, configuration.groundOffsetMeters + height * 1.08, 0]

        root.addChild(core)
        root.addChild(indicator)
    }

    private func ear(name: String, x: Float, y: Float) -> ModelEntity {
        let entity = model(
            name: name,
            mesh: .generateSphere(radius: 0.085),
            color: UIColor(red: 0.34, green: 0.76, blue: 0.96, alpha: 1)
        )
        entity.scale = SIMD3<Float>(0.65, 1, 0.45)
        entity.position = [x, y, 0]
        entity.scale = SIMD3<Float>(0.65, 1, 0.45)
        return entity
    }

    private func model(name: String, mesh: MeshResource, color: UIColor) -> ModelEntity {
        let material = SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }
}
