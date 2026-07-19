import Foundation

/// Session-mid motion timings for Lira stills (animation plan A1).
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
}
