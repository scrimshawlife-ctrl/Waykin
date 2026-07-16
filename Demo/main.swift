import WaykinCore
import Foundation

print("=== WAYKIN MPOC DEMO ===")
print("Simulating full product loop without GPS or permissions.\n")

let movement = MovementEngine()
let companion = Companion(id: UUID(), name: "Lira", archetype: "explorer", bondLevel: 12, lastSessionID: nil, memories: [])
let memoryEngine = MemoryEngine()
let recEngine = RecommendationEngine()

print("Companion: \(companion.name) (Bond: \(companion.bondLevel))")

let recs = recEngine.recommend(for: "night", lastExperience: "future_self", activity: ActivityType.walk)
print("\nRecommendations (night):")
for r in recs { print(" - \(r.experienceID) (\(r.variantID)) score:\(r.score)") }

let chosenExpID = "orc_pursuit"
let exp: any WaykinExperience
switch chosenExpID {
case "orc_pursuit": exp = OrcPursuitExperience()
case "future_self": exp = FutureSelfExperience()
default: exp = CompanionWalkExperience()
}

try! movement.startSession(activity: ActivityType.walk, experienceID: chosenExpID)
print("\nStarted walk with \(chosenExpID)")

let context = ExperienceContext(timeOfDay: "night", activity: ActivityType.walk)
var expState = exp.start(context: context)
var companionRuntime = CompanionRuntime()

print("\nSimulating movement...")
for tick in 1...10 {
    let speed = tick < 4 ? 1.2 : (tick > 7 ? 0.3 : 2.8)
    movement.simulate(deltaSeconds: 12, speed: speed)

    guard let session = movement.currentSession else { break }
    let snapshot = MovementSnapshot(
        timestamp: Date(),
        speed: session.currentSpeedMetersPerSecond,
        distanceDelta: 0,
        isMoving: speed > 0.5
    )

    let update = exp.update(previousState: expState, movement: snapshot, context: context)
    expState = update.state

    for cmd in update.companionCommands {
        companionRuntime.apply(command: cmd)
    }

    if !update.narrativeEvents.isEmpty {
        print("  Tick \(tick): \(update.narrativeEvents.joined()) | Dist: \(Int(session.distanceMeters))m")
    }
}

let finalSession = try! movement.endSession()
let result = exp.finish(state: expState, session: finalSession)
print("\nSession ended. Outcome: \(result.outcome)")

let mem = memoryEngine.createMemory(session: finalSession, result: result, companion: companion)
print("Memory: \"\(mem.text)\"")

var updatedCompanion = companion
updatedCompanion.bondLevel += result.bondDelta
updatedCompanion.memories.append(mem)
updatedCompanion.lastSessionID = finalSession.id

print("\nUpdated Companion Bond: \(updatedCompanion.bondLevel)")
print("Memories count: \(updatedCompanion.memories.count)")

let nextRecs = recEngine.recommend(for: "day", lastExperience: chosenExpID, activity: ActivityType.walk)
print("\nNext day recommendations:")
for r in nextRecs.prefix(2) {
    print(" - \(r.experienceID) because: \(r.observedReasons + r.inferredReasons)")
}

print("\n=== DEMO COMPLETE - Full loop proven ===")
print("Companion now remembers the session and bond increased.")
