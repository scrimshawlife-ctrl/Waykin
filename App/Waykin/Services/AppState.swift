import Foundation
import SwiftData
import Observation
import WaykinCore

/// Session-wide wiring: loads the companion, owns the engines, persists
/// results. Views only talk to this.
@Observable
final class AppState {
    private let context: ModelContext
    private var storedCompanion: StoredCompanion?

    let experiences = ExperienceEngine.standard()
    private(set) var memoryEngine: MemoryEngine!
    private(set) var companionEngine: CompanionEngine?
    private(set) var recommendationEngine: RecommendationEngine!

    /// Set when a session finishes; drives the summary sheet.
    var lastSummary: SessionSummary?

    init(context: ModelContext) {
        self.context = context
        if ProcessInfo.processInfo.arguments.contains("--demo-reset") {
            try? context.delete(model: StoredCompanion.self)
            try? context.delete(model: StoredMemory.self)
            try? context.delete(model: StoredLocationMemory.self)
            try? context.save()
        }
        let store = SwiftDataMemoryStore(context: context)
        memoryEngine = MemoryEngine(store: store)
        recommendationEngine = RecommendationEngine(experiences: experiences, memoryEngine: memoryEngine)

        if let stored = try? context.fetch(FetchDescriptor<StoredCompanion>()).first {
            storedCompanion = stored
            companionEngine = CompanionEngine(companion: stored.asCompanion, memoryEngine: memoryEngine)
        } else if ProcessInfo.processInfo.arguments.contains("--demo-seed") {
            seedDemo()
        }
    }

    /// Dev/demo shortcut: launch with `--demo-seed` to skip onboarding and
    /// land on Day 2 — a companion who already remembers yesterday's walk.
    private func seedDemo() {
        createCompanion(name: "Ember", species: .emberfox)
        guard let engine = companionEngine else { return }
        let yesterdayEvening = Calendar.current.date(
            bySettingHour: 18, minute: 40, second: 0,
            of: Date().addingTimeInterval(-86_400)) ?? Date().addingTimeInterval(-86_400)
        let session = MovementSession(activity: .walking,
                                      startedAt: yesterdayEvening.addingTimeInterval(-600),
                                      endedAt: yesterdayEvening,
                                      distanceMeters: 903, route: [])
        let outcome = ExperienceOutcome(succeeded: true, bondDelta: 8,
                                        memorySeed: "caught your future self",
                                        summaryLine: "You closed the gap and caught your future self.")
        _ = engine.completeSession(session, outcome: outcome,
                                   experienceID: FutureSelfExperience.experienceID,
                                   experienceName: "Future Self",
                                   locationName: "Shoreline Park")
        storedCompanion?.apply(engine.companion)
        try? context.save()
    }

    func createCompanion(name: String, species: Companion.Species) {
        let companion = Companion(name: name, species: species, createdAt: Date())
        let stored = StoredCompanion(companion)
        context.insert(stored)
        try? context.save()
        storedCompanion = stored
        companionEngine = CompanionEngine(companion: companion, memoryEngine: memoryEngine)
    }

    @discardableResult
    func completeSession(_ session: MovementSession,
                         outcome: ExperienceOutcome,
                         registration: ExperienceEngine.Registration,
                         locationName: String) -> SessionSummary? {
        guard let engine = companionEngine else { return nil }
        let levelBefore = engine.companion.relationship.level
        let memory = engine.completeSession(session, outcome: outcome,
                                            experienceID: registration.id,
                                            experienceName: registration.name,
                                            locationName: locationName)
        storedCompanion?.apply(engine.companion)
        try? context.save()
        let summary = SessionSummary(session: session, outcome: outcome,
                                     memory: memory,
                                     levelBefore: levelBefore,
                                     levelAfter: engine.companion.relationship.level)
        lastSummary = summary
        return summary
    }

    /// Where the app writes field-test receipts (one JSON per session).
    static var receiptStore: FileReceiptStore {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return FileReceiptStore(directory: documents.appendingPathComponent("Receipts"))
    }

    func recommendations() -> [Recommendation] {
        let hour = Calendar.current.component(.hour, from: Date())
        return recommendationEngine.recommend(
            .init(timeOfDay: .from(hour: hour), weather: .clear, availableMinutes: 30))
    }
}

struct SessionSummary: Identifiable {
    let id = UUID()
    let session: MovementSession
    let outcome: ExperienceOutcome
    let memory: Memory
    let levelBefore: Relationship.Level
    let levelAfter: Relationship.Level
}
