import RealityKit
import UIKit

@MainActor
struct CompanionVisualConfiguration: Equatable, Sendable {
    var heightMeters: Float = 0.62
    var scale: Float = 1

    var normalized: CompanionVisualConfiguration {
        CompanionVisualConfiguration(
            heightMeters: min(max(heightMeters.isFinite ? heightMeters : 0.62, 0.3), 1.2),
            scale: min(max(scale.isFinite ? scale : 1, 0.5), 2)
        )
    }
}

@MainActor
enum CompanionEntityFactory {
    static let rootName = "LiraRoot"
    static let requiredChildNames = [
        "Body", "Head", "LeftEar", "RightEar", "Tail", "CoreGlow", "GroundShadow", "StatusIndicator"
    ]

    static func makeLira(configuration: CompanionVisualConfiguration = .init()) -> Entity {
        let config = configuration.normalized
        let root = Entity()
        root.name = rootName
        root.scale = SIMD3(repeating: config.scale)

        let spirit = SimpleMaterial(color: UIColor(red: 0.30, green: 0.82, blue: 0.92, alpha: 1), roughness: 0.42, isMetallic: false)
        let light = SimpleMaterial(color: UIColor(red: 0.78, green: 0.98, blue: 1, alpha: 1), roughness: 0.25, isMetallic: false)
        let dark = SimpleMaterial(color: UIColor(red: 0.07, green: 0.20, blue: 0.25, alpha: 1), roughness: 0.7, isMetallic: false)

        let body = model(name: "Body", mesh: .generateSphere(radius: 0.16), material: spirit)
        body.scale = SIMD3<Float>(0.92, 1.20, 1.28)
        body.position = [0, config.heightMeters * 0.38, 0]

        let head = model(name: "Head", mesh: .generateSphere(radius: 0.13), material: spirit)
        head.position = [0, config.heightMeters * 0.72, 0.035]

        let leftEar = model(name: "LeftEar", mesh: .generateBox(size: 0.095), material: dark)
        leftEar.scale = [0.45, 1.15, 0.35]
        leftEar.position = [-0.075, config.heightMeters * 0.93, 0]
        leftEar.orientation = simd_quatf(angle: -0.22, axis: [0, 0, 1])

        let rightEar = model(name: "RightEar", mesh: .generateBox(size: 0.095), material: dark)
        rightEar.scale = [0.45, 1.15, 0.35]
        rightEar.position = [0.075, config.heightMeters * 0.93, 0]
        rightEar.orientation = simd_quatf(angle: 0.22, axis: [0, 0, 1])

        let tail = model(name: "Tail", mesh: .generateBox(size: 0.16), material: spirit)
        tail.scale = [0.34, 0.35, 1.25]
        tail.position = [0, config.heightMeters * 0.34, -0.21]
        tail.orientation = simd_quatf(angle: -0.45, axis: [1, 0, 0])

        let core = model(name: "CoreGlow", mesh: .generateSphere(radius: 0.055), material: light)
        core.position = [0, config.heightMeters * 0.46, 0.145]

        let shadow = model(name: "GroundShadow", mesh: .generateCylinder(height: 0.006, radius: 0.20), material: dark)
        shadow.scale = [1.15, 1, 0.65]
        shadow.position = [0, 0.003, 0]

        let indicator = model(name: "StatusIndicator", mesh: .generateSphere(radius: 0.025), material: light)
        indicator.position = [0, config.heightMeters * 1.12, 0]

        [body, head, leftEar, rightEar, tail, core, shadow, indicator].forEach(root.addChild)
        return root
    }

    private static func model(name: String, mesh: MeshResource, material: Material) -> ModelEntity {
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }
}
