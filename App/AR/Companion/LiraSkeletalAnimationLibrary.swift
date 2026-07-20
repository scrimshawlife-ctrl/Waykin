import Foundation
import RealityKit
import simd

/// Multi-joint skeletal AnimationLibrary clips for Lira AR mid-LOD.
///
/// Generates RealityKit `AnimationResource` groups bound to joint paths under
/// `LiraRoot`. Not DCC bone export — runtime-authored puppet clips that share
/// the same joint names as procedural and USDZ hierarchies.
///
/// **Policy:** When `LiraSkeletalPlayer` is driving, the renderer must not apply
/// conflicting per-frame pure-function channels on the same joints.
@MainActor
enum LiraSkeletalAnimationLibrary {
    enum ClipID: String, CaseIterable, Sendable {
        case idle
        case follow
        case investigate
        case alert
        case celebrate
        case spawn

        var isLooping: Bool {
            switch self {
            case .celebrate, .spawn: return false
            default: return true
            }
        }
    }

    /// Map presentation state → ambient skeletal clip.
    static func clip(for state: CompanionPresentationState) -> ClipID {
        switch state {
        case .idle: return .idle
        case .follow: return .follow
        case .investigate: return .investigate
        case .alert: return .alert
        case .celebrate: return .celebrate
        }
    }

    /// Build the full named library (clip id → resource).
    static func makeLibrary() throws -> [ClipID: AnimationResource] {
        var result: [ClipID: AnimationResource] = [:]
        for id in ClipID.allCases {
            result[id] = try generate(clip: id)
        }
        return result
    }

    static func generate(clip: ClipID) throws -> AnimationResource {
        switch clip {
        case .idle: return try idleClip()
        case .follow: return try followClip()
        case .investigate: return try investigateClip()
        case .alert: return try alertClip()
        case .celebrate: return try celebrateClip()
        case .spawn: return try spawnClip()
        }
    }

    // MARK: - Clips

    /// Soft A2 breath + mild A3 filament sway + micro head.
    static func idleClip(duration: TimeInterval = 1.8) throws -> AnimationResource {
        let half = max(0.05, duration) / 2
        return try AnimationResource.group(with: [
            try scalePulse(path: "CoreGlow", to: 1.08, duration: half, reverse: true),
            try scalePulse(path: "CoreHalo", to: 1.12, duration: half, reverse: true),
            try rotateSwing(
                path: "Filament",
                from: filamentRest(),
                to: filamentTilt(pitchDelta: 0.08, yaw: 0.03),
                duration: half,
                reverse: true
            ),
            try rotateSwing(
                path: "Head",
                from: headRest(pitch: -0.12),
                to: headRest(pitch: -0.12, yaw: 0.04),
                duration: half,
                reverse: true
            ),
            try bodyBob(amplitude: 0.008, duration: half)
        ])
    }

    /// Follow: root-relative head yaw + filament lag + soft breath.
    static func followClip(duration: TimeInterval = 2.2) throws -> AnimationResource {
        let half = max(0.05, duration) / 2
        return try AnimationResource.group(with: [
            try scalePulse(path: "CoreGlow", to: 1.06, duration: half, reverse: true),
            try rotateSwing(
                path: "Head",
                from: headRest(pitch: -0.12, yaw: 0.04),
                to: headRest(pitch: -0.10, yaw: 0.12),
                duration: half,
                reverse: true
            ),
            try rotateSwing(
                path: "Filament",
                from: filamentRest(),
                to: filamentTilt(pitchDelta: 0.09, yaw: -0.04),
                duration: half,
                reverse: true
            ),
            try rotateSwing(
                path: "Tail",
                from: tailRest(),
                to: tailTilt(0.07),
                duration: half,
                reverse: true
            ),
            try bodyBob(amplitude: 0.006, duration: half)
        ])
    }

