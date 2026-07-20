import Foundation
import RealityKit

/// Joint-hierarchy contract for Lira AR mid-LOD skeletal AnimationLibrary.
///
/// Runtime clips bind to **named semantic entity paths** under `LiraRoot`
/// (`AnimationBindTarget.entity`). Packaged USDZ may also carry Blender
/// `LiraArmature` + heat-map skin weights on Body/Head/ears/legs; FX filament/core
/// stay rigid. Procedural factory uses the same joint names without DCC weights.
///
/// **Meshy / single textured mesh:** geometry lives under `Body`; Head/ears/etc.
/// are empty promote markers. Puppet style switches to body-centric clips so
/// procedural multi-part rest scales never squash the authored mesh.
enum LiraSkeletalRig {
    /// How runtime-generated puppet clips should treat rest poses.
    enum PuppetStyle: String, Sendable {
        /// Procedural / multi-part artist mesh — factory rest scales on Body/Tail.
        case multiPart
        /// Single textured mesh under Body (Meshy static) — identity rest on Body.
        case staticMesh
    }

    /// Root entity name (matches factory / loader).
    static let rootName = CompanionEntityFactory.rootName

    /// Joints driven by skeletal ambient clips (excludes hunter echo / status).
    static let animatedJoints: [String] = [
        "Body",
        "Head",
        "LeftEar",
        "RightEar",
        "Tail",
        "Filament",
        "CoreGlow",
        "CoreHalo"
    ]

    /// Full semantic set required for embodiment (includes non-animated).
    static let requiredNodes: [String] = CompanionEntityFactory.requiredNodeNames

    /// RealityKit `AnimationBindTarget.path` relative to `LiraRoot`.
    static func path(_ joint: String) -> String { joint }

    /// Filament segment paths (optional; procedural multi-seg only).
    static let filamentSegments: [String] = [
        LiraARMotion.filamentBaseName,
        LiraARMotion.filamentMidName,
        LiraARMotion.filamentTipName
    ]

    static func hasSkeletalJoints(_ entity: Entity) -> Bool {
        // Minimal set for useful clip playback.
        ["Head", "CoreGlow", "Filament"].allSatisfy { entity.findEntity(named: $0) != nil }
    }

    /// Detect Meshy-style single mesh vs multi-part procedural/artist hierarchy.
    static func puppetStyle(for entity: Entity) -> PuppetStyle {
        guard let body = entity.findEntity(named: "Body") else { return .multiPart }

        var modelsUnderBody = 0
        var modelsOutsideBody = 0
        func walk(_ node: Entity, underBody: Bool) {
            let here = underBody || node.name == "Body"
            if node is ModelEntity {
                if here { modelsUnderBody += 1 } else { modelsOutsideBody += 1 }
            }
            for child in node.children {
                walk(child, underBody: here)
            }
        }
        walk(entity, underBody: false)

        // Head/ears/filament as ModelEntity ⇒ multi-part (factory or artist).
        let multiPartMarkers = ["Head", "LeftEar", "RightEar", "Tail", "Filament", "CoreGlow"]
        let markerHasMesh = multiPartMarkers.contains { name in
            guard let joint = entity.findEntity(named: name) else { return false }
            if joint is ModelEntity { return true }
            return joint.children.contains { $0 is ModelEntity }
        }

        if markerHasMesh { return .multiPart }
        if modelsUnderBody >= 1, modelsOutsideBody == 0 { return .staticMesh }
        // Promote path: mesh reparented under Body, empty sibling markers.
        if modelsUnderBody >= 1, !markerHasMesh { return .staticMesh }
        return .multiPart
    }
}
