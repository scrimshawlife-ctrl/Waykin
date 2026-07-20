import Foundation
import simd

/// Deterministic local AR motion for Living Familiar mid-LOD (animation plan A2–A4).
/// Pure functions — breath, sway, hunter echo, spawn coalesce.
enum LiraARMotion {
    static let hunterEchoNodeName = "HunterEcho"

    /// A2 chest ember scale multiplier (1 = rest).
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

    /// A3 filament pitch offset radians around a base trail angle.
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

    /// Base filament trail pitch (matches procedural factory lean).
    static let filamentBasePitch: Float = .pi / 4.2

    static func filamentOrientation(elapsed: TimeInterval, state: CompanionPresentationState) -> simd_quatf {
        let pitch = filamentBasePitch + filamentSwayRadians(elapsed: elapsed, state: state)
        let axis = simd_normalize(SIMD3<Float>(1, 0.12, 0))
        return simd_quatf(angle: pitch, axis: axis)
    }

    // MARK: - Head attention (A1)

    /// Soft head yaw toward investigate / follow spatial intent (radians, Y-up).
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
        // Ease toward target with a gentle settle (deterministic from elapsed only).
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

    // MARK: - Root ease (presentation plant blend)

    /// 0…1 ease for root plant transitions (200ms nominal when deltaElapsed known).
    static func rootPlantEase(progress: Float) -> Float {
        let p = min(1, max(0, progress))
        return p * p * (3 - 2 * p)
    }

    // MARK: - Hunter echo (A3)

    static func showsHunterEcho(state: CompanionPresentationState) -> Bool {
        state == .alert
    }

    /// Local offset for delayed pressure ghost (behind, slight up).
    static func hunterEchoOffset(elapsed: TimeInterval) -> SIMD3<Float> {
        let t = Self.safeElapsed(elapsed)
        let drift = 0.01 * sin(Float(t) * 2.6)
        return SIMD3<Float>(0.04 + drift, 0.02, -0.08)
    }

    // MARK: - Spawn coalesce (A4)

    /// Duration for spawn scale settle (normal / reduce-motion callers choose).
    static let spawnCoalesceDuration: TimeInterval = 0.70
    static let spawnCoalesceDurationReduced: TimeInterval = 0.12

    /// 0…1 progress from elapsed and duration.
    static func spawnCoalesceProgress(elapsed: TimeInterval, duration: TimeInterval) -> Float {
        let d = duration > 0 && duration.isFinite ? duration : spawnCoalesceDuration
        let t = Self.safeElapsed(elapsed)
        return min(1, max(0, Float(t / d)))
    }

    /// Multiplies root presentation scale during coalesce (0.92 → 1.0).
    static func spawnScaleFactor(progress: Float) -> Float {
        let p = min(1, max(0, progress))
        // Ease-out cubic
        let e = 1 - pow(1 - p, 3)
        return 0.92 + 0.08 * e
    }

    private static func safeElapsed(_ elapsed: TimeInterval) -> TimeInterval {
        guard elapsed.isFinite, elapsed >= 0 else { return 0 }
        return elapsed
    }
}
