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
    ///
    /// Spectral FX under CoreGlow/Filament do **not** force multiPart — only a real
    /// Head mesh (factory/artist multi-part) does. Static mesh keeps identity Body rest.
    static func puppetStyle(for entity: Entity) -> PuppetStyle {
        guard let body = entity.findEntity(named: "Body") else { return .multiPart }

        func hasModelGeometry(_ node: Entity) -> Bool {
            if node is ModelEntity { return true }
            return node.children.contains { hasModelGeometry($0) }
        }

        guard hasModelGeometry(body) else { return .multiPart }

        // Factory / artist: Head is a ModelEntity with real geometry.
        if let head = entity.findEntity(named: "Head"), hasModelGeometry(head) {
            return .multiPart
        }
        // Meshy promote: Body holds authored mesh; Head is empty transform marker.
        return .staticMesh
    }
}
