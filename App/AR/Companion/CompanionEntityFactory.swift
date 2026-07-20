import RealityKit
import UIKit
import simd

/// Living Familiar **AR mid-LOD** for Lira under Echo materials.
///
/// Anchors (product contract):
/// - **A1** `Head` — tapered non-canid snout mesh
/// - **A2** `CoreGlow` — amber bond ember
/// - **A3** `Filament` — multi-segment trailing path plume
///
/// Geometry from `LiraMeshGeometry` (real MeshDescriptor meshes). Cosmetics via `LiraSkin`.
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

    /// Spectral Living Familiar — low-poly mesh mid-LOD (mature, slightly uncanny).
    private func makeProceduralLivingFamiliar(
        configuration: CompanionVisualConfiguration
    ) -> Entity {
        let palette = SkinPalette(skin: skin)
        let root = Entity()
        root.name = Self.rootName
        let g = configuration.groundOffsetMeters

        let shadow = model(
            name: "GroundShadow",
            mesh: LiraMeshGeometry.sphere(radius: 0.18, segments: 12, rings: 8),
            color: palette.shadow,
            roughness: 1.0
        )
        shadow.scale = SIMD3<Float>(1.35, 0.012, 0.92)
        shadow.position = [0.01, g, 0.02]

        // Torso mass — ellipsoid mesh scaled for upright presence
        let body = model(
            name: "Body",
            mesh: LiraMeshGeometry.sphere(radius: 0.15, segments: 18, rings: 14),
            color: palette.body,
            roughness: 0.52
        )
        body.scale = SIMD3<Float>(0.68, 1.52, 1.12)
        body.position = [0.008, LiraARMotion.bodyRestY(groundOffset: g), 0.03]

        let chest = model(
            name: "Chest",
            mesh: LiraMeshGeometry.sphere(radius: 0.11, segments: 14, rings: 10),
            color: palette.bodySecondary,
            roughness: 0.48
        )
        chest.scale = SIMD3<Float>(0.98, 0.82, 0.95)
        chest.position = [0.01, g + 0.34, 0.13]

        // A1 Head — real tapered mesh (not a scaled sphere)
        let head = model(
            name: "Head",
            mesh: LiraMeshGeometry.taperedHead(length: 0.24, baseRadius: 0.085, tipRadius: 0.032, segments: 14, rings: 12),
            color: palette.body,
            roughness: 0.45
        )
        head.position = [0.012, g + 0.59, 0.14]
        head.orientation = simd_quatf(angle: -0.10, axis: [1, 0, 0])

        // Optional snout accent for facing readability
        let snout = model(
            name: "Snout",
            mesh: LiraMeshGeometry.sphere(radius: 0.04, segments: 10, rings: 8),
            color: palette.bodySecondary,
            roughness: 0.42
        )
        snout.scale = SIMD3<Float>(0.55, 0.42, 1.15)
        snout.position = [0.015, g + 0.56, 0.30]

        // Sensor blades (real wedge meshes, not scaled spheres)
        let leftEar = model(
            name: "LeftEar",
            mesh: LiraMeshGeometry.sensorBlade(height: 0.15, width: 0.03, depth: 0.05),
            color: palette.bodySecondary,
            roughness: 0.5
        )
        leftEar.position = [-0.055, g + 0.68, 0.08]
        leftEar.orientation = simd_quatf(angle: 0.35, axis: [0, 0, 1])
            * simd_quatf(angle: -0.15, axis: [1, 0, 0])

        let rightEar = model(
            name: "RightEar",
            mesh: LiraMeshGeometry.sensorBlade(height: 0.14, width: 0.028, depth: 0.048),
            color: palette.bodySecondary,
            roughness: 0.5
        )
        rightEar.position = [0.062, g + 0.67, 0.075]
        rightEar.orientation = simd_quatf(angle: -0.28, axis: [0, 0, 1])
            * simd_quatf(angle: -0.12, axis: [1, 0, 0])

        let haunch = model(
            name: "Haunch",
            mesh: LiraMeshGeometry.sphere(radius: 0.10, segments: 12, rings: 10),
            color: palette.bodySecondary,
            roughness: 0.55
        )
        haunch.scale = SIMD3<Float>(0.88, 1.02, 1.18)
        haunch.position = [-0.02, g + 0.22, -0.12]

        let tail = model(
            name: "Tail",
            mesh: LiraMeshGeometry.sphere(radius: 0.09, segments: 12, rings: 10),
            color: palette.fringe,
            roughness: 0.38
        )
        tail.scale = SIMD3<Float>(0.38, 0.48, 1.65)
        tail.position = [-0.015, g + 0.25, -0.28]
        tail.orientation = simd_quatf(angle: .pi / 5.5, axis: [1, 0, 0])

        // A3 multi-segment filament (base + mid + tip) for wave animation
        let filament = Entity()
        filament.name = "Filament"
        filament.position = [0.04, g + 0.35, -0.42]
        filament.orientation = simd_quatf(angle: LiraARMotion.filamentBasePitch, axis: [1, 0.12, 0])

        let filBase = model(
            name: LiraARMotion.filamentBaseName,
            mesh: LiraMeshGeometry.filamentSegment(radius: 0.04, length: 0.16),
            color: palette.filament,
            roughness: 0.28
        )
        filBase.scale = SIMD3<Float>(0.022, 0.022, 0.09)
        filBase.position = [0, 0, -0.08]

        let filMid = model(
            name: LiraARMotion.filamentMidName,
            mesh: LiraMeshGeometry.filamentSegment(radius: 0.035, length: 0.18),
            color: palette.filament.withAlphaComponent(0.95),
            roughness: 0.26
        )
        filMid.scale = SIMD3<Float>(0.018, 0.018, 0.10)
        filMid.position = [0, 0, -0.28]

        let filamentTip = model(
            name: LiraARMotion.filamentTipName,
            mesh: LiraMeshGeometry.filamentSegment(radius: 0.028, length: 0.14),
            color: palette.fringe.withAlphaComponent(0.9),
            roughness: 0.22
        )
        filamentTip.scale = SIMD3<Float>(0.014, 0.014, 0.08)
        filamentTip.position = [0, 0, -0.48]

        filament.addChild(filBase)
        filament.addChild(filMid)
        filament.addChild(filamentTip)

        // A2 Bond core
        let glow = max(0.75, min(1.4, configuration.glowIntensity))
        let core = model(
            name: "CoreGlow",
            mesh: LiraMeshGeometry.sphere(radius: 0.044, segments: 12, rings: 10),
            color: palette.bondCore,
            roughness: 0.15,
            metallic: 0.2
        )
        core.position = [0.01, g + 0.34, 0.19]
        core.scale = SIMD3<Float>(repeating: glow)

        let coreHalo = model(
            name: "CoreHalo",
            mesh: LiraMeshGeometry.sphere(radius: 0.058, segments: 12, rings: 10),
            color: palette.bondCore.withAlphaComponent(0.35),
            roughness: 0.8
        )
        coreHalo.position = [0.01, g + 0.34, 0.19]
        coreHalo.scale = SIMD3<Float>(repeating: glow * 1.15)

        let indicator = model(
            name: "StatusIndicator",
            mesh: LiraMeshGeometry.sphere(radius: 0.02, segments: 8, rings: 6),
            color: palette.indicator,
            roughness: 0.25
        )
        indicator.position = [0.02, g + 0.82, 0.12]

        let hunterEcho = model(
            name: LiraARMotion.hunterEchoNodeName,
            mesh: LiraMeshGeometry.sphere(radius: 0.14, segments: 12, rings: 10),
            color: palette.body.withAlphaComponent(0.22),
            roughness: 0.75
        )
        hunterEcho.scale = SIMD3<Float>(0.70, 1.32, 0.98)
        hunterEcho.position = [0.05, g + LiraARMotion.hunterEchoBaseYAboveGround, -0.09]
        hunterEcho.isEnabled = false

        [shadow, body, chest, head, snout, leftEar, rightEar, haunch, tail, filament, coreHalo, core, indicator, hunterEcho]
            .forEach { root.addChild($0) }

        root.scale = SIMD3<Float>(repeating: configuration.companionHeightMeters / 0.72)
        return root
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

extension CompanionEntityFactory {
    enum EchoMaterial {
        static var body: UIColor { SkinPalette(skin: .dawn).body }
        static var fringe: UIColor { SkinPalette(skin: .dawn).fringe }
        static var bondCore: UIColor { SkinPalette(skin: .dawn).bondCore }
    }
}
