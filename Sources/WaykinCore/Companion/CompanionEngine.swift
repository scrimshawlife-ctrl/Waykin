import Foundation

/// The companion's mind between sessions: greetings that evolve with the
/// relationship, place recognition, and bond bookkeeping.
public final class CompanionEngine {
    public private(set) var companion: Companion
    private let memoryEngine: MemoryEngine

    public init(companion: Companion, memoryEngine: MemoryEngine) {
        self.companion = companion
        self.memoryEngine = memoryEngine
    }

    /// Greeting shown when the app opens. Changes with bond level, session
    /// count, and what the companion remembers.
    public func greeting(now: Date) -> String {
        let name = companion.name
        let level = companion.relationship.level

        guard companion.totalSessions > 0 else {
            return "Hi! I'm \(name). I've never seen this world before — take me somewhere?"
        }

        var lines: [String] = []
        if let last = memoryEngine.mostRecentMemory() {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day],
                                               from: calendar.startOfDay(for: last.date),
                                               to: calendar.startOfDay(for: now)).day ?? 0
            switch days {
            case 0: lines.append("Back already? I was still thinking about \(last.locationName).")
            case 1: lines.append("I kept yesterday safe: \(last.text)")
            case 2...6: lines.append("It's been \(days) days! I've been replaying our \(last.experienceName.lowercased()) at \(last.locationName).")
            default: lines.append("It's been a while... I never forgot \(last.locationName), though.")
            }
        }

        switch level {
        case .stranger: lines.append("Where to today?")
        case .acquaintance: lines.append("I was hoping you'd show up. Where to?")
        case .friend: lines.append("Ready when you are, friend.")
        case .companion: lines.append("Every walk with you makes my world bigger.")
        case .soulbound: lines.append("You and me. Always. Let's go.")
        }
        return lines.joined(separator: " ")
    }

    /// What the companion says on arriving somewhere — recognition is the
    /// heart of Pillar 5.
    public func arrivalLine(locationName: String) -> String {
        guard let place = memoryEngine.locationMemory(named: locationName) else {
            return "A brand new place! I'm memorizing everything."
        }
        if place.isFavorite {
            return "\(locationName)! Our place. Visit number \(place.visitCount + 1) — I love it here."
        }
        return "I remember this place. \(locationName), right? We've been here before."
    }

    /// Apply a finished session: bond, counters, and a generated memory.
    @discardableResult
    public func completeSession(_ session: MovementSession,
                                outcome: ExperienceOutcome,
                                experienceID: String,
                                experienceName: String,
                                locationName: String) -> Memory {
        companion.totalSessions += 1
        companion.totalDistanceMeters += session.distanceMeters
        companion.relationship.bondPoints += outcome.bondDelta

        return memoryEngine.recordSession(
            session,
            outcome: outcome,
            experienceID: experienceID,
            experienceName: experienceName,
            locationName: locationName,
            companionName: companion.name
        )
    }
}
