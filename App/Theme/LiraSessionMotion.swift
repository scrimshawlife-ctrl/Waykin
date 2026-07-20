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
}
