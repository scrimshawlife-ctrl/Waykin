import RealityKit
import UIKit

/// Living Familiar **AR mid-LOD** for Lira under Echo materials.
///
/// Anchors (product contract):
/// - **A1** `Head` — tapered non-canid snout
/// - **A2** `CoreGlow` — amber bond ember
/// - **A3** `Filament` — trailing path plume
///
/// Cosmetics via `LiraSkin`. Same hierarchy for Dawn / Veil / Rupture.
/// Optional artist USDZ may replace this later; see `LiraARAssetCatalog`.
@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"

    /// Semantic node names required by the renderer and tests.
    static let requiredNodeNames: [String] = [
        "Body", "Head", "LeftEar", "RightEar", "Tail",
        "Filament", "CoreGlow", "GroundShadow", "StatusIndicator"
    ]

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
        makeProceduralLivingFamiliar(configuration: configuration)
    }

    /// Spectral Living Familiar silhouette — mature, slightly uncanny, non-mascot.
    private func makeProceduralLivingFamiliar(
        configuration: CompanionVisualConfiguration
    ) -> Entity {
        let palette = SkinPalette(skin: skin)
        let root = Entity()
        root.name = Self.rootName
        let g = configuration.groundOffsetMeters

        // Ground contact shadow
        let shadow = model(
            name: "GroundShadow",
            mesh: .generateSphere(radius: 0.18),
            color: palette.shadow,
            roughness: 1.0
        )
        shadow.scale = SIMD3<Float>(1.25, 0.01, 0.85)
        shadow.position = [0, g, 0.02]

        // Torso — elongated, upright presence (not a pet blob)
        let body = model(
            name: "Body",
            mesh: .generateSphere(radius: 0.15),
            color: palette.body,
            roughness: 0.52
        )
        body.scale = SIMD3<Float>(0.72, 1.45, 1.05)
        body.position = [0, g + 0.28, 0.02]

        // Chest plate volume (secondary body mass under A2)
        let chest = model(
            name: "Chest",
            mesh: .generateSphere(radius: 0.11),
            color: palette.bodySecondary,
            roughness: 0.48
        )
        chest.scale = SIMD3<Float>(0.95, 0.85, 0.9)
        chest.position = [0, g + 0.32, 0.12]

        // A1 Head — tapered blade/snout, non-canid
        let head = model(
            name: "Head",
            mesh: .generateSphere(radius: 0.11),
            color: palette.body,
            roughness: 0.45
        )
        head.scale = SIMD3<Float>(0.55, 0.72, 1.55)
        head.position = [0, g + 0.58, 0.18]
        head.orientation = simd_quatf(angle: -0.12, axis: [1, 0, 0])

        // Sensor blades (ears) — offset pair, soft ridge language
        let leftEar = ear(name: "LeftEar", x: -0.055, y: g + 0.70, z: 0.10, color: palette.bodySecondary)
        leftEar.orientation = simd_quatf(angle: 0.35, axis: [0, 0, 1])
            * simd_quatf(angle: -0.2, axis: [1, 0, 0])
        let rightEar = ear(name: "RightEar", x: 0.06, y: g + 0.69, z: 0.09, color: palette.bodySecondary)
        rightEar.orientation = simd_quatf(angle: -0.28, axis: [0, 0, 1])
            * simd_quatf(angle: -0.18, axis: [1, 0, 0])

        // Hind mass / haunch
        let haunch = model(
            name: "Haunch",
            mesh: .generateSphere(radius: 0.10),
            color: palette.bodySecondary,
            roughness: 0.55
        )
        haunch.scale = SIMD3<Float>(0.85, 0.95, 1.1)
        haunch.position = [0, g + 0.22, -0.10]

        // Soft tail mass behind body
        let tail = model(
            name: "Tail",
            mesh: .generateSphere(radius: 0.09),
            color: palette.fringe,
            roughness: 0.38
        )
        tail.scale = SIMD3<Float>(0.4, 0.5, 1.55)
        tail.position = [0, g + 0.26, -0.26]
        tail.orientation = simd_quatf(angle: .pi / 5.5, axis: [1, 0, 0])

        // A3 Filament plume — long trailing path stream
        let filament = model(
            name: "Filament",
            mesh: .generateSphere(radius: 0.055),
            color: palette.filament,
            roughness: 0.28
        )
        filament.scale = SIMD3<Float>(0.28, 0.28, 2.8)
        filament.position = [0.03, g + 0.34, -0.48]
        filament.orientation = simd_quatf(angle: .pi / 4.2, axis: [1, 0.12, 0])

        // Filament tip (glowing path residue) — child of Filament for hierarchy clarity
        let filamentTip = model(
            name: "FilamentTip",
            mesh: .generateSphere(radius: 0.04),
            color: palette.fringe.withAlphaComponent(0.9),
            roughness: 0.22
        )
        filamentTip.scale = SIMD3<Float>(0.7, 0.7, 1.2)
        filamentTip.position = [0, 0, -0.55]
        filament.addChild(filamentTip)

        // A2 Bond core — amber chest ember
        let core = model(
            name: "CoreGlow",
            mesh: .generateSphere(radius: 0.042),
            color: palette.bondCore,
            roughness: 0.15,
            metallic: 0.2
        )
        core.position = [0, g + 0.33, 0.18]
        let glow = max(0.75, min(1.4, configuration.glowIntensity))
        core.scale = SIMD3<Float>(repeating: glow)

        // Soft outer glow shell around core (readability outdoors later)
        let coreHalo = model(
            name: "CoreHalo",
            mesh: .generateSphere(radius: 0.055),
            color: palette.bondCore.withAlphaComponent(0.35),
            roughness: 0.8
        )
        coreHalo.position = [0, g + 0.33, 0.18]
        coreHalo.scale = SIMD3<Float>(repeating: glow * 1.15)

        let indicator = model(
            name: "StatusIndicator",
            mesh: .generateSphere(radius: 0.02),
            color: palette.indicator,
            roughness: 0.25
        )
        indicator.position = [0, g + 0.80, 0.10]

        // Hunter pressure ghost (A3) — geometry/asymmetry, not gore. Off unless alert.
        let hunterEcho = model(
            name: LiraARMotion.hunterEchoNodeName,
            mesh: .generateSphere(radius: 0.14),
            color: palette.body.withAlphaComponent(0.22),
            roughness: 0.75
        )
        hunterEcho.scale = SIMD3<Float>(0.72, 1.35, 1.0)
        hunterEcho.position = [0.04, g + 0.28, -0.08]
        hunterEcho.isEnabled = false

        [shadow, body, chest, head, leftEar, rightEar, haunch, tail, filament, coreHalo, core, indicator, hunterEcho]
            .forEach { root.addChild($0) }

        root.scale = SIMD3<Float>(repeating: configuration.companionHeightMeters / 0.72)
        return root
    }

    private func ear(name: String, x: Float, y: Float, z: Float, color: UIColor) -> ModelEntity {
        let entity = model(
            name: name,
            mesh: .generateSphere(radius: 0.065),
            color: color,
            roughness: 0.5
        )
        // Blade-like sensor: tall, thin, short depth
        entity.scale = SIMD3<Float>(0.35, 1.45, 0.55)
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
