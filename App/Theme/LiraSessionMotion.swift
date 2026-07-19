import CoreGraphics
import Foundation

/// Session-mid motion timings for Lira stills (animation plan A1–A3).
/// Pure functions for unit tests — no SwiftUI dependency.
enum LiraSessionMotion {
    /// Pose/skin still crossfade duration in seconds.
    /// Reduce Motion: short cut-fade (≤80ms). Normal: ~220ms ease.
    static func poseCrossfadeDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.08 : 0.22
    }

    /// Whether idle scale pulse is allowed.
    static func allowsIdlePulse(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }

    /// Soft pulse half-cycle duration when allowed.
    static func idlePulseDuration(reduceMotion: Bool) -> TimeInterval? {
        allowsIdlePulse(reduceMotion: reduceMotion) ? 0.35 : nil
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
}