    /// Investigate: head leans off-axis, slower breath.
    static func investigateClip(duration: TimeInterval = 2.0) throws -> AnimationResource {
        let half = max(0.05, duration) / 2
        return try AnimationResource.group(with: [
            try scalePulse(path: "CoreGlow", to: 1.05, duration: half, reverse: true),
            try rotateSwing(
                path: "Head",
                from: headRest(pitch: -0.16, yaw: -0.12),
                to: headRest(pitch: -0.20, yaw: -0.22),
                duration: half,
                reverse: true
            ),
            try rotateSwing(
                path: "Filament",
                from: filamentRest(),
                to: filamentTilt(pitchDelta: 0.06, yaw: 0.05),
                duration: half,
                reverse: true
            ),
            try bodyBob(amplitude: 0.005, duration: half)
        ])
    }

    /// Alert: tighter breath, ear tension, faster filament, slight crouch bob.
    static func alertClip(duration: TimeInterval = 0.9) throws -> AnimationResource {
        let half = max(0.05, duration) / 2
        return try AnimationResource.group(with: [
            try scalePulse(path: "CoreGlow", to: 1.04, duration: half, reverse: true),
            try rotateSwing(
                path: "Head",
                from: headRest(pitch: -0.08, yaw: 0.04),
                to: headRest(pitch: -0.06, yaw: 0.08),
                duration: half,
                reverse: true
            ),
            try rotateSwing(
                path: "Filament",
                from: filamentRest(),
                to: filamentTilt(pitchDelta: 0.14, yaw: 0.06),
                duration: half * 0.85,
                reverse: true
            ),
            try rotateSwing(
                path: "LeftEar",
                from: earRest(isLeft: true),
                to: earFlutter(isLeft: true, delta: 0.08),
                duration: half * 0.7,
                reverse: true
            ),
            try rotateSwing(
                path: "RightEar",
                from: earRest(isLeft: false),
                to: earFlutter(isLeft: false, delta: 0.08),
                duration: half * 0.7,
                reverse: true
            ),
            try bodyBob(amplitude: 0.004, duration: half)
        ])
    }

    /// Celebrate one-shot: core bloom + head tilt + tail lift (root lift stays presentation-table).
    static func celebrateClip(duration: TimeInterval = 0.55) throws -> AnimationResource {
        let d = max(0.05, duration)
        return try AnimationResource.group(with: [
            try scalePulse(path: "CoreGlow", to: 1.14, duration: d, reverse: false),
            try rotateSwing(
                path: "Head",
                from: headRest(pitch: -0.08),
                to: headRest(pitch: -0.05, yaw: 0.16),
                duration: d,
                reverse: false
            ),
            try rotateSwing(
                path: "Tail",
                from: tailRest(),
                to: tailTilt(0.14),
                duration: d,
                reverse: false
            )
        ])
    }

    /// Spawn coalesce one-shot on root scale (additive language only on CoreGlow; root scale is presentation).
    static func spawnClip(duration: TimeInterval = 0.7) throws -> AnimationResource {
        let d = max(0.05, duration)
        var from = Transform.identity
        from.scale = SIMD3<Float>(repeating: 0.92)
        let definition = FromToByAnimation<Transform>(
            from: from,
            to: Transform.identity,
            duration: d,
            timing: .easeOut,
            isAdditive: false,
            bindTarget: jointTransform("CoreGlow"),
            repeatMode: .none
        )
        return try AnimationResource.generate(with: definition)
    }

    /// Bind path to a named child entity's transform under the playing root.
    private static func jointTransform(_ name: String) -> BindTarget {
        .entity(name).transform
    }

    // MARK: - Pose helpers
    // Transform clips replace full local transform — preserve factory rest scale/translation.

    private static let bodyRestScale = SIMD3<Float>(0.68, 1.52, 1.12)
    private static let bodyRestXZ = SIMD3<Float>(0.008, 0, 0.03)
    private static let tailRestScale = SIMD3<Float>(0.38, 0.48, 1.65)
    private static let tailRestPosition = SIMD3<Float>(-0.015, LiraARMotion.defaultGroundOffsetMeters + 0.25, -0.28)

