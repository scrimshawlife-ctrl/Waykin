import Foundation
import WaykinCore

// waykin-sim — plays the MPOC demonstration scenario end-to-end on macOS,
// no device required: Day 1 create a companion, walk 10 minutes of
// "Future Self" at Shoreline Park; Day 2 reopen the app and be remembered.
//
// Usage: swift run waykin-sim [--experience walk-together|orc-pursuit|future-self]

let arguments = CommandLine.arguments
var experienceID = FutureSelfExperience.experienceID
if let flagIndex = arguments.firstIndex(of: "--experience"), flagIndex + 1 < arguments.count {
    experienceID = arguments[flagIndex + 1]
}

func header(_ title: String) {
    print("\n════════════════════════════════════════════")
    print("  \(title)")
    print("════════════════════════════════════════════")
}

func show(_ events: [ExperienceEvent], at elapsed: TimeInterval) {
    let stamp = String(format: "[%02d:%02d]", Int(elapsed) / 60, Int(elapsed) % 60)
    for event in events {
        switch event {
        case .dialogue(let line): print("\(stamp) 🦊 \(line)")
        case .milestone(let text): print("\(stamp) ⭐ \(text)")
        case .companionBehavior, .audio, .threatLevel, .ghostDistance:
            break // continuous channels — sampled below instead of spamming
        }
    }
}

// ─── Setup ───────────────────────────────────────────────────────────────

let store = InMemoryStore()
let memoryEngine = MemoryEngine(store: store)
let experiences = ExperienceEngine.standard()

let day1 = DateComponents(calendar: .current, year: 2026, month: 7, day: 15, hour: 18, minute: 30).date!

header("DAY 1 — Onboarding")
let companion = Companion(name: "Ember", species: .emberfox, createdAt: day1)
let brain = CompanionEngine(companion: companion, memoryEngine: memoryEngine)
print("Created companion: \(companion.name) the \(companion.species.displayName)")
print("🦊 \(brain.greeting(now: day1))")

guard let registration = experiences.available.first(where: { $0.id == experienceID }),
      let experience = experiences.makeExperience(id: experienceID) else {
    print("Unknown experience '\(experienceID)'. Available: \(experiences.available.map(\.id).joined(separator: ", "))")
    exit(1)
}

header("DAY 1 — \(registration.name) at Shoreline Park (10 min)")
print("🦊 \(brain.arrivalLine(locationName: "Shoreline Park"))")

let context = ExperienceContext(companion: brain.companion,
                                locationName: "Shoreline Park",
                                timeOfDay: .evening,
                                weather: .clear)
let runner = ExperienceRunner(experience: experience, context: context)
let receiptBuilder = SessionReceiptBuilder(mode: .simulated)
let openingEvents = runner.begin()
receiptBuilder.record(openingEvents)
show(openingEvents, at: 0)

// Simulated GPS: 5-second fixes heading up the shoreline. The walker
// starts easy (1.2 m/s), pushes in the middle (1.6 m/s), pauses once at a
// viewpoint, then sprints the finish — enough variance to exercise pace,
// stop detection, and every experience's tension curve.
let tracker = MovementSessionTracker(activity: nil, startedAt: day1)
var coordinate = GeoCoordinate(latitude: 37.4312, longitude: -122.0898)
tracker.record(MovementSample(coordinate: coordinate, timestamp: day1))

var lastGhostGap: Double?
var lastThreat: Double?

for tick in 1...120 { // 120 × 5 s = 10 minutes
    let elapsed = TimeInterval(tick * 5)
    let speed: Double
    switch tick {
    case ..<40: speed = 1.2          // easing in
    case 40..<48: speed = 0.0        // viewpoint pause (~40 s)
    case 48..<100: speed = 1.6       // pushing
    default: speed = 2.4             // finishing surge
    }
    coordinate.latitude += (speed * 5) / 111_111 // meters → degrees north
    let sampleDate = day1.addingTimeInterval(elapsed)
    guard let update = tracker.record(MovementSample(coordinate: coordinate, timestamp: sampleDate)) else { continue }

    let events = runner.handle(update)
    receiptBuilder.record(events)
    show(events, at: elapsed)
    for event in events {
        if case .ghostDistance(let gap) = event { lastGhostGap = gap }
        if case .threatLevel(let threat) = event { lastThreat = threat }
    }
    if tick % 24 == 0 { // once per 2 minutes, report the continuous channels
        var status = String(format: "[%02d:%02d] 📍 %.0f m", Int(elapsed) / 60, Int(elapsed) % 60, update.distanceMeters)
        if let pace = update.paceSecondsPerKm {
            status += String(format: " · pace %d:%02d /km", Int(pace) / 60, Int(pace) % 60)
        }
        if let gap = lastGhostGap { status += String(format: " · ghost %+.0f m ahead", gap) }
        if let threat = lastThreat { status += String(format: " · threat %.0f%%", threat * 100) }
        print(status)
    }
}

