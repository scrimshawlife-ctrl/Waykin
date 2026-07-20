import Foundation
import RealityKit
import simd

/// Procedural `AnimationResource` clips for Lira AR mid-LOD.
///
/// Not DCC skeletal AnimationLibrary — RealityKit transform clips generated at
/// runtime and bound to Living Familiar hierarchy nodes. Safe when USDZ lacks bones.
///
/// **Playback policy:** `ARWorldCommandRenderer` drives motion via pure
/// `LiraARMotion` channels each frame (deterministic tests). These clips are
/// available for lab / optional one-shot playback and must not fight per-frame
/// local motion on the same bind targets.
@MainActor
enum LiraARAnimationLibrary {
    enum ClipID: String, CaseIterable, Sendable {
        case idleBreath
        case alertTension
        case celebrateLift
        case followSway
        case spawnCoalesce
    }

    /// Generate a looping scale pulse for A2 CoreGlow (idle breath).
    static func idleBreathClip(duration: TimeInterval = 1.8) throws -> AnimationResource {
        let safeDuration = max(0.05, duration)
        var to = Transform.identity
        to.scale = SIMD3<Float>(repeating: 1.08)
        let definition = FromToByAnimation<Transform>(
            from: Transform.identity,
            to: to,
            duration: safeDuration / 2,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .autoReverse
        )
        return try AnimationResource.generate(with: definition)
    }

    /// Subtle root yaw sway for follow state.
    static func followSwayClip(duration: TimeInterval = 2.2) throws -> AnimationResource {
        let safeDuration = max(0.05, duration)
        var to = Transform.identity
        to.rotation = simd_quatf(angle: 0.12, axis: [0, 1, 0])
        let definition = FromToByAnimation<Transform>(
            from: Transform.identity,
            to: to,
            duration: safeDuration / 2,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .autoReverse
        )
        return try AnimationResource.generate(with: definition)
    }

    /// Alert: slight crouch scale on companion root.
    static func alertTensionClip(duration: TimeInterval = 0.9) throws -> AnimationResource {
        let safeDuration = max(0.05, duration)
        var to = Transform.identity
        to.scale = SIMD3<Float>(1.04, 0.96, 1.04)
        to.translation = SIMD3<Float>(0, 0, -0.04)
        let definition = FromToByAnimation<Transform>(
            from: Transform.identity,
            to: to,
            duration: safeDuration / 2,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .autoReverse
        )
        return try AnimationResource.generate(with: definition)
    }

    /// Celebrate lift (one-shot, non-looping).
    static func celebrateLiftClip(duration: TimeInterval = 0.55) throws -> AnimationResource {
        let safeDuration = max(0.05, duration)
        var to = Transform.identity
        to.translation = SIMD3<Float>(0, 0.08, 0)
        to.rotation = simd_quatf(angle: .pi / 8, axis: [0, 1, 0])
        to.scale = SIMD3<Float>(repeating: 1.08)
        let definition = FromToByAnimation<Transform>(
            from: Transform.identity,
            to: to,
            duration: safeDuration,
            timing: .easeInOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .none
        )
        return try AnimationResource.generate(with: definition)
    }

    /// Spawn coalesce scale (one-shot).
    static func spawnCoalesceClip(duration: TimeInterval = 0.7) throws -> AnimationResource {
        let safeDuration = max(0.05, duration)
        var from = Transform.identity
        from.scale = SIMD3<Float>(repeating: 0.92)
        let definition = FromToByAnimation<Transform>(
            from: from,
            to: Transform.identity,
            duration: safeDuration,
            timing: .easeOut,
            isAdditive: false,
            bindTarget: .transform,
            repeatMode: .none
        )
        return try AnimationResource.generate(with: definition)
    }

    /// Resolve looping ambient clip for presentation state (one-shots excluded).
    static func loopingClip(for state: CompanionPresentationState) -> ClipID? {
        switch state {
        case .idle, .investigate: return .idleBreath
        case .follow: return .followSway
        case .alert: return .alertTension
        case .celebrate: return nil
        }
    }

    static func generate(clip: ClipID) throws -> AnimationResource {
        switch clip {
        case .idleBreath: return try idleBreathClip()
        case .alertTension: return try alertTensionClip()
        case .celebrateLift: return try celebrateLiftClip()
        case .followSway: return try followSwayClip()
        case .spawnCoalesce: return try spawnCoalesceClip()
        }
    }
}
