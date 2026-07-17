import XCTest
@testable import WaykinCore

final class CompanionMemoryTests: XCTestCase {
    let day1 = Date(timeIntervalSince1970: 1_800_000_000)
    var day2: Date { day1.addingTimeInterval(86_400) }

    func makeSession(endingAt end: Date, distance: Double = 900) -> MovementSession {
        MovementSession(activity: .walking,
                        startedAt: end.addingTimeInterval(-600),
                        endedAt: end,
                        distanceMeters: distance, route: [])
    }

    func makeOutcome(bond: Int = 8) -> ExperienceOutcome {
        ExperienceOutcome(succeeded: true, bondDelta: bond,
                          memorySeed: "caught your future self",
                          summaryLine: "Caught the ghost.")
    }

    func makeBrain() -> CompanionEngine {
        CompanionEngine(companion: Companion(name: "Ember", createdAt: day1),
                        memoryEngine: MemoryEngine(store: InMemoryStore()))
    }

    // MARK: Pillar 1 — persistent companion & evolving greetings

    func testFirstGreetingIsAFirstMeeting() {
        XCTAssertTrue(makeBrain().greeting(now: day1).contains("never seen this world"))
    }

    func testGreetingChangesAfterASessionAndReferencesMemory() {
        let brain = makeBrain()
        let before = brain.greeting(now: day1)
        brain.completeSession(makeSession(endingAt: day1), outcome: makeOutcome(),
                              experienceID: "future-self", experienceName: "Future Self",
                              locationName: "Shoreline Park")
        let after = brain.greeting(now: day2)
        XCTAssertNotEqual(before, after)
        XCTAssertTrue(after.contains("Shoreline Park"), "next-day greeting should recall the memory: \(after)")
    }

    func testBondLevelsProgress() {
        let brain = makeBrain()
        XCTAssertEqual(brain.companion.relationship.level, .stranger)
        for day in 0..<5 {
            brain.completeSession(makeSession(endingAt: day1.addingTimeInterval(Double(day) * 86_400)),
                                  outcome: makeOutcome(bond: 8),
                                  experienceID: "future-self", experienceName: "Future Self",
                                  locationName: "Shoreline Park")
        }
        XCTAssertEqual(brain.companion.relationship.bondPoints, 40)
        XCTAssertEqual(brain.companion.relationship.level, .friend)
        XCTAssertEqual(brain.companion.totalSessions, 5)
    }

    // MARK: Pillar 5 — memory & place recognition

    func testMemoryTextMentionsPlaceAndSeed() {
        let store = InMemoryStore()
        let engine = MemoryEngine(store: store)
        let memory = engine.recordSession(makeSession(endingAt: day1), outcome: makeOutcome(),
                                          experienceID: "future-self", experienceName: "Future Self",
                                          locationName: "Shoreline Park", companionName: "Ember")
        XCTAssertTrue(memory.text.contains("Shoreline Park"))
        XCTAssertTrue(memory.text.contains("caught your future self"))
        XCTAssertEqual(store.allMemories().count, 1)
    }

    func testPlaceRecognitionAndFavorites() {
        let brain = makeBrain()
        XCTAssertTrue(brain.arrivalLine(locationName: "Shoreline Park").contains("new place"))

        brain.completeSession(makeSession(endingAt: day1), outcome: makeOutcome(),
                              experienceID: "walk-together", experienceName: "Companion Walk",
                              locationName: "Shoreline Park")
        XCTAssertTrue(brain.arrivalLine(locationName: "Shoreline Park").contains("I remember this place"))

        for day in 1...2 {
            brain.completeSession(makeSession(endingAt: day1.addingTimeInterval(Double(day) * 86_400)),
                                  outcome: makeOutcome(),
                                  experienceID: "walk-together", experienceName: "Companion Walk",
                                  locationName: "Shoreline Park")
        }
        XCTAssertTrue(brain.arrivalLine(locationName: "Shoreline Park").contains("Our place"))
    }

    // MARK: Phase 7 — prompt assembly

    func testSystemPromptContainsMandatedContext() {
        let brain = makeBrain()
        brain.completeSession(makeSession(endingAt: day1), outcome: makeOutcome(),
                              experienceID: "future-self", experienceName: "Future Self",
                              locationName: "Shoreline Park")
        let prompt = PromptBuilder.systemPrompt(CompanionAIContext(
            companion: brain.companion,
            currentActivity: .walking,
            locationName: "Shoreline Park",
            weather: .rain,
            timeOfDay: .evening,
            currentExperienceName: "Orc Pursuit",
            recentMemories: [Memory(date: day1, locationName: "Shoreline Park",
                                    durationSeconds: 600, distanceMeters: 900,
                                    experienceID: "future-self", experienceName: "Future Self",
                                    bondGained: 8, text: "We caught your future self at Shoreline Park.")],
            recentAchievements: ["caught your future self"]))

        for required in ["Ember", "walking", "Shoreline Park", "rain", "evening", "Orc Pursuit",
                         "caught your future self", "Relationship level"] {
            XCTAssertTrue(prompt.contains(required), "prompt missing '\(required)'")
        }
    }

    // MARK: Phase 8 — recommendations

    func testRecommendationsReturnThreeAndAvoidRepeatingYesterday() {
        let store = InMemoryStore()
        let memoryEngine = MemoryEngine(store: store)
        memoryEngine.recordSession(makeSession(endingAt: day1), outcome: makeOutcome(),
                                   experienceID: FutureSelfExperience.experienceID,
                                   experienceName: "Future Self",
                                   locationName: "Shoreline Park", companionName: "Ember")

        let recommender = RecommendationEngine(experiences: .standard(), memoryEngine: memoryEngine)
        let recommendations = recommender.recommend(.init(timeOfDay: .evening, weather: .clear, availableMinutes: 30))
        XCTAssertEqual(recommendations.count, 3)
        XCTAssertNotEqual(recommendations.first?.experienceID, FutureSelfExperience.experienceID,
                          "yesterday's experience should not be the top pick")
        XCTAssertFalse(recommendations.contains { $0.reason.isEmpty })
    }

    // MARK: AI fallback

    func testRuleBasedProviderRecallsMemoryWhenAsked() async {
        let provider = RuleBasedProvider()
        let system = "You are Ember.\nShared memories, newest first:\n- We caught your future self at Shoreline Park."
        var reply = ""
        for await chunk in provider.reply(system: system, userLine: "Do you remember yesterday?") {
            reply += chunk
        }
        XCTAssertTrue(reply.contains("Shoreline Park"), "reply should surface the memory: \(reply)")
    }
}
