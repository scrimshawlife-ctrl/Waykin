import XCTest
@testable import WaykinCore

final class WorldEventTests: XCTestCase {

    func snapshot(energy: Double = 0.6, pressure: Double = 0.1,
                  familiarity: Double = 0, bond: Int = 0) -> WorldSnapshot {
        WorldSnapshot(energy: energy, pressure: pressure, familiarity: familiarity,
                      bondPoints: bond, isMoving: true)
    }

    // MARK: Generator mechanics

    func testSameSeedReplaysIdenticalEventSequence() {
        func run(seed: UInt64) -> [WorldEventKind] {
            var generator = WorldEventGenerator(seed: seed)
            var kinds: [WorldEventKind] = []
            for tick in stride(from: 0.0, through: 600, by: 5) {
                if let event = generator.evaluate(snapshot(), elapsed: tick) {
                    kinds.append(event.kind)
                }
            }
            return kinds
        }
        XCTAssertFalse(run(seed: 42).isEmpty)
        XCTAssertEqual(run(seed: 42), run(seed: 42))
        XCTAssertNotEqual(run(seed: 42), run(seed: 43), "different seeds should diverge")
    }

    func testTickSpacingIsRespected() {
        var generator = WorldEventGenerator(seed: 7)
        XCTAssertNotNil(generator.evaluate(snapshot(), elapsed: 100))
        // Inside minimum tick spacing (40 s): nothing fires.
        XCTAssertNil(generator.evaluate(snapshot(), elapsed: 120))
    }

    func testPerKindCooldownPreventsImmediateRepeat() {
        // Only one rule: after it fires, its cooldown must block a re-fire
        // even once tick spacing has passed.
        let config = WorldEventConfiguration(
            minimumTickSpacing: 10,
            rules: [WorldEventRule(kind: .quietInterval, weight: 1, cooldown: 100)])
        var generator = WorldEventGenerator(seed: 7, configuration: config)
        XCTAssertNotNil(generator.evaluate(snapshot(), elapsed: 0))
        XCTAssertNil(generator.evaluate(snapshot(), elapsed: 50), "kind still cooling down")
        XCTAssertNotNil(generator.evaluate(snapshot(), elapsed: 120))
    }

    func testEligibilityRespectsPressureBandsAndBondGate() {
        let calm = WorldEventConfiguration.defaultRules.first { $0.kind == .quietInterval }!
        XCTAssertTrue(calm.isEligible(for: snapshot(pressure: 0.1)))
        XCTAssertFalse(calm.isEligible(for: snapshot(pressure: 0.9)),
                       "quietInterval must not fire under high pressure")

        let intensify = WorldEventConfiguration.defaultRules.first { $0.kind == .pursuitIntensifies }!
        XCTAssertFalse(intensify.isEligible(for: snapshot(pressure: 0.1)))
        XCTAssertTrue(intensify.isEligible(for: snapshot(pressure: 0.8)))

        let bond = WorldEventConfiguration.defaultRules.first { $0.kind == .bondMoment }!
        XCTAssertFalse(bond.isEligible(for: snapshot(bond: 5)))
        XCTAssertTrue(bond.isEligible(for: snapshot(bond: 50)))
    }

    // MARK: The experience plug-in

    func makeUpdate(elapsed: TimeInterval, distance: Double, speed: Double) -> MovementUpdate {
        MovementUpdate(elapsedSeconds: elapsed, distanceMeters: distance,
                       paceSecondsPerKm: speed > 0 ? 1000 / speed : nil,
                       speedMetersPerSecond: speed,
                       isMoving: speed >= MovementSessionTracker.movingSpeedThreshold,
                       detectedActivity: .walking,
                       coordinate: GeoCoordinate(latitude: 37, longitude: -122))
    }

    func testWanderingPathsEmitsWorldMomentsAndAlwaysSucceeds() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let experience = WanderingPathsExperience(seed: 42)
        var companion = Companion(name: "Ember", createdAt: start)
        companion.relationship.bondPoints = 40 // unlock bondMoment rule
        let context = ExperienceContext(companion: companion, locationName: "Shoreline Park")

        _ = experience.begin(context: context)
        var dialogueCount = 0
        var threats: [Double] = []
        var distance = 0.0
        for tick in 1...360 { // 30 minutes — long enough for several events
            distance += 1.4 * 5
            let events = experience.update(
                makeUpdate(elapsed: Double(tick * 5), distance: distance, speed: 1.4),
                context: context)
            for event in events {
                if case .dialogue = event { dialogueCount += 1 }
                if case .threatLevel(let threat) = event { threats.append(threat) }
            }
        }
        XCTAssertGreaterThanOrEqual(dialogueCount, 3, "a 30-minute wander should surface several moments")
        XCTAssertTrue(threats.allSatisfy { (0...1).contains($0) })

        let session = MovementSession(activity: .walking, startedAt: start,
                                      endedAt: start.addingTimeInterval(1800),
                                      distanceMeters: distance, route: [])
        let outcome = experience.end(session: session, context: context)
        XCTAssertTrue(outcome.succeeded)
        XCTAssertGreaterThan(outcome.bondDelta, 0)
        XCTAssertFalse(outcome.memorySeed.isEmpty)
    }

    func testWanderingPathsIsRegisteredInStandardEngine() {
        let engine = ExperienceEngine.standard()
        XCTAssertEqual(engine.available.count, 4)
        XCTAssertNotNil(engine.makeExperience(id: WanderingPathsExperience.experienceID))
    }
}
