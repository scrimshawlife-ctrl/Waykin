import RealityKit
import UIKit

@MainActor
struct CompanionVisualConfiguration: Equatable {
    let companionHeightMeters: Float
    let groundOffsetMeters: Float

    static let liraPlaceholder = CompanionVisualConfiguration(
        companionHeightMeters: 0.62,
        groundOffsetMeters: 0.015
    )

    init(companionHeightMeters: Float, groundOffsetMeters: Float) {
        self.companionHeightMeters = min(max(companionHeightMeters.isFinite ? companionHeightMeters : 0.62, 0.3), 1.2)
        self.groundOffsetMeters = min(max(groundOffsetMeters.isFinite ? groundOffsetMeters : 0.015, 0), 0.1)
    }
}

@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"
    static let requiredChildNames = [
        "Body", "Head", "LeftEar", "RightEar", "Tail", "CoreGlow", "GroundShadow", "StatusIndicator"
    ]

    func makeLira(
        configuration: CompanionVisualConfiguration = .liraPlaceholder
    ) -> Entity {
        let root = Entity()
        root.name = Self.rootName

        let scale = configuration.companionHeightMeters / 0.62
        root.scale = SIMD3(repeating: scale)
        root.position.y = configuration.groundOffsetMeters

        let bodyMaterial = SimpleMaterial(color: UIColor(red: 0.18, green: 0.72, blue: 0.82, alpha: 1), isMetallic: false)
        let accentMaterial = SimpleMaterial(color: UIColor(red: 0.72, green: 0.94, blue: 1, alpha: 1), isMetallic: false)
        let darkMaterial = SimpleMaterial(color: UIColor(red: 0.08, green: 0.18, blue: 0.24, alpha: 1), isMetallic: false)
        let glowMaterial = SimpleMaterial(color: UIColor(red: 0.85, green: 1, blue: 1, alpha: 1), isMetallic: true)

        let body = ModelEntity(mesh: .generateSphere(radius: 0.18), materials: [bodyMaterial])
        body.name = "Body"
        body.scale = [1.0, 1.25, 0.82]
        body.position = [0, 0.26, 0]

        let head = ModelEntity(mesh: .generateSphere(radius: 0.135), materials: [accentMaterial])
        head.name = "Head"
        head.scale = [1.0, 0.92, 1.0]
        head.position = [0, 0.49, -0.055]

        let leftEar = ModelEntity(mesh: .generateCone(height: 0.18, radius: 0.065), materials: [accentMaterial])
        leftEar.name = "LeftEar"
        leftEar.position = [-0.075, 0.64, -0.04]
        leftEar.orientation = simd_quatf(angle: -.12, axis: [0, 0, 1])

        let rightEar = ModelEntity(mesh: .generateCone(height: 0.18, radius: 0.065), materials: [accentMaterial])
        rightEar.name = "RightEar"
        rightEar.position = [0.075, 0.64, -0.04]
        rightEar.orientation = simd_quatf(angle: .12, axis: [0, 0, 1])

        let tail = ModelEntity(mesh: .generateCylinder(height: 0.34, radius: 0.045), materials: [bodyMaterial])
        tail.name = "Tail"
        tail.position = [0, 0.27, 0.20]
        tail.orientation = simd_quatf(angle: -.75, axis: [1, 0, 0])

        let core = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [glowMaterial])
        core.name = "CoreGlow"
        core.position = [0, 0.31, -0.155]

        let shadow = ModelEntity(mesh: .generateCylinder(height: 0.006, radius: 0.20), materials: [darkMaterial])
        shadow.name = "GroundShadow"
        shadow.position = [0, 0.004, 0]
        shadow.scale = [1, 1, 0.55]

        let indicator = ModelEntity(mesh: .generateSphere(radius: 0.025), materials: [glowMaterial])
        indicator.name = "StatusIndicator"
        indicator.position = [0, 0.76, 0]

        [shadow, body, head, leftEar, rightEar, tail, core, indicator].forEach(root.addChild)
        return root
    }
}
