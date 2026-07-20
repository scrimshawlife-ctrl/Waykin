import Foundation

/// Soft audio when semantic path relation changes (#140).
/// Uses existing produced `AudioCueKind` only — never selects world events or Bond.
public enum PathAudioCoupling {
    public static let cooldownSeconds: TimeInterval = 14

    /// Cue for a path-relation transition, or nil when suppressed.
    public static func cue(
        from previous: PathRelation,
        to next: PathRelation,
        pursuitState: PursuitState,
        sessionElapsed: TimeInterval = 0,
        lastPathAudioElapsed: TimeInterval? = nil
    ) -> AudioCue? {
        guard previous != next else { return nil }
        // Do not compete with active pursuit drama.
        guard pursuitState == .inactive || pursuitState == .fading else { return nil }

        if let last = lastPathAudioElapsed, sessionElapsed - last < cooldownSeconds {
            return nil
        }

        switch next {
        case .strained:
            return AudioCue(
                kind: .quietShift,
                intensity: 0.35,
                spatialBias: .center,
                priority: 1,
                cooldownGroup: "path",
                shouldFade: true,
                debugLabel: "path:strained"
            )
        case .offPath:
            return AudioCue(
                kind: .quietShift,
                intensity: 0.5,
                spatialBias: .behind,
                priority: 1,
                cooldownGroup: "path",
                shouldFade: true,
                debugLabel: "path:offPath"
            )
        case .recovered:
            return AudioCue(
                kind: .pursuitRelease,
                intensity: 0.4,
                spatialBias: .center,
                priority: 2,
                cooldownGroup: "path",
                shouldFade: true,
                debugLabel: "path:recovered"
            )
        case .establishing, .onPath:
            return nil
        }
    }
}
