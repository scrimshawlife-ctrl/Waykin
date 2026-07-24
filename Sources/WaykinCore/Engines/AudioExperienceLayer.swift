import Foundation

public protocol AudioAssetResolving {
    func assetAvailability(for cue: AudioCue) -> AudioAssetAvailability
}

public struct EmptyAudioAssetResolver: AudioAssetResolving {
    public init() {}

    public func assetAvailability(for cue: AudioCue) -> AudioAssetAvailability {
        .missing
    }
}

public struct AudioExperienceLayer {
    /// Minimum session elapsed between behavior-transition cues when no world event fires (#130).
    public static let behaviorTransitionCooldown: TimeInterval = 12
    /// Minimum session elapsed between AR presentation-transition cues when event/behavior audio is silent.
    public static let arPresentationTransitionCooldown: TimeInterval = 12

    /// Canonical AR presentation vocabulary (matches `CompanionPresentationMatrix.arBehaviorString`
    /// and App `CompanionPresentationState` raw values). Used only for mapping — no new cue kinds.
    public static let arPresentationVocabulary: Set<String> = [
        "idle", "follow", "investigate", "alert", "celebrate",
    ]

    private var activeCues: [String: AudioCue] = [:]
    private var lastPlayedByCooldownGroup: [String: Date] = [:]
    private let resolver: any AudioAssetResolving
    private let cooldown: TimeInterval

    public init(resolver: (any AudioAssetResolving)? = nil, cooldown: TimeInterval = 18) {
        self.resolver = resolver ?? EmptyAudioAssetResolver()
        self.cooldown = max(0, cooldown)
    }

    public mutating func cue(for event: WorldEvent?, now: Date) -> AudioCue? {
        guard let event else { return nil }

        let cue = Self.map(event: event)
        if let last = lastPlayedByCooldownGroup[cue.cooldownGroup], now.timeIntervalSince(last) < cooldown {
            return nil
        }

        if let existing = activeCues[cue.cooldownGroup], existing.priority > cue.priority {
            return nil
        }

        lastPlayedByCooldownGroup[cue.cooldownGroup] = now
        activeCues[cue.cooldownGroup] = cue
        _ = resolver.assetAvailability(for: cue)
        return cue
    }

    /// Cue for a companion behavior transition when no world-event cue is available (#130).
    /// Returns nil when behavior is unchanged, unmapped, or still in cooldown.
    public static func cueForBehaviorTransition(
        from previousRaw: String?,
        to next: CompanionBehaviorState,
        sessionElapsed: TimeInterval,
        lastBehaviorAudioElapsed: TimeInterval?,
        intensity: Double = 0.45
    ) -> AudioCue? {
        let previous = previousRaw.flatMap(CompanionBehaviorState.init(rawValue:))
        guard previous != next else { return nil }
        // First presentation in a session: seed state without audio (avoid start-of-walk noise).
        guard previous != nil else { return nil }

        if let last = lastBehaviorAudioElapsed,
           sessionElapsed - last < behaviorTransitionCooldown {
            return nil
        }

        return map(behavior: next, intensity: intensity)
    }

    /// Cue when AR presentation vocabulary changes (DCC / `CompanionPresentationState` strings)
    /// and higher-priority event/behavior audio is silent. Uses existing produced cue kinds only.
    /// First presentation seed is silent; cooldown matches behavior transitions.
    public static func cueForARPresentationTransition(
        from previousRaw: String?,
        to nextRaw: String,
        sessionElapsed: TimeInterval,
        lastARPresentationAudioElapsed: TimeInterval?,
        intensity: Double = 0.45
    ) -> AudioCue? {
        let previous = previousRaw.map(normalizedARPresentation)
        let next = normalizedARPresentation(nextRaw)
        guard previous != next else { return nil }
        // First presentation seeds without audio (avoid spawn / session-start noise).
        guard previous != nil else { return nil }

        if let last = lastARPresentationAudioElapsed,
           sessionElapsed - last < arPresentationTransitionCooldown {
            return nil
        }

        return map(arPresentation: next, intensity: intensity)
    }

    public mutating func endSession() {
        activeCues.removeAll()
        lastPlayedByCooldownGroup.removeAll()
    }

    public var activeCueCount: Int {
        activeCues.count
    }

