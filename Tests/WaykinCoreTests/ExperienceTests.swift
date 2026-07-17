import XCTest
@testable import WaykinCore

final class ExperienceTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    func makeContext() -> ExperienceContext {
        ExperienceContext(companion: Companion(name: "Ember", createdAt: start),
                          locationName: "Shoreline Park",
                          timeOfDay: .evening,
                          weather: .clear)
    }

    func makeUpdate(elapsed: TimeInterval, distance: Double, speed: Double) -> MovementUpdate {
        MovementUpdate(elapsedSeconds: elapsed,
                       distanceMeters: distance,
                       paceSecondsPerKm: speed > 0 ? 1000 / speed : nil,
                       speedMetersPerSecond: speed,
                       isMoving: speed >= MovementSessionTracker.movingSpeedThreshold,
                       detectedActivity: speed >= MovementSessionTracker.runningSpeedThreshold ? .running : .walking,
                       coordinate: GeoCoordinate(latitude: 37, longitude: -122))
    }

    func makeSession(distance: Double, seconds: TimeInterval) -> MovementSession {
        MovementSession(activity: .walking, startedAt: start,
                        endedAt: start.addingTimeInterval(seconds),
                        distanceMeters: distance, route: [])
    }

    // MARK: Walk Together

    func testWalkTogetherEmitsMilestonesAndAlwaysSucceeds() {
        let experience = WalkTogetherExperience()
        let context = makeContext()
        _ = experience.begin(context: context)

        var milestones = 0
        for tick in 1...120 {
            let events = experience.update(
                makeUpdate(elapsed: Double(tick * 5), distance: Double(tick) * 7, speed: 1.4),
                context: context)
            milestones += events.filter { if case .milestone = $0 { return true } else { return false } }.count
        }
        XCTAssertEqual(milestones, 3) // 840 m → 250/500/750 milestones

        let outcome = experience.end(session: makeSession(distance: 840, seconds: 600), context: context)
        XCTAssertTrue(outcome.succeeded)
        XCTAssertGreaterThan(outcome.bondDelta, 0)
    }

    // MARK: Orc Pursuit

    func testOrcPursuitThreatRisesWhenStoppedAndFallsWhenMoving() {
        let experience = OrcPursuitExperience()
        let context = makeContext()
        _ = experience.begin(context: context)

        // Stand still for 60 s: orcs gain, threat rises.
        var threatWhileStopped: [Double] = []
        for tick in 1...12 {
            let events = experience.update(makeUpdate(elapsed: Double(tick * 5), distance: 0, speed: 0), context: context)
            for case .threatLevel(let threat) in events { threatWhileStopped.append(threat) }
        }
        XCTAssertGreaterThan(threatWhileStopped.last!, threatWhileStopped.first!)

        // Now outrun them (2.5 m/s > orc 1.15 m/s): threat falls.
        var distance = 0.0
        var threatWhileRunning: [Double] = []
        for tick in 13...36 {
            distance += 2.5 * 5
            let events = experience.update(makeUpdate(elapsed: Double(tick * 5), distance: distance, speed: 2.5), context: context)
            for case .threatLevel(let threat) in events { threatWhileRunning.append(threat) }
        }
        XCTAssertLessThan(threatWhileRunning.last!, threatWhileRunning.first!)
    }

    func testOrcPursuitCatchesAnIdlePlayer() {
        let experience = OrcPursuitExperience()
        let context = makeContext()
        _ = experience.begin(context: context)

        // 120 m head start / 1.15 m/s ≈ 105 s until caught if you never move.
        var caught = false
        for tick in 1...30 {
            let events = experience.update(makeUpdate(elapsed: Double(tick * 5), distance: 0, speed: 0), context: context)
            for case .threatLevel(let threat) in events where threat >= 1.0 { caught = true }
        }
        XCTAssertTrue(caught)
        let outcome = experience.end(session: makeSession(distance: 0, seconds: 150), context: context)
        XCTAssertFalse(outcome.succeeded)
        XCTAssertGreaterThan(outcome.bondDelta, 0) // losing still builds a little bond
    }

    func testOrcPursuitEscapeAfterChaseWindow() {
        let experience = OrcPursuitExperience()
        let context = makeContext()
        _ = experience.begin(context: context)

        var distance = 0.0
        var escaped = false
        for tick in 1...100 { // 500 s > 480 s window, moving at 1.6 m/s
            distance += 1.6 * 5
            let events = experience.update(makeUpdate(elapsed: Double(tick * 5), distance: distance, speed: 1.6), context: context)
            for case .milestone(let text) in events where text.contains("Escaped") { escaped = true }
        }
        XCTAssertTrue(escaped)
        XCTAssertTrue(experience.end(session: makeSession(distance: distance, seconds: 500), context: context).succeeded)
    }

    // MARK: Future Self

    func testFutureSelfGhostStaysAheadAtBaselinePace() {
        let experience = FutureSelfExperience(baselineSpeed: 1.25)
        let context = makeContext()
        _ = experience.begin(context: context)

        // Walking exactly at baseline: the 5%-faster ghost pulls away.
        var distance = 0.0
        var gaps: [Double] = []
        for tick in 1...60 {
            distance += 1.25 * 5
            let events = experience.update(makeUpdate(elapsed: Double(tick * 5), distance: distance, speed: 1.25), context: context)
            for case .ghostDistance(let gap) in events { gaps.append(gap) }
        }
        XCTAssertGreaterThan(gaps.last!, gaps.first!)
        XCTAssertTrue(gaps.allSatisfy { $0 > 0 })
    }

    func testFutureSelfCanBeCaughtByOutpacingGhost() {
        let experience = FutureSelfExperience(baselineSpeed: 1.25)
        let context = makeContext()
        _ = experience.begin(context: context)

        var distance = 0.0
        var caught = false
        for tick in 1...120 { // 2.0 m/s ≫ ghost's 1.3125 m/s; 40 m gap closes in ~60 s
            distance += 2.0 * 5
            let events = experience.update(makeUpdate(elapsed: Double(tick * 5), distance: distance, speed: 2.0), context: context)
            for case .milestone(let text) in events where text.contains("Caught") { caught = true }
        }
        XCTAssertTrue(caught)
        XCTAssertTrue(experience.end(session: makeSession(distance: distance, seconds: 600), context: context).succeeded)
    }

    // MARK: Modularity — Pillar 3's real test

    /// A brand-new experience registers and runs with zero changes to the
    /// movement engine, the experience engine, or the runner.
    func testNewExperiencePluginNeedsNoEngineChanges() {
        final class SunsetChaseExperience: Experience {
            let id = "sunset-chase"
            let name = "Sunset Chase"
            let summary = "Reach the overlook before the sun dips."
            let difficulty = Difficulty.moderate
            var sawUpdate = false

            func begin(context: ExperienceContext) -> [ExperienceEvent] {
                [.dialogue("The sun waits for no one — go!")]
            }
            func update(_ update: MovementUpdate, context: ExperienceContext) -> [ExperienceEvent] {
                sawUpdate = true
                return [.companionBehavior(.run)]
            }
            func end(session: MovementSession, context: ExperienceContext) -> ExperienceOutcome {
                ExperienceOutcome(succeeded: true, bondDelta: 6,
                                  memorySeed: "raced the sunset", summaryLine: "Made it before dark.")
            }
        }

        let engine = ExperienceEngine.standard()
        engine.register(id: "sunset-chase", name: "Sunset Chase",
                        summary: "Reach the overlook before the sun dips.",
                        difficulty: .moderate) { SunsetChaseExperience() }

        XCTAssertEqual(engine.available.count, 5)
        let experience = try! XCTUnwrap(engine.makeExperience(id: "sunset-chase"))
        let runner = ExperienceRunner(experience: experience, context: makeContext())
        _ = runner.begin()
        _ = runner.handle(makeUpdate(elapsed: 5, distance: 7, speed: 1.4))
        let outcome = runner.finish(session: makeSession(distance: 500, seconds: 300))
        XCTAssertTrue(outcome.succeeded)
        XCTAssertTrue((experience as! SunsetChaseExperience).sawUpdate)
    }
}
