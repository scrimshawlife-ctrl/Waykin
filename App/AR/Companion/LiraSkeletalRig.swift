import Foundation
import RealityKit

/// Joint-hierarchy contract for Lira AR mid-LOD skeletal AnimationLibrary.
///
/// Runtime clips bind to **named semantic entity paths** under `LiraRoot`
/// (`AnimationBindTarget.entity`). Packaged USDZ may also carry Blender
/// `LiraArmature` + heat-map skin weights on Body/Head/ears/legs; FX filament/core
/// stay rigid. Procedural factory uses the same joint names without DCC weights.
enum LiraSkeletalRig {
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
}
