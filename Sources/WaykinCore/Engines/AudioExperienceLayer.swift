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

    /// One-shot lifecycle "moment" cues, fired at app-lifecycle points rather
    /// than derived from the walk (launch, onboarding companion reveal, spawn,
    /// bond milestone). Every moment states the Lira leitmotif — spawn and
    /// launch are the full theme. These are top-priority foreground one-shots
    /// (above the loudest walk cue, `bondMotif` = 5) so a moment always wins the
    /// foreground channel; the *caller* is responsible for firing each once per
    /// moment (there is no transition cooldown here). See
    /// `docs/design/LIRA_AUDIO_CUE_FAMILY.md`.
    public enum Moment: String, Sendable, CaseIterable {
        case appLaunch
        case companionReveal
        case spawn
        case bondMilestone
    }

    public static func momentCue(_ moment: Moment, intensity: Double = 0.9) -> AudioCue {
        let kind: AudioCueKind
        switch moment {
        case .appLaunch: kind = .appLaunchTheme
        case .companionReveal: kind = .companionReveal
        case .spawn: kind = .spawnTheme
        case .bondMilestone: kind = .bondMilestone
        }
        return AudioCue(
            kind: kind,
            intensity: intensity,
            spatialBias: .center,
            priority: 6,
            cooldownGroup: "moment",
            shouldFade: true,
            debugLabel: "moment:\(moment.rawValue)"
        )
    }
}
