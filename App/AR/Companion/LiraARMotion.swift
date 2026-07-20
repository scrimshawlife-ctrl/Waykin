import Foundation
import simd

/// Deterministic local AR motion for Living Familiar mid-LOD.
/// Pure functions — breath, sway, head attention, ear/tail, multi-segment filament, hunter echo, spawn.
enum LiraARMotion {
    static let hunterEchoNodeName = "HunterEcho"
    static let filamentMidName = "FilamentMid"
    static let filamentBaseName = "FilamentBase"
    static let filamentTipName = "FilamentTip"

    /// Matches `CompanionVisualConfiguration.liraPlaceholder.groundOffsetMeters`.
    static let defaultGroundOffsetMeters: Float = 0.02
    /// Body local Y above ground in factory (`g + bodyBaseYAboveGround`).
    static let bodyBaseYAboveGround: Float = 0.29
    /// Hunter echo rest Y above ground in factory.
    static let hunterEchoBaseYAboveGround: Float = 0.28

    // MARK: - A2 Core breath

    static func coreBreathScale(elapsed: TimeInterval, state: CompanionPresentationState) -> Float {
        let t = Self.safeElapsed(elapsed)
        let amplitude: Float
        switch state {
        case .celebrate: amplitude = 0.10
        case .alert: amplitude = 0.04
        case .investigate: amplitude = 0.05
        default: amplitude = 0.06
        }
        return 1 + amplitude * sin(Float(t) * 2.2)
    }

    // MARK: - A3 Filament

    static let filamentBasePitch: Float = .pi / 4.2

    static func filamentSwayRadians(elapsed: TimeInterval, state: CompanionPresentationState) -> Float {
        let t = Self.safeElapsed(elapsed)
        let amplitude: Float
        switch state {
        case .alert: amplitude = 0.12
        case .follow: amplitude = 0.09
        case .celebrate: amplitude = 0.07
        default: amplitude = 0.08
        }
        let rate: Float = state == .alert ? 1.8 : 1.4
        return amplitude * sin(Float(t) * rate)
    }

    static func filamentOrientation(elapsed: TimeInterval, state: CompanionPresentationState) -> simd_quatf {
        let pitch = filamentBasePitch + filamentSwayRadians(elapsed: elapsed, state: state)
        let yaw = 0.04 * sin(Float(Self.safeElapsed(elapsed)) * 1.1)
        let qPitch = simd_quatf(angle: pitch, axis: simd_normalize(SIMD3<Float>(1, 0.12, 0)))
        let qYaw = simd_quatf(angle: yaw, axis: [0, 1, 0])
        return qYaw * qPitch
    }

    /// Secondary wave for mid/tip segments (phase-shifted).
    static func filamentSegmentPitch(elapsed: TimeInterval, segmentIndex: Int, state: CompanionPresentationState) -> Float {
        let t = Self.safeElapsed(elapsed)
        let phase = Float(segmentIndex) * 0.85
        let amp: Float = state == .alert ? 0.18 : 0.10
        return amp * sin(Float(t) * 1.7 + phase)
    }

    // MARK: - A1 Head

    static func headAttentionYawRadians(elapsed: TimeInterval, state: CompanionPresentationState) -> Float {
        let t = Self.safeElapsed(elapsed)
        let target: Float
        switch state {
        case .investigate: target = -0.22
        case .follow: target = 0.10
        case .alert: target = 0.06
        case .celebrate: target = 0.14 * sin(Float(t) * 1.6)
        default: target = 0.04 * sin(Float(t) * 0.9)
        }
        let settle = min(1, Float(t) * 2.5)
        return target * settle
    }

    static func headOrientation(elapsed: TimeInterval, state: CompanionPresentationState) -> simd_quatf {
        let yaw = headAttentionYawRadians(elapsed: elapsed, state: state)
        let pitch: Float = state == .investigate ? -0.18 : -0.12
        let qPitch = simd_quatf(angle: pitch, axis: [1, 0, 0])
        let qYaw = simd_quatf(angle: yaw, axis: [0, 1, 0])
        return qYaw * qPitch
    }

    // MARK: - Ears / tail / body idle

    static func earFlutterRadians(elapsed: TimeInterval, isLeft: Bool, state: CompanionPresentationState) -> Float {
        let t = Self.safeElapsed(elapsed)
        let side: Float = isLeft ? 1 : -1
        let amp: Float = state == .alert ? 0.08 : 0.04
        return side * amp * sin(Float(t) * (isLeft ? 2.4 : 2.1))
    }

    static func earOrientation(elapsed: TimeInterval, isLeft: Bool, state: CompanionPresentationState) -> simd_quatf {
        let baseZ: Float = isLeft ? 0.35 : -0.28
        let baseX: Float = isLeft ? -0.15 : -0.12
        let flutter = earFlutterRadians(elapsed: elapsed, isLeft: isLeft, state: state)
        return simd_quatf(angle: baseZ + flutter, axis: [0, 0, 1])
            * simd_quatf(angle: baseX, axis: [1, 0, 0])
    }

