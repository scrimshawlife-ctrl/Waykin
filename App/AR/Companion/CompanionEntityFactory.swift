import RealityKit
import UIKit

struct CompanionVisualConfiguration: Equatable, Sendable {
    var companionHeightMeters: Float = 0.62
    var groundOffsetMeters: Float = 0
    var glowScale: Float = 1

    var normalized: CompanionVisualConfiguration {
        CompanionVisualConfiguration(
            companionHeightMeters: min(max(companionHeightMeters.isFinite ? companionHeightMeters : 0.62, 0.25), 1.2),
            groundOffsetMeters: min(max(groundOffsetMeters.isFinite ? groundOffsetMeters : 0, -0.05), 0.2),
            glowScale: min(max(glowScale.isFinite ? glowScale : 1, 0.25), 2)
        )
    }
}

@MainActor
enum CompanionEntityFactory {
    static let rootName = "LiraRoot"

    static func makeLira(configuration: CompanionVisualConfiguration = .init()) -> Entity {
        let config = configuration.normalized
        let root = Entity()
        root.name = rootName

        let body = model(
            name: "Body",
            mesh: .generateCapsule(height: config.companionHeightMeters * 0.46, radius: config.companionHeightMeters * 0.14),
            color: UIColor(red: 0.18, green: 0.56, blue: 0.74, alpha: 1)
        )
        body.position.y = config.groundOffsetMeters + config.companionHeightMeters * 0.31

        let headRadius = config.companionHeightMeters * 0.15
        let head = model(name: "Head", mesh: .generateSphere(radius: headRadius), color: .systemTeal)
        head.position = [0, config.groundOffsetMeters + config.companionHeightMeters * 0.63, config.companionHeightMeters * 0.035]

        let leftEar = model(name: "LeftEar", mesh: .generateBox(size: [0.055, 0.16, 0.045], cornerRadius: 0.018), color: .systemTeal)
        leftEar.position = [-headRadius * 0.48, headRadius * 0.82, 0]
        leftEar.orientation = simd_quatf(angle: -0.18, axis: [0, 0, 1])

        let rightEar = model(name: "RightEar", mesh: .generateBox(size: [0.055, 0.16, 0.045], cornerRadius: 0.018), color: .systemTeal)
        rightEar.position = [headRadius * 0.48, headRadius * 0.82, 0]
        rightEar.orientation = simd_quatf(angle: 0.18, axis: [0, 0, 1])
        head.addChild(leftEar)
        head.addChild(rightEar)

        let tail = model(name: "Tail", mesh: .generateCapsule(height: config.companionHeightMeters * 0.32, radius: config.companionHeightMeters * 0.045), color: .systemCyan)
        tail.position = [0, config.groundOffsetMeters + config.companionHeightMeters * 0.31, -config.companionHeightMeters * 0.16]
        tail.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])

        let glow = model(name: "CoreGlow", mesh: .generateSphere(radius: config.companionHeightMeters * 0.055 * config.glowScale), color: .white)
        glow.position = [0, config.groundOffsetMeters + config.companionHeightMeters * 0.39, config.companionHeightMeters * 0.13]

        let shadow = model(name: "GroundShadow", mesh: .generateCylinder(height: 0.006, radius: config.companionHeightMeters * 0.22), color: UIColor(white: 0.08, alpha: 0.72))
        shadow.position.y = config.groundOffsetMeters + 0.004

        let indicator = model(name: "StatusIndicator", mesh: .generateSphere(radius: 0.025), color: .systemYellow)
        indicator.position = [0, config.groundOffsetMeters + config.companionHeightMeters * 0.9, 0]
        indicator.isEnabled = false

        [shadow, body, head, tail, glow, indicator].forEach(root.addChild)
        return root
    }

    private static func model(name: String, mesh: MeshResource, color: UIColor) -> ModelEntity {
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.name = name
        return entity
    }
}
