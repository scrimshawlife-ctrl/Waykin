import Foundation

/// A ghost of you moves at a target pace slightly better than your recent
/// average, staying ahead. Match its pace to close the gap; catch it by
/// session's end to win.
public final class FutureSelfExperience: Experience {
    public static let experienceID = "future-self"

    public let id = FutureSelfExperience.experienceID
    public let name = "Future Self"
    public let summary = "A ghost of a slightly better you stays ahead. Catch it."
    public let difficulty = Difficulty.moderate

    /// Ghost starts this far ahead.
    static let initialGap = 40.0
    /// Ghost pace multiplier vs. the target baseline: 5% better than you.
    static let challengeFactor = 1.05

    /// Baseline speed (m/s) the ghost improves upon. Defaults to a casual
    /// walk; the app passes the user's historical average in.
    let baselineSpeed: Double
    private var ghostDistance: Double = FutureSelfExperience.initialGap
    private var userDistance: Double = 0
    private var lastElapsed: TimeInterval = 0
    private var caught = false
    private var lastEncouragement: TimeInterval = 0

    public init(baselineSpeed: Double = 1.25) {
        self.baselineSpeed = baselineSpeed
    }

    public func begin(context: ExperienceContext) -> [ExperienceEvent] {
        [
            .companionBehavior(.follow),
            .audio(.ghostWhoosh),
            .ghostDistance(gap),
            .dialogue("See that shimmer ahead? That's you — tomorrow's you, moving just a little stronger. Think we can catch them?"),
        ]
    }

    public func update(_ update: MovementUpdate, context: ExperienceContext) -> [ExperienceEvent] {
        guard !caught else { return [] }

        let dt = max(0, update.elapsedSeconds - lastElapsed)
        lastElapsed = update.elapsedSeconds
        userDistance = update.distanceMeters
        // Adaptive pace: the ghost tracks 5% above baseline, but slows a touch
        // when you fall far behind so it never becomes hopeless.
        let hopelesslyBehind = gap > 3 * Self.initialGap
        let ghostSpeed = baselineSpeed * Self.challengeFactor * (hopelesslyBehind ? 0.9 : 1.0)
        ghostDistance += ghostSpeed * dt

        var events: [ExperienceEvent] = [.ghostDistance(gap)]

        if gap <= 0 {
            caught = true
            events.append(contentsOf: [
                .audio(.victory),
                .companionBehavior(.celebrate),
                .milestone("Caught your future self"),
                .dialogue("You caught them! Or... you became them. Either way — that pace is yours now."),
            ])
            return events
        }

        events.append(.companionBehavior(update.isMoving ? (update.detectedActivity == .running ? .run : .walk) : .idle))

        // Encourage at most every 90 seconds, tone based on the gap trend.
        if update.elapsedSeconds - lastEncouragement >= 90 {
            lastEncouragement = update.elapsedSeconds
            events.append(.dialogue(encouragement(update: update)))
        }
        return events
    }

    public func end(session: MovementSession, context: ExperienceContext) -> ExperienceOutcome {
        ExperienceOutcome(
            succeeded: caught,
            bondDelta: caught ? 8 : 5,
            memorySeed: caught ? "caught your future self" : "chased your future self",
            summaryLine: caught
                ? "You closed the gap and caught your future self."
                : String(format: "The ghost finished %.0f m ahead — closer every day.", max(0, gap))
        )
    }

    /// Meters the ghost is ahead. Negative once you pass it.
    var gap: Double { ghostDistance - userDistance }

    private func encouragement(update: MovementUpdate) -> String {
        if !update.isMoving {
            return "The ghost doesn't take breaks... but it also doesn't get to enjoy the view. Ready when you are."
        }
        switch gap {
        case ..<15: return "They're RIGHT there — I can see the shimmer! Surge!"
        case ..<40: return "Gap's closing. Keep exactly this rhythm."
        default: return "They're ahead, but they're only 5% better than yesterday's you. You have this."
        }
    }
}
