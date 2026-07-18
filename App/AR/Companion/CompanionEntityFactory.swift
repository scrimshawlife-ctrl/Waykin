import RealityKit
import UIKit

@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"

    @MainActor
    private enum Resources {
        static let bodyMesh = MeshResource.generateSphere(radius: 0.18)
        static let headMesh = MeshResource.generateSphere(radius: 0.14)
        static let earMesh = MeshResource.generateSphere(radius: 0.065)
        static let tailMesh = MeshResource.generateSphere(radius: 0.08)
        static let coreMesh = MeshResource.generateSphere(radius: 0.055)
        static let shadowMesh = MeshResource.generateSphere(radius: 0.20)
        static let indicatorMesh = MeshResource.generateSphere(radius: 0.025)

        static let bodyMaterial = SimpleMaterial(
            color: UIColor(red: 0.30, green: 0.72, blue: 0.92, alpha: 1),
            roughness: 0.35,
            isMetallic: false
        )
        static let headMaterial = SimpleMaterial(
            color: UIColor(red: 0.42, green: 0.86, blue: 1.0, alpha: 1),
            roughness: 0.35,
            isMetallic: false
        )
        static let earMaterial = SimpleMaterial(
            color: UIColor(red: 0.34, green: 0.76, blue: 0.96, alpha: 1),
            roughness: 0.35,
            isMetallic: false
        )
        static let tailMaterial = SimpleMaterial(
            color: UIColor(red: 0.25, green: 0.64, blue: 0.90, alpha: 1),
            roughness: 0.35,
            isMetallic: false
        )
        static let coreMaterial = SimpleMaterial(
            color: UIColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 1),
            roughness: 0.35,
            isMetallic: false
        )
        static let shadowMaterial = SimpleMaterial(
            color: UIColor(white: 0.05, alpha: 0.65),
            roughness: 0.35,
            isMetallic: false
        )
        static let indicatorMaterial = SimpleMaterial(
            color: .white,
            roughness: 0.35,
            isMetallic: false
        )
    }

    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        let root = Entity()
        root.name = Self.rootName

        let body = model(
            name: "Body",
            mesh: Resources.bodyMesh,
            material: Resources.bodyMaterial
        )
        body.scale = SIMD3<Float>(0.9, 1.35, 0.72)
        body.position = [0, configuration.groundOffsetMeters + 0.28, 0]

        let head = model(
            name: "Head",
            mesh: Resources.headMesh,
            material: Resources.headMaterial
        )
        head.position = [0, configuration.groundOffsetMeters + 0.54, 0.03]

        let leftEar = ear(name: "LeftEar", x: -0.08, y: configuration.groundOffsetMeters + 0.70)
        let rightEar = ear(name: "RightEar", x: 0.08, y: configuration.groundOffsetMeters + 0.70)

        let tail = model(
            name: "Tail",
            mesh: Resources.tailMesh,
            material: Resources.tailMaterial
        )
        tail.scale = SIMD3<Float>(0.55, 1.75, 0.55)
        tail.position = [0, configuration.groundOffsetMeters + 0.30, -0.21]
        tail.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])

        let core = model(
            name: "CoreGlow",
            mesh: Resources.coreMesh,
            material: Resources.coreMaterial
        )
        let glowScale = Float(0.75 + (configuration.glowIntensity * 0.5))
        core.scale = SIMD3<Float>(repeating: glowScale)
        core.position = [0, configuration.groundOffsetMeters + 0.34, 0.15]

        let shadow = model(
            name: "GroundShadow",
            mesh: Resources.shadowMesh,
            material: Resources.shadowMaterial
        )
        shadow.scale = SIMD3<Float>(1, 0.02, 1)
        shadow.position = [0, configuration.groundOffsetMeters, 0]

        let indicator = model(
            name: "StatusIndicator",
            mesh: Resources.indicatorMesh,
            material: Resources.indicatorMaterial
        )
        indicator.position = [0, configuration.groundOffsetMeters + 0.77, 0]

        [shadow, body, head, leftEar, rightEar, tail, core, indicator].forEach {
            root.addChild($0)
        }
        root.scale = SIMD3<Float>(repeating: configuration.companionHeightMeters / 0.72)
        return root
    }

    private func ear(name: String, x: Float, y: Float) -> ModelEntity {
        let entity = model(
            name: name,
            mesh: Resources.earMesh,
            material: Resources.earMaterial
        )
        entity.scale = SIMD3<Float>(0.8, 1.45, 0.7)
        entity.position = [x, y, 0]
        return entity
    }

    private func model(
        name: String,
        mesh: MeshResource,
        material: SimpleMaterial
    ) -> ModelEntity {
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }
}
