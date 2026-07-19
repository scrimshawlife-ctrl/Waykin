import RealityKit
import UIKit

@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"

    /// Echo palette for the procedural Lira placeholder (WK_TOKENS_v0.2 day
    /// values — AR is lit by the real world, so one palette serves both
    /// modes). Still a placeholder: no production mesh is claimed.
    enum EchoPalette {
        static let body = UIColor(wkHex: 0x4A535E)          // ink secondary
        static let head = UIColor(wkHex: 0x3F8F8A)          // guide teal (A1)
        static let ears = UIColor(wkHex: 0x2F6F6B)          // guide deep
        static let bondCore = UIColor(wkHex: 0xD4A45A)      // bond gold (A2)
        static let filament = UIColor(wkHex: 0x7B8C9E)      // mist filament (A3)
        static let snout = UIColor(wkHex: 0x5FA8A2)         // guide light
        static let shadow = UIColor(white: 0.05, alpha: 0.65)
        static let indicator = UIColor.white
    }

    /// Builds the procedural Lira placeholder with the Living Familiar
    /// anchor structure:
    ///   A1 — head (guide teal, with snout so the silhouette has a facing)
    ///   A2 — chest bond core ("CoreGlow", bond gold; the renderer keeps
    ///        toggling its visibility per presentation state)
    ///   A3 — trail filament (arc of mist beads continuing the tail)
    /// Existing child names are preserved — they are load-bearing for the
    /// renderer (StatusIndicator, CoreGlow) and the embodiment tests.
    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) -> Entity {
        let root = Entity()
        root.name = Self.rootName

        let body = model(
            name: "Body",
            mesh: .generateSphere(radius: 0.18),
            color: EchoPalette.body
        )
        body.scale = SIMD3<Float>(0.9, 1.35, 0.72)
        body.position = [0, configuration.groundOffsetMeters + 0.28, 0]

        let head = model(
            name: "Head",
            mesh: .generateSphere(radius: 0.14),
            color: EchoPalette.head
        )
        head.position = [0, configuration.groundOffsetMeters + 0.54, 0.03]

        // A1 marker: an empty anchor at the head center for future gaze or
        // attention work, plus a snout so Lira has a readable facing.
        let headAnchor = Entity()
        headAnchor.name = "A1_HeadAnchor"
        headAnchor.position = head.position

        let snout = model(
            name: "Snout",
            mesh: .generateSphere(radius: 0.055),
            color: EchoPalette.snout
        )
        snout.scale = SIMD3<Float>(0.9, 0.7, 1.15)
        snout.position = [0, configuration.groundOffsetMeters + 0.51, 0.15]

        let leftEar = ear(name: "LeftEar", x: -0.08, y: configuration.groundOffsetMeters + 0.70)
        let rightEar = ear(name: "RightEar", x: 0.08, y: configuration.groundOffsetMeters + 0.70)

        let tail = model(
            name: "Tail",
            mesh: .generateSphere(radius: 0.14),
            color: EchoPalette.filament
        )
        tail.scale = SIMD3<Float>(0.32, 1, 0.32)
        tail.position = [0, configuration.groundOffsetMeters + 0.30, -0.21]
        tail.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])

        // A3: the tail continues into a filament — three mist beads arcing
        // up and back, echoing the trailing stroke of the brand mark.
        let filament = Entity()
        filament.name = "A3_Filament"
        let beadOffsets: [SIMD3<Float>] = [
            [0, configuration.groundOffsetMeters + 0.42, -0.30],
            [0.02, configuration.groundOffsetMeters + 0.52, -0.36],
            [0.05, configuration.groundOffsetMeters + 0.60, -0.40],
        ]
        for (index, offset) in beadOffsets.enumerated() {
            let bead = model(
                name: "FilamentBead\(index + 1)",
                mesh: .generateSphere(radius: 0.03 - Float(index) * 0.006),
                color: EchoPalette.filament
            )
            bead.position = offset
            filament.addChild(bead)
        }

        // A2: the chest bond core. Name stays "CoreGlow" — the renderer
        // owns its per-state visibility.
        let core = model(
            name: "CoreGlow",
            mesh: .generateSphere(radius: 0.055),
            color: EchoPalette.bondCore
        )
        core.position = [0, configuration.groundOffsetMeters + 0.34, 0.15]

        let shadow = model(
            name: "GroundShadow",
            mesh: .generateSphere(radius: 0.20),
            color: EchoPalette.shadow
        )
        shadow.scale = SIMD3<Float>(1, 0.01, 1)
        shadow.position = [0, configuration.groundOffsetMeters, 0]

        let indicator = model(
            name: "StatusIndicator",
            mesh: .generateSphere(radius: 0.025),
            color: EchoPalette.indicator
        )
        indicator.position = [0, configuration.groundOffsetMeters + 0.77, 0]

        [shadow, body, head, headAnchor, snout, leftEar, rightEar,
         tail, filament, core, indicator].forEach {
            root.addChild($0)
        }
        root.scale = SIMD3<Float>(repeating: configuration.companionHeightMeters / 0.72)
        return root
    }

    private func ear(name: String, x: Float, y: Float) -> ModelEntity {
        let entity = model(
            name: name,
            mesh: .generateSphere(radius: 0.085),
            color: EchoPalette.ears
        )
        entity.scale = SIMD3<Float>(0.65, 1, 0.45)
        entity.position = [x, y, 0]
        return entity
    }

    private func model(name: String, mesh: MeshResource, color: UIColor) -> ModelEntity {
        let material = SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }
}

extension UIColor {
    /// Echo token hex (matches the App-layer WKTokens values).
    convenience init(wkHex hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
