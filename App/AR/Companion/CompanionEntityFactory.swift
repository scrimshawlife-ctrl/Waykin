import RealityKit
import UIKit

/// Procedural Lira placeholder under **Echo** materials (Living Familiar anchors).
/// Materials follow selected `LiraSkin` (Dawn / Veil / Rupture). Not production sculpted mesh.
@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"

    var skin: LiraSkin

    init(skin: LiraSkin = .dawn) {
        self.skin = skin
    }

    /// UIKit palette from cosmetic skin.
    struct SkinPalette {
        let body: UIColor
        let bodySecondary: UIColor
        let fringe: UIColor
        let bondCore: UIColor
        let filament: UIColor
        let hunterFilament: UIColor
        let shadow: UIColor
        let indicator: UIColor

        init(skin: LiraSkin) {
            switch skin {
            case .dawn:
                body = UIColor(red: 0.91, green: 0.85, blue: 0.77, alpha: 1)
                bodySecondary = UIColor(red: 0.79, green: 0.72, blue: 0.60, alpha: 1)
                fringe = UIColor(red: 0.25, green: 0.56, blue: 0.54, alpha: 1)
                bondCore = UIColor(red: 0.83, green: 0.64, blue: 0.35, alpha: 1)
                filament = UIColor(red: 0.48, green: 0.62, blue: 0.60, alpha: 1)
                hunterFilament = UIColor(red: 0.48, green: 0.55, blue: 0.62, alpha: 1)
            case .veil:
                body = UIColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1)
                bodySecondary = UIColor(red: 0.23, green: 0.25, blue: 0.31, alpha: 1)
                fringe = UIColor(red: 0.48, green: 0.55, blue: 0.62, alpha: 1)
                bondCore = UIColor(red: 0.79, green: 0.54, blue: 0.48, alpha: 1)
                filament = UIColor(red: 0.48, green: 0.55, blue: 0.62, alpha: 1)
                hunterFilament = UIColor(red: 0.42, green: 0.35, blue: 0.54, alpha: 1)
            case .rupture:
                body = UIColor(red: 0.29, green: 0.27, blue: 0.35, alpha: 1)
                bodySecondary = UIColor(red: 0.36, green: 0.31, blue: 0.48, alpha: 1)
                fringe = UIColor(red: 0.54, green: 0.59, blue: 0.66, alpha: 1)
                bondCore = UIColor(red: 0.83, green: 0.64, blue: 0.35, alpha: 1)
                filament = UIColor(red: 0.54, green: 0.59, blue: 0.66, alpha: 1)
                hunterFilament = UIColor(red: 0.42, green: 0.31, blue: 0.54, alpha: 1)
            }
            shadow = UIColor(white: 0.05, alpha: 0.55)
            indicator = UIColor(red: 0.90, green: 0.92, blue: 0.94, alpha: 1)
        }
    }

    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        let palette = SkinPalette(skin: skin)
        let root = Entity()
        root.name = Self.rootName
        let g = configuration.groundOffsetMeters

        let shadow = model(
            name: "GroundShadow",
            mesh: .generateSphere(radius: 0.20),
            color: palette.shadow,
            roughness: 1.0
        )
        shadow.scale = SIMD3<Float>(1.1, 0.012, 0.75)
        shadow.position = [0, g, 0.02]

        let body = model(
            name: "Body",
            mesh: .generateSphere(radius: 0.17),
            color: palette.body,
            roughness: 0.55
        )
        body.scale = SIMD3<Float>(0.95, 1.15, 1.35)
        body.position = [0, g + 0.26, 0]

        let head = model(
            name: "Head",
            mesh: .generateSphere(radius: 0.12),
            color: palette.body,
            roughness: 0.5
        )
        head.scale = SIMD3<Float>(0.85, 1.05, 1.15)
        head.position = [0, g + 0.52, 0.16]

        let leftEar = ear(name: "LeftEar", x: -0.07, y: g + 0.64, z: 0.12, color: palette.bodySecondary)
        let rightEar = ear(name: "RightEar", x: 0.075, y: g + 0.63, z: 0.11, color: palette.bodySecondary)

        let tail = model(
            name: "Tail",
            mesh: .generateSphere(radius: 0.10),
            color: palette.fringe,
            roughness: 0.4
        )
        tail.scale = SIMD3<Float>(0.45, 0.55, 1.4)
        tail.position = [0, g + 0.28, -0.22]
        tail.orientation = simd_quatf(angle: .pi / 5, axis: [1, 0, 0])

        let filament = model(
            name: "Filament",
            mesh: .generateSphere(radius: 0.06),
            color: palette.filament,
            roughness: 0.35
        )
        filament.scale = SIMD3<Float>(0.35, 0.35, 2.2)
        filament.position = [0.02, g + 0.30, -0.38]
        filament.orientation = simd_quatf(angle: .pi / 4.5, axis: [1, 0.15, 0])

        let core = model(
            name: "CoreGlow",
            mesh: .generateSphere(radius: 0.045),
            color: palette.bondCore,
            roughness: 0.2,
            metallic: 0.15
        )
        core.position = [0, g + 0.30, 0.14]
        let glow = max(0.75, min(1.4, configuration.glowIntensity))
        core.scale = SIMD3<Float>(repeating: glow)

        let indicator = model(
            name: "StatusIndicator",
            mesh: .generateSphere(radius: 0.022),
            color: palette.indicator,
            roughness: 0.25
        )
        indicator.position = [0, g + 0.74, 0.12]

        [shadow, body, head, leftEar, rightEar, tail, filament, core, indicator].forEach {
            root.addChild($0)
        }
        root.scale = SIMD3<Float>(repeating: configuration.companionHeightMeters / 0.72)
        return root
    }

    private func ear(name: String, x: Float, y: Float, z: Float, color: UIColor) -> ModelEntity {
        let entity = model(
            name: name,
            mesh: .generateSphere(radius: 0.07),
            color: color,
            roughness: 0.55
        )
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

// Keep static material references used by tests
extension CompanionEntityFactory {
    enum EchoMaterial {
        static var body: UIColor { SkinPalette(skin: .dawn).body }
        static var fringe: UIColor { SkinPalette(skin: .dawn).fringe }
        static var bondCore: UIColor { SkinPalette(skin: .dawn).bondCore }
    }
}