    static func tailSwayRadians(elapsed: TimeInterval, state: CompanionPresentationState) -> Float {
        let t = Self.safeElapsed(elapsed)
        let amp: Float = state == .celebrate ? 0.14 : 0.07
        return amp * sin(Float(t) * 1.5)
    }

    static func tailOrientation(elapsed: TimeInterval, state: CompanionPresentationState) -> simd_quatf {
        let base: Float = .pi / 5.5
        let sway = tailSwayRadians(elapsed: elapsed, state: state)
        return simd_quatf(angle: base + sway, axis: [1, 0, 0])
            * simd_quatf(angle: sway * 0.35, axis: [0, 1, 0])
    }

    /// Soft vertical body bob amplitude (meters, added to rest Y).
    static func bodyBobOffsetY(elapsed: TimeInterval, state: CompanionPresentationState) -> Float {
        let t = Self.safeElapsed(elapsed)
        let amp: Float
        switch state {
        case .celebrate: amp = 0.012
        case .alert: amp = 0.004
        default: amp = 0.008
        }
        return amp * sin(Float(t) * 1.9)
    }

    /// Body lean for single-mesh (Meshy) pure-function fallback — identity rest.
    static func staticMeshBodyOrientation(
        elapsed: TimeInterval,
        state: CompanionPresentationState
    ) -> simd_quatf {
        let t = Self.safeElapsed(elapsed)
        let pitch: Float
        let yaw: Float
        switch state {
        case .follow:
            pitch = 0.05 + 0.015 * sin(Float(t) * 1.3)
            yaw = 0.08 + 0.04 * sin(Float(t) * 1.1)
        case .investigate:
            pitch = 0.12 + 0.02 * sin(Float(t) * 1.0)
            yaw = -0.14 + 0.04 * sin(Float(t) * 0.9)
        case .alert:
            pitch = 0.03 + 0.02 * sin(Float(t) * 2.0)
            yaw = 0.04 * sin(Float(t) * 2.2)
        case .celebrate:
            pitch = -0.03
            yaw = 0.12 * sin(Float(t) * 1.6)
        case .idle:
            pitch = 0.01 * sin(Float(t) * 0.9)
            yaw = 0.025 * sin(Float(t) * 0.7)
        }
        let qPitch = simd_quatf(angle: pitch, axis: [1, 0, 0])
        let qYaw = simd_quatf(angle: yaw, axis: [0, 1, 0])
        return qYaw * qPitch
    }

    /// Factory rest Y for Body (includes ground offset).
    static func bodyRestY(groundOffset: Float = defaultGroundOffsetMeters) -> Float {
        groundOffset + bodyBaseYAboveGround
    }

    /// Absolute Body local Y for a frame (rest + bob).
    static func bodyPositionY(
        elapsed: TimeInterval,
        state: CompanionPresentationState,
        groundOffset: Float = defaultGroundOffsetMeters
    ) -> Float {
        bodyRestY(groundOffset: groundOffset) + bodyBobOffsetY(elapsed: elapsed, state: state)
    }

    // MARK: - Root plant ease

    static func rootPlantEase(progress: Float) -> Float {
        let p = min(1, max(0, progress))
        return p * p * (3 - 2 * p)
    }

    // MARK: - Hunter echo

    static func showsHunterEcho(state: CompanionPresentationState) -> Bool {
        state == .alert
    }

    /// Absolute local position for HunterEcho (includes ground offset).
    static func hunterEchoPosition(
        elapsed: TimeInterval,
        groundOffset: Float = defaultGroundOffsetMeters
    ) -> SIMD3<Float> {
        let t = Self.safeElapsed(elapsed)
        let drift = 0.01 * sin(Float(t) * 2.6)
        return SIMD3<Float>(
            0.04 + drift,
            groundOffset + hunterEchoBaseYAboveGround + 0.01 * sin(Float(t) * 1.8),
            -0.08
        )
    }

    /// Backward-compatible alias used by older call sites / tests.
    static func hunterEchoOffset(elapsed: TimeInterval) -> SIMD3<Float> {
        hunterEchoPosition(elapsed: elapsed)
    }

    // MARK: - Spawn coalesce

    static let spawnCoalesceDuration: TimeInterval = 0.70
    static let spawnCoalesceDurationReduced: TimeInterval = 0.12

    static func spawnCoalesceProgress(elapsed: TimeInterval, duration: TimeInterval) -> Float {
        let d = duration > 0 && duration.isFinite ? duration : spawnCoalesceDuration
        let t = Self.safeElapsed(elapsed)
        return min(1, max(0, Float(t / d)))
    }

    static func spawnScaleFactor(progress: Float) -> Float {
        let p = min(1, max(0, progress))
        let e = 1 - pow(1 - p, 3)
        return 0.92 + 0.08 * e
    }

    private static func safeElapsed(_ elapsed: TimeInterval) -> TimeInterval {
        guard elapsed.isFinite, elapsed >= 0 else { return 0 }
        return elapsed
    }
}