let session = tracker.end(at: day1.addingTimeInterval(600))
let outcome = runner.finish(session: session)

header("DAY 1 — Session Summary")
print(String(format: "Activity: %@ (auto-detected)", session.activity.displayName))
print(String(format: "Distance: %.2f km in %.0f min", session.distanceMeters / 1000, session.durationSeconds / 60))
if let pace = session.averagePaceSecondsPerKm {
    print(String(format: "Avg pace: %d:%02d /km", Int(pace) / 60, Int(pace) % 60))
}
print("Result: \(outcome.summaryLine)")

let bondBefore = brain.companion.relationship.level
let memory = brain.completeSession(session, outcome: outcome,
                                   experienceID: registration.id,
                                   experienceName: registration.name,
                                   locationName: "Shoreline Park")
let bondAfter = brain.companion.relationship.level
print("Bond: +\(outcome.bondDelta) → \(brain.companion.relationship.bondPoints) points (\(bondAfter.displayName))")
if bondAfter > bondBefore { print("💛 Relationship grew: \(bondBefore.displayName) → \(bondAfter.displayName)") }
print("📖 New memory: “\(memory.text)”")

// Field-test receipt: save next to the working directory for inspection.
let receipt = receiptBuilder.finalize(session: session, outcome: outcome,
                                      companionName: brain.companion.name,
                                      experienceID: registration.id,
                                      experienceName: registration.name,
                                      locationName: "Shoreline Park",
                                      memory: memory)
let receiptStore = FileReceiptStore(
    directory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("receipts"))
if let url = try? receiptStore.save(receipt) {
    let counts = receipt.eventCounts.sorted { $0.key < $1.key }
        .map { "\($0.key)×\($0.value)" }.joined(separator: ", ")
    print("🧾 Receipt: \(counts)")
    print("   saved to \(url.path)")
}

// ─── Day 2 ───────────────────────────────────────────────────────────────

let day2 = day1.addingTimeInterval(86_400)
header("DAY 2 — Opening the app again")
print("🦊 \(brain.greeting(now: day2))")
print("\n(You walk back to Shoreline Park...)")
print("🦊 \(brain.arrivalLine(locationName: "Shoreline Park"))")

header("DAY 2 — Today's Recommendations")
let recommender = RecommendationEngine(experiences: experiences, memoryEngine: memoryEngine)
let recommendations = recommender.recommend(.init(timeOfDay: .evening, weather: .clear, availableMinutes: 25))
for (rank, rec) in recommendations.enumerated() {
    print("\(rank + 1). \(rec.experienceName) — \(rec.reason)")
}

header("DAY 2 — Ask Ember something")
let ai = RuleBasedProvider()
let aiContext = CompanionAIContext(companion: brain.companion,
                                   currentActivity: nil,
                                   locationName: "Shoreline Park",
                                   weather: .clear,
                                   timeOfDay: .evening,
                                   currentExperienceName: nil,
                                   recentMemories: memoryEngine.recentMemories(limit: 5),
                                   recentAchievements: outcome.succeeded ? [outcome.memorySeed] : [])
let systemPrompt = PromptBuilder.systemPrompt(aiContext)
print("You: Do you remember yesterday?")
print("🦊 ", terminator: "")
let semaphore = DispatchSemaphore(value: 0)
Task {
    for await chunk in ai.reply(system: systemPrompt, userLine: "Do you remember yesterday?") {
        print(chunk, terminator: "")
    }
    print("")
    semaphore.signal()
}
semaphore.wait()

print("\n──────────────────────────────────────────────")
print("System prompt a hosted LLM would receive (Phase 7):")
print("──────────────────────────────────────────────")
print(systemPrompt)
print("")