    public static func map(event: WorldEvent) -> AudioCue {
        switch event.kind {
        case .companionDrawsNear:
            return AudioCue(kind: .companionNear, intensity: event.intensity, spatialBias: .left, priority: 2, cooldownGroup: "companion", shouldFade: true, debugLabel: event.debugLabel)
        case .companionMovesAhead:
            return AudioCue(kind: .companionAhead, intensity: event.intensity, spatialBias: .center, priority: 2, cooldownGroup: "companion", shouldFade: true, debugLabel: event.debugLabel)
        case .distantPresence, .pursuitBegins:
            return AudioCue(kind: .distantFootsteps, intensity: event.intensity, spatialBias: .behind, priority: 3, cooldownGroup: "pursuit", shouldFade: false, debugLabel: event.debugLabel)
        case .pursuitIntensifies:
            return AudioCue(kind: .pursuitPressure, intensity: event.intensity, spatialBias: .behind, priority: 4, cooldownGroup: "pursuit", shouldFade: false, debugLabel: event.debugLabel)
        case .pursuitFades:
            return AudioCue(kind: .pursuitRelease, intensity: event.intensity, spatialBias: .behind, priority: 3, cooldownGroup: "pursuit", shouldFade: true, debugLabel: event.debugLabel)
        case .bondMoment:
            return AudioCue(kind: .bondMotif, intensity: event.intensity, spatialBias: .center, priority: 5, cooldownGroup: "bond", shouldFade: true, debugLabel: event.debugLabel)
        case .companionObserves, .familiarPlaceStirs, .quietInterval:
            return AudioCue(kind: .quietShift, intensity: event.intensity, spatialBias: .center, priority: 1, cooldownGroup: "ambient", shouldFade: true, debugLabel: event.debugLabel)
        }
    }

    /// Map companion-visible behavior changes onto existing produced cue kinds (no new kinds).
    public static func map(behavior: CompanionBehaviorState, intensity: Double = 0.45) -> AudioCue? {
        let label = "behavior:\(behavior.rawValue)"
        switch behavior {
        case .drawNear:
            return AudioCue(
                kind: .companionNear,
                intensity: intensity,
                spatialBias: .left,
                priority: 2,
                cooldownGroup: "companion",
                shouldFade: true,
                debugLabel: label
            )
        case .lead:
            return AudioCue(
                kind: .companionAhead,
                intensity: intensity,
                spatialBias: .center,
                priority: 2,
                cooldownGroup: "companion",
                shouldFade: true,
                debugLabel: label
            )
        case .rest, .observe:
            return AudioCue(
                kind: .quietShift,
                intensity: min(intensity, 0.4),
                spatialBias: .center,
                priority: 1,
                cooldownGroup: "ambient",
                shouldFade: true,
                debugLabel: label
            )
        case .celebrate:
            return AudioCue(
                kind: .bondMotif,
                intensity: intensity,
                spatialBias: .center,
                priority: 5,
                cooldownGroup: "bond",
                shouldFade: true,
                debugLabel: label
            )
        case .follow, .idle:
            // Follow/idle are high-frequency motion defaults — no dedicated cue.
            return nil
        }
    }

    /// Map AR presentation vocabulary onto existing produced cue kinds (no new kinds / assets).
    /// Continuous skeletal loops, filament bob, and gait remain unmapped — transitions only.
    public static func map(arPresentation raw: String, intensity: Double = 0.45) -> AudioCue? {
        let key = normalizedARPresentation(raw)
        let label = "arPresentation:\(key)"
        switch key {
        case "celebrate":
            return AudioCue(
                kind: .bondMotif,
                intensity: intensity,
                spatialBias: .center,
                priority: 5,
                cooldownGroup: "bond",
                shouldFade: true,
                debugLabel: label
            )
        case "alert":
            return AudioCue(
                kind: .pursuitPressure,
                intensity: min(intensity, 0.7),
                spatialBias: .behind,
                priority: 4,
                cooldownGroup: "pursuit",
                shouldFade: false,
                debugLabel: label
            )
        case "investigate":
            return AudioCue(
                kind: .quietShift,
                intensity: min(intensity, 0.4),
                spatialBias: .center,
                priority: 1,
                cooldownGroup: "ambient",
                shouldFade: true,
                debugLabel: label
            )
        case "follow", "idle":
            // High-frequency AR defaults (DCC follow/idle loops) — no transition cue.
            return nil
        default:
            return nil
        }
    }

    private static func normalizedARPresentation(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
