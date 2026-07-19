import Foundation
import simd

/// Deterministic local AR motion for Living Familiar mid-LOD (animation plan A2).
/// Pure functions — drive CoreGlow breath and Filament sway from elapsed time.
enum LiraARMotion {
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

    private static func safeElapsed(_ elapsed: TimeInterval) -> TimeInterval {
        guard elapsed.isFinite, elapsed >= 0 else { return 0 }
        return elapsed
    }
}
