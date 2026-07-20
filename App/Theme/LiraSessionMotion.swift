import CoreGraphics
import Foundation

/// Session-mid motion timings for Lira stills (indoor UX polish).
/// Pure functions for unit tests — no SwiftUI dependency.
enum LiraSessionMotion {
    /// Pose/skin still crossfade duration in seconds.
    /// Reduce Motion: short cut-fade (≤80ms). Normal: ~220ms ease.
    static func poseCrossfadeDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.08 : 0.22
    }

    /// Crossfade duration for a specific incoming pose (manifesting is longer coalesce).
    static func poseCrossfadeDuration(
        reduceMotion: Bool,
        incomingPose: LiraSessionPose
    ) -> TimeInterval {
        if incomingPose == .manifesting {
            return manifestingFadeDuration(reduceMotion: reduceMotion)
        }
        return poseCrossfadeDuration(reduceMotion: reduceMotion)
    }

    /// Manifesting coalesce fade (plan S_manifest: 700ms / ≤120ms RM).
    static func manifestingFadeDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.12 : 0.70
    }

    /// Starting scale for manifesting settle (eases to 1.0).
    static let manifestingStartScale: CGFloat = 0.92

    /// Whether idle scale pulse is allowed.
    static func allowsIdlePulse(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }

    /// Soft pulse half-cycle duration when allowed.
    static func idlePulseDuration(reduceMotion: Bool) -> TimeInterval? {
        allowsIdlePulse(reduceMotion: reduceMotion) ? 0.35 : nil
    }

    // MARK: - Bond orbit (S_bond_orbit)

    /// Continuous orbit period when bond pose is active; nil = static under Reduce Motion.
    static func bondOrbitPeriod(reduceMotion: Bool) -> TimeInterval? {
        reduceMotion ? nil : 1.2
    }

    /// Rest angle for guide/other poses (degrees).
    static let bondOrbitRestDegrees: Double = -40

    /// Bond pose orbit base angle (degrees) before spin.
    static let bondOrbitBondBaseDegrees: Double = -10

    /// Trim range for bond (fuller arc) vs guide.
    static func bondOrbitTrim(pose: LiraSessionPose) -> (from: CGFloat, to: CGFloat) {
        if pose == .bond { return (0.02, 0.92) }
        return (0.08, 0.82)
    }

    static func bondOrbitLineWidth(pose: LiraSessionPose) -> CGFloat {
        pose == .bond ? 6 : 5
    }

    // MARK: - Hunter echo (A3)

    /// Delayed echo opacity for hunter pressure (geometry/asymmetry — not gore).
    static func hunterEchoOpacity(reduceMotion: Bool) -> Double {
        reduceMotion ? 0.18 : 0.28
    }

    /// Echo offset in still points (behind and slightly up — pressure “behind”).
    static func hunterEchoOffset(reduceMotion: Bool) -> CGSize {
        reduceMotion ? CGSize(width: 10, height: 6) : CGSize(width: 14, height: 8)
    }

    static func showsHunterEcho(pose: LiraSessionPose) -> Bool {
        pose.showsEchoSilhouette
    }

    // MARK: - Core pulse / filament drift (still presentation)

    /// A2 soft pulse period for bond/guide stills when motion allowed.
    static func corePulsePeriod(reduceMotion: Bool) -> TimeInterval? {
        reduceMotion ? nil : 1.6
    }

    /// Filament drift period (guide/follow language on still + orbit).
    static func filamentDriftPeriod(reduceMotion: Bool) -> TimeInterval? {
        reduceMotion ? nil : 2.4
    }

    /// Horizontal still offset (points) for subtle filament-side drift at progress 0…1.
    static func filamentDriftOffsetX(progress: Double, reduceMotion: Bool) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let p = progress.isFinite ? progress : 0
        return CGFloat(2.5 * sin(p * .pi * 2))
    }

    /// Vertical micro-bob (points) for guide/sanctuary language.
    static func filamentDriftOffsetY(progress: Double, reduceMotion: Bool) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let p = progress.isFinite ? progress : 0
        return CGFloat(1.2 * sin(p * .pi * 2 + 0.6))
    }

    /// Ambient still motion (drift + soft pulse) for guide/bond/sanctuary/hunter language.
    static func allowsAmbientStillMotion(pose: LiraSessionPose, reduceMotion: Bool) -> Bool {
        guard !reduceMotion else { return false }
        switch pose {
        case .dormant: return false
        case .guide, .bond, .sanctuary, .manifesting, .hunter, .rival: return true
        }
    }

    /// Drift cycle progress 0…1 at wall date (deterministic for a given date).
    static func filamentDriftProgress(at date: Date, reduceMotion: Bool) -> Double {
        guard let period = filamentDriftPeriod(reduceMotion: reduceMotion), period > 0 else { return 0 }
        let t = date.timeIntervalSinceReferenceDate
        let r = t.truncatingRemainder(dividingBy: period)
        return max(0, min(1, r / period))
    }

    /// Soft continuous pulse scale factor (1…~1.025) for still ambient.
    static func ambientPulseScale(at date: Date, pose: LiraSessionPose, reduceMotion: Bool) -> CGFloat {
        guard allowsAmbientStillMotion(pose: pose, reduceMotion: reduceMotion),
              let period = corePulsePeriod(reduceMotion: reduceMotion), period > 0 else {
            return 1
        }
        let t = date.timeIntervalSinceReferenceDate
        let r = t.truncatingRemainder(dividingBy: period) / period
        let amp: CGFloat
        switch pose {
        case .bond: amp = 0.028
        case .guide, .manifesting: amp = 0.02
        case .hunter, .rival: amp = 0.012
        case .sanctuary: amp = 0.015
        case .dormant: amp = 0
        }
        return 1 + amp * CGFloat(sin(r * .pi * 2))
    }

    // MARK: - Route polyline reveal (#157)

    /// Draw-on duration for planned walking route polyline.
    static func routeRevealDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.12 : 0.85
    }

    /// Count of polyline points to show for progress 0…1 (always ≥2 when ready and progress>0).
    static func routeRevealPointCount(total: Int, progress: Double) -> Int {
        guard total >= 2 else { return 0 }
        let p = progress.isFinite ? min(1, max(0, progress)) : 0
        if p <= 0 { return 0 }
        if p >= 1 { return total }
        let count = Int((Double(total - 1) * p).rounded(.up)) + 1
        return min(total, max(2, count))
    }
}
