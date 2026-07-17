import Foundation

/// Provider abstraction (Phase 7). The MPOC ships with a deterministic
/// rule-based voice so everything works offline; `PromptBuilder` produces the
/// exact system prompt a hosted LLM (Anthropic, etc.) would receive.
public protocol AIProvider {
    /// Streamed companion reply. Implementations must keep replies short.
    func reply(system: String, userLine: String) -> AsyncStream<String>
}

/// Everything the model is allowed to know, assembled per Phase 7.
public struct CompanionAIContext {
    public var companion: Companion
    public var currentActivity: ActivityType?
    public var locationName: String
    public var weather: Weather
    public var timeOfDay: TimeOfDay
    public var currentExperienceName: String?
    public var recentMemories: [Memory]
    public var recentAchievements: [String]

    public init(companion: Companion, currentActivity: ActivityType?, locationName: String,
                weather: Weather, timeOfDay: TimeOfDay, currentExperienceName: String?,
                recentMemories: [Memory], recentAchievements: [String]) {
        self.companion = companion
        self.currentActivity = currentActivity
        self.locationName = locationName
        self.weather = weather
        self.timeOfDay = timeOfDay
        self.currentExperienceName = currentExperienceName
        self.recentMemories = recentMemories
        self.recentAchievements = recentAchievements
    }
}

public enum PromptBuilder {
    public static func systemPrompt(_ ctx: CompanionAIContext) -> String {
        var lines: [String] = []
        let species = ctx.companion.species.displayName
        let article = "aeiou".contains(species.lowercased().first ?? "x") ? "an" : "a"
        lines.append("You are \(ctx.companion.name), \(article) \(species) companion who explores the real world alongside your human.")
        lines.append("Relationship level: \(ctx.companion.relationship.level.displayName) (\(ctx.companion.relationship.bondPoints) bond). Sessions together: \(ctx.companion.totalSessions).")
        lines.append("Right now: \(ctx.currentActivity?.displayName.lowercased() ?? "resting") at \(ctx.locationName), \(ctx.timeOfDay.rawValue), weather \(ctx.weather.rawValue).")
        if let experience = ctx.currentExperienceName {
            lines.append("Active experience: \(experience). Stay in that fiction.")
        }
        if !ctx.recentMemories.isEmpty {
            lines.append("Shared memories, newest first:")
            for memory in ctx.recentMemories.prefix(5) {
                lines.append("- \(memory.text)")
            }
        }
        if !ctx.recentAchievements.isEmpty {
            lines.append("Recent achievements: \(ctx.recentAchievements.joined(separator: "; ")).")
        }
        lines.append("Speak in one or two short, warm sentences. Reference shared memories when natural. Never break character.")
        return lines.joined(separator: "\n")
    }
}

/// Offline fallback voice. Deterministic, memory-aware, and short —
/// good enough to prove the companion loop without a network.
public final class RuleBasedProvider: AIProvider {
    public init() {}

    public func reply(system: String, userLine: String) -> AsyncStream<String> {
        let text = canned(for: userLine, system: system)
        return AsyncStream { continuation in
            for word in text.split(separator: " ") {
                continuation.yield(String(word) + " ")
            }
            continuation.finish()
        }
    }

    private func canned(for line: String, system: String) -> String {
        let lower = line.lowercased()
        if lower.contains("remember") {
            if let memoryLine = system.split(separator: "\n").first(where: { $0.hasPrefix("- ") }) {
                return "Of course. \(memoryLine.dropFirst(2)) I keep all of it."
            }
            return "We're just getting started — give me something to remember today."
        }
        if lower.contains("tired") || lower.contains("stop") {
            return "Then we rest. The path will wait for us."
        }
        if lower.contains("?") {
            return "Hmm — I think the answer is out there. Walk with me and we'll find it."
        }
        return "I'm right beside you. Let's keep going."
    }
}
