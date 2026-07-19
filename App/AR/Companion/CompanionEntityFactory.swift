import RealityKit
import UIKit

/// Procedural Lira placeholder under **Echo** materials (Living Familiar anchors).
/// Not production sculpted mesh — single-developer stand-in with A1/A2/A3 identity.
@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"

    /// Echo day materials (sRGB approximations of WK_TOKENS_v0.2).
    enum EchoMaterial {
        static let body = UIColor(red: 0.91, green: 0.85, blue: 0.77, alpha: 1)      // cream body
        static let bodySecondary = UIColor(red: 0.79, green: 0.72, blue: 0.60, alpha: 1)
        static let head = UIColor(red: 0.91, green: 0.85, blue: 0.77, alpha: 1)
        static let fringe = UIColor(red: 0.25, green: 0.56, blue: 0.54, alpha: 1)    // guide teal
        static let bondCore = UIColor(red: 0.83, green: 0.64, blue: 0.35, alpha: 1)  // bond gold
        static let filament = UIColor(red: 0.48, green: 0.62, blue: 0.60, alpha: 1)
        static let hunterFilament = UIColor(red: 0.48, green: 0.55, blue: 0.62, alpha: 1)
        static let shadow = UIColor(white: 0.05, alpha: 0.55)
        static let indicator = UIColor(red: 0.90, green: 0.92, blue: 0.94, alpha: 1)
    }

    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        let root = Entity()
        root.name = Self.rootName
        let g = configuration.groundOffsetMeters

        // Ground shadow
        let shadow = model(
            name: "GroundShadow",
            mesh: .generateSphere(radius: 0.20),
            color: EchoMaterial.shadow,
            roughness: 1.0
        )
        shadow.scale = SIMD3<Float>(1.1, 0.012, 0.75)
        shadow.position = [0, g, 0.02]

        // Body — elongated Living Familiar torso (not sphere blob)
        let body = model(
            name: "Body",
            mesh: .generateSphere(radius: 0.17),
            color: EchoMaterial.body,
            roughness: 0.55
        )
        body.scale = SIMD3<Float>(0.95, 1.15, 1.35)
        body.position = [0, g + 0.26, 0]

        // A1 Head — tapered non-canid cranial form
        let head = model(
            name: "Head",
            mesh: .generateSphere(radius: 0.12),
            color: EchoMaterial.head,
            roughness: 0.5
        )
        head.scale = SIMD3<Float>(0.85, 1.05, 1.15)
        head.position = [0, g + 0.52, 0.16]

        // Offset ear / sensor pair (A4 supporting)
        let leftEar = ear(name: "LeftEar", x: -0.07, y: g + 0.64, z: 0.12)
        let rightEar = ear(name: "RightEar", x: 0.075, y: g + 0.63, z: 0.11)

        // Hind mass + plume base (Tail keeps semantic name for tests; acts as plume root)
        let tail = model(
            name: "Tail",
            mesh: .generateSphere(radius: 0.10),
            color: EchoMaterial.fringe,
            roughness: 0.4
        )
        tail.scale = SIMD3<Float>(0.45, 0.55, 1.4)
        tail.position = [0, g + 0.28, -0.22]
        tail.orientation = simd_quatf(angle: .pi / 5, axis: [1, 0, 0])

        // A3 Trailing filament stream (additional identity anchor)
        let filament = model(
            name: "Filament",
            mesh: .generateSphere(radius: 0.06),
            color: EchoMaterial.filament,
            roughness: 0.35
        )
        filament.scale = SIMD3<Float>(0.35, 0.35, 2.2)
        filament.position = [0.02, g + 0.30, -0.38]
        filament.orientation = simd_quatf(angle: .pi / 4.5, axis: [1, 0.15, 0])

        // A2 Chest bond core / emitter
        let core = model(
            name: "CoreGlow",
            mesh: .generateSphere(radius: 0.045),
            color: EchoMaterial.bondCore,
            roughness: 0.2,
            metallic: 0.15
        )
        core.position = [0, g + 0.30, 0.14]
        // Scale glow by configuration
        let glow = max(0.75, min(1.4, configuration.glowIntensity))
        core.scale = SIMD3<Float>(repeating: glow)

        let indicator = model(
            name: "StatusIndicator",
            mesh: .generateSphere(radius: 0.022),
            color: EchoMaterial.indicator,
            roughness: 0.25
        )
        indicator.position = [0, g + 0.74, 0.12]

        [shadow, body, head, leftEar, rightEar, tail, filament, core, indicator].forEach {
            root.addChild($0)
        }
        root.scale = SIMD3<Float>(repeating: configuration.companionHeightMeters / 0.72)
        return root
    }

    private func ear(name: String, x: Float, y: Float, z: Float) -> ModelEntity {
        let entity = model(
            name: name,
            mesh: .generateSphere(radius: 0.07),
            color: EchoMaterial.bodySecondary,
            roughness: 0.55
        )
        // Soft offset paired sensors — not cartoon dog ears
        entity.scale = SIMD3<Float>(0.55, 1.15, 0.4)
        entity.position = [x, y, z]
        return entity
    }

    private func model(
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
}
