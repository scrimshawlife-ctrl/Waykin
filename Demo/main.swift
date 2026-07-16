import Foundation
import WaykinCore

print("=== WAYKIN SOLO MVP DEMO ===")
print("Deterministic audio-first walking loop; no GPS or permissions required.\n")

let movement = MovementEngine()
let companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
let memoryEngine = MemoryEngine()
let recommendation = RecommendationEngine().recommend(for: "night", lastExperience: nil, activity: .walk).first

print("Companion: \(companion.name) (Bond: \(companion.bondLevel))")
print("Recommended path: \(recommendation?.experienceID ?? "companion_walk") / \(recommendation?.variantID ?? "nighttimeGuardian")")

let experience = CompanionWalkExperience()
let context = ExperienceContext(timeOfDay: TimeContext.night.rawValue, activity: .walk, bondLevel: companion.bondLevel, eventSeed: 7)
var state = experience.start(context: context)
var companionRuntime = CompanionRuntime()

try movement.startSession(activity: .walk, experienceID: "companion_walk")
print("\nStarted Begin Walk demo.")

let ticks: [(TimeInterval, Double)] = [
    (12, 1.2), (12, 1.3), (12, 1.5), (12, 0.2),
    (12, 1.6), (12, 1.7), (12, 1.4), (12, 1.5)
]

for (index, tick) in ticks.enumerated() {
    movement.simulate(deltaSeconds: tick.0, speed: tick.1)
    guard let session = movement.currentSession else { break }

    let snapshot = MovementSnapshot(
        timestamp: session.routePoints.last?.timestamp ?? Date(timeIntervalSince1970: Double(index) * tick.0),
        speed: session.currentSpeedMetersPerSecond,
        distanceDelta: tick.0 * tick.1,
        isMoving: tick.1 > 0.1
    )
    let update = experience.update(previousState: state, movement: snapshot, context: context)
    state = update.state
    update.companionCommands.forEach { companionRuntime.apply(command: $0) }

    let cue = update.semanticAudioCues.first?.kind.rawValue ?? "none"
    let event = update.narrativeEvents.first ?? "quiet"
    print("Tick \(index + 1): event=\(event), audio=\(cue), companion=\(companionRuntime.state.rawValue), distance=\(Int(session.distanceMeters))m")
}

let finalSession = try movement.endSession()
let result = experience.finish(state: state, session: finalSession)
let memory = memoryEngine.createMemory(session: finalSession, result: result, companion: companion)

print("\nSession ended. Outcome: \(result.outcome)")
print("Memory: \"\(memory.text)\"")
print("Bond +\(result.bondDelta)")
print("\n=== DEMO COMPLETE ===")