    private static func filamentRest() -> Transform {
        var t = Transform.identity
        t.rotation = simd_quatf(
            angle: LiraARMotion.filamentBasePitch,
            axis: simd_normalize(SIMD3<Float>(1, 0.12, 0))
        )
        return t
    }

    private static func filamentTilt(pitchDelta: Float, yaw: Float) -> Transform {
        var t = Transform.identity
        let pitch = LiraARMotion.filamentBasePitch + pitchDelta
        let qPitch = simd_quatf(angle: pitch, axis: simd_normalize(SIMD3<Float>(1, 0.12, 0)))
        let qYaw = simd_quatf(angle: yaw, axis: [0, 1, 0])
        t.rotation = qYaw * qPitch
        return t
    }

    private static func headRest(pitch: Float, yaw: Float = 0) -> Transform {
        var t = Transform.identity
        let qPitch = simd_quatf(angle: pitch, axis: [1, 0, 0])
        let qYaw = simd_quatf(angle: yaw, axis: [0, 1, 0])
        t.rotation = qYaw * qPitch
        return t
    }

    private static func tailRest() -> Transform {
        var t = Transform.identity
        t.scale = tailRestScale
        t.translation = tailRestPosition
        t.rotation = simd_quatf(angle: .pi / 5.5, axis: [1, 0, 0])
        return t
    }

    private static func tailTilt(_ sway: Float) -> Transform {
        var t = Transform.identity
        t.scale = tailRestScale
        t.translation = tailRestPosition
        t.rotation = simd_quatf(angle: .pi / 5.5 + sway, axis: [1, 0, 0])
            * simd_quatf(angle: sway * 0.35, axis: [0, 1, 0])
        return t
    }

    private static func earRest(isLeft: Bool) -> Transform {
        var t = Transform.identity
        let baseZ: Float = isLeft ? 0.35 : -0.28
        let baseX: Float = isLeft ? -0.15 : -0.12
        t.rotation = simd_quatf(angle: baseZ, axis: [0, 0, 1])
            * simd_quatf(angle: baseX, axis: [1, 0, 0])
        return t
    }

    private static func earFlutter(isLeft: Bool, delta: Float) -> Transform {
        var t = Transform.identity
        let baseZ: Float = isLeft ? 0.35 : -0.28
        let baseX: Float = isLeft ? -0.15 : -0.12
        let side: Float = isLeft ? 1 : -1
        t.rotation = simd_quatf(angle: baseZ + side * delta, axis: [0, 0, 1])
            * simd_quatf(angle: baseX, axis: [1, 0, 0])
        return t
    }

    private static func bodyBob(amplitude: Float, duration: TimeInterval) throws -> AnimationResource {
        let restY = LiraARMotion.bodyRestY()
        var from = Transform.identity
        from.scale = bodyRestScale
        from.translation = SIMD3<Float>(bodyRestXZ.x, restY, bodyRestXZ.z)
        var to = from
        to.translation.y = restY + amplitude
        let definition = FromToByAnimation<Transform>(
            from: from,
            to: to,
            duration: duration,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: jointTransform("Body"),
            repeatMode: .autoReverse
        )
        return try AnimationResource.generate(with: definition)
    }

    private static func scalePulse(
        path: String,
        to scale: Float,
        duration: TimeInterval,
        reverse: Bool
    ) throws -> AnimationResource {
        var toTransform = Transform.identity
        toTransform.scale = SIMD3<Float>(repeating: scale)
        let definition = FromToByAnimation<Transform>(
            from: Transform.identity,
            to: toTransform,
            duration: duration,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: jointTransform(path),
            repeatMode: reverse ? .autoReverse : .none
        )
        return try AnimationResource.generate(with: definition)
    }

    private static func rotateSwing(
        path: String,
        from: Transform,
        to: Transform,
        duration: TimeInterval,
        reverse: Bool
    ) throws -> AnimationResource {
        let definition = FromToByAnimation<Transform>(
            from: from,
            to: to,
            duration: duration,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: jointTransform(path),
            repeatMode: reverse ? .autoReverse : .none
        )
        return try AnimationResource.generate(with: definition)
    }
}
