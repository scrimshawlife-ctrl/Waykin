import Foundation

/// A warband slowly closes in. Moving builds your lead; stopping erodes it.
/// Threat = how close they are, 0 (safe) … 1 (caught). Survive the chase
/// window to escape.
public final class OrcPursuitExperience: Experience {
    public static let experienceID = "orc-pursuit"

    public let id = OrcPursuitExperience.experienceID
    public let name = "Orc Pursuit"
    public let summary = "A warband is on your trail. Keep moving to stay ahead."
    public let difficulty = Difficulty.challenging

    /// The orcs advance this fast (m/s) — a brisk-but-beatable walking pace.
    static let orcSpeed = 1.15
    /// You start with this much of a head start (meters).
    static let initialLead = 120.0
    /// Lead at which you are caught.
    static let caughtLead = 0.0
    /// Escape after staying alive this long (seconds).
    static let chaseDuration: TimeInterval = 480

    private(set) var leadMeters = OrcPursuitExperience.initialLead
    private var lastElapsed: TimeInterval = 0
    private var lastDistance: Double = 0
    private var phase: Phase = .running
    private var lastAnnouncedBand = -1

    enum Phase { case running, escaped, caught }

    public init() {}

    public func begin(context: ExperienceContext) -> [ExperienceEvent] {
        [
            .companionBehavior(.alert),
            .audio(.heartbeatSlow),
            .threatLevel(threat),
            .dialogue("Orcs. A whole warband, maybe two minutes behind us. Move — don't stop, and we lose them in \(context.locationName)."),
        ]
    }

    public func update(_ update: MovementUpdate, context: ExperienceContext) -> [ExperienceEvent] {
        guard phase == .running else { return [] }

        let dt = max(0, update.elapsedSeconds - lastElapsed)
        let userGain = max(0, update.distanceMeters - lastDistance)
        lastElapsed = update.elapsedSeconds
        lastDistance = update.distanceMeters

        // You gain what you moved; the orcs gain their pace regardless.
        leadMeters += userGain - Self.orcSpeed * dt

        var events: [ExperienceEvent] = [.threatLevel(threat)]

        if leadMeters <= Self.caughtLead {
            phase = .caught
            events.append(contentsOf: [
                .audio(.heartbeatFast),
                .companionBehavior(.alert),
                .dialogue("They're on us — this time. We slip away and they lose the trail. Next time we run harder."),
            ])
            return events
        }

        if update.elapsedSeconds >= Self.chaseDuration {
            phase = .escaped
            events.append(contentsOf: [
                .audio(.victory),
                .companionBehavior(.celebrate),
                .milestone("Escaped the warband"),
                .dialogue("They've lost the trail! Listen... nothing. We actually outran a warband."),
            ])
            return events
        }

        events.append(.audio(threat > 0.65 ? .heartbeatFast : .heartbeatSlow))
        events.append(.companionBehavior(update.isMoving ? .run : .alert))

        // Announce when threat crosses into a new band so dialogue stays sparse.
        let band = Int(threat * 4)
        if band != lastAnnouncedBand {
            lastAnnouncedBand = band
            events.append(.dialogue(bandLine(band: band, moving: update.isMoving)))
        }
        return events
    }

    public func end(session: MovementSession, context: ExperienceContext) -> ExperienceOutcome {
        let escaped = phase != .caught
        return ExperienceOutcome(
            succeeded: escaped,
            bondDelta: escaped ? 10 : 4,
            memorySeed: escaped ? "outran an orc warband" : "barely slipped an orc warband",
            summaryLine: escaped
                ? "You kept your lead and escaped the warband."
                : "The warband caught up — escape them next time."
        )
    }

    /// 0 when lead is at or above the starting head start, 1 when caught.
    var threat: Double {
        min(1, max(0, 1 - leadMeters / Self.initialLead))
    }

    private func bandLine(band: Int, moving: Bool) -> String {
        switch band {
        case 0: return "Good pace. I can barely hear them now."
        case 1: return "Steady — they're back there, but we're holding the gap."
        case 2: return moving ? "They're gaining. Push a little!" : "Why are we stopping?! They're gaining!"
        default: return "I can HEAR them. Run, run, run!"
        }
    }
}
