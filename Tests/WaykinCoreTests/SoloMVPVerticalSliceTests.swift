import XCTest
@testable import WaykinCore

final class SoloMVPVerticalSliceTests: XCTestCase {
    func testWorldStateDerivationClampsInvalidValues() {
        let state = WorldState(
            timeContext: .midday,
            movementState: .moving,
            currentSpeedMetersPerSecond: .nan,
            sessionDistanceMeters: -4,
            activeTime: -Double.infinity,
            bondLevel: -3,
            familiarity: 3,
            energy: .infinity,
            pressure: -1
        )

        XCTAssertEqual(state.currentSpeedMetersPerSecond, 0)
        XCTAssertEqual(state.sessionDistanceMeters, 0)
        XCTAssertEqual(state.activeTime, 0)
        XCTAssertEqual(state.bondLevel, 0)
        XCTAssertEqual(state.familiarity, 1)
        XCTAssertEqual(state.energy, 0)
        XCTAssertEqual(state.pressure, 0)
    }

    func testSeededGeneratorIsDeterministicForSameInputs() {
        let start = Date(timeIntervalSince1970: 1_000)
        var states: [WorldState] = []
        for idx in 0..<8 {
            let lastEventAt: Date? = idx == 0 ? nil : start.addingTimeInterval(Double(idx * 40 - 40))
            let familiarity = Double(idx) / 10
            states.append(WorldState(
                timeContext: .midday,
                movementState: .moving,
                currentSpeedMetersPerSecond: 1.4,
                sessionDistanceMeters: Double(idx * 80),
                activeTime: Double(idx * 40),
                bondLevel: 12,
                familiarity: familiarity,
                energy: 0.65,
                pressure: 0.35,
                lastEventAt: lastEventAt
            ))
        }

        var first = WorldEventGenerator(seed: 7)
        var second = WorldEventGenerator(seed: 7)

        let firstKinds = states.enumerated().compactMap { idx, state in
            first.evaluate(state: state, now: start.addingTimeInterval(Double(idx * 40)))?.kind
        }
        let secondKinds = states.enumerated().compactMap { idx, state in
            second.evaluate(state: state, now: start.addingTimeInterval(Double(idx * 40)))?.kind
        }

        XCTAssertEqual(firstKinds, secondKinds)
        XCTAssertFalse(firstKinds.isEmpty)
    }

    func testGeneratorEnforcesCooldownAndNoEventPath() {
        let now = Date(timeIntervalSince1970: 2_000)
        let config = WorldEventGeneratorConfiguration(
            minimumTickSpacing: 60,
            rules: [WorldEventRule(kind: .bondMoment, minimumEnergy: 0.2, minimumBondLevel: 5, cooldown: 60)]
        )
        var generator = WorldEventGenerator(seed: 1, configuration: config)
        let eligible = WorldState(timeContext: .midday, movementState: .moving, currentSpeedMetersPerSecond: 1, sessionDistanceMeters: 100, activeTime: 60, bondLevel: 6, familiarity: 0.1, energy: 0.5, pressure: 0.1)

        XCTAssertNotNil(generator.evaluate(state: eligible, now: now))
        XCTAssertNil(generator.evaluate(state: eligible, now: now.addingTimeInterval(30)))

        let ineligible = WorldState(timeContext: .midday, movementState: .stopped, currentSpeedMetersPerSecond: 0, sessionDistanceMeters: 0, activeTime: 0, bondLevel: 0, familiarity: 0, energy: 0, pressure: 0)
        XCTAssertNil(generator.evaluate(state: ineligible, now: now.addingTimeInterval(90)))
    }

    func testCompanionPursuitAndAudioStayCoherent() {
        let exp = CompanionWalkExperience()
        let ctx = ExperienceContext(timeOfDay: TimeContext.midday.rawValue, activity: .walk, bondLevel: 12, eventSeed: 11)
        var state = exp.start(context: ctx)
        var runtime = CompanionRuntime()

        let snapshot = MovementSnapshot(timestamp: Date(timeIntervalSince1970: 3_000), speed: 1.6, distanceDelta: 160, isMoving: true)
        let update = exp.update(previousState: state, movement: snapshot, context: ctx)
        state = update.state
        update.companionCommands.forEach { runtime.apply(command: $0) }
        if case .companionWalk(let walkState) = state.runtimeState {
            runtime.apply(event: walkState.lastEvent)
            XCTAssertNotEqual(walkState.pursuitState, .close, "One calm tick should not create maximum pursuit pressure.")
            XCTAssertLessThanOrEqual(update.semanticAudioCues.count, 1)
            XCTAssertTrue(CompanionBehaviorState.allCasesForTests.contains(runtime.state))
        } else {
            XCTFail("Expected companion walk state")
        }
    }

    func testAudioLayerPriorityCooldownAndSessionEnd() {
        let now = Date(timeIntervalSince1970: 4_000)
        var layer = AudioExperienceLayer(cooldown: 20)
        let pressure = WorldEvent(kind: .pursuitIntensifies, occurredAt: now, intensity: 0.8, debugLabel: "pressure")
        let release = WorldEvent(kind: .pursuitFades, occurredAt: now.addingTimeInterval(5), intensity: 0.3, debugLabel: "release")

        XCTAssertEqual(layer.cue(for: pressure, now: now)?.kind, .pursuitPressure)
        XCTAssertNil(layer.cue(for: release, now: now.addingTimeInterval(5)))
        XCTAssertEqual(layer.activeCueCount, 1)
        layer.endSession()
        XCTAssertEqual(layer.activeCueCount, 0)
    }

    func testFrequencyBoundOverDeterministicFixture() {
        let start = Date(timeIntervalSince1970: 5_000)
        var generator = WorldEventGenerator(seed: 19)
        var lastEventAt: Date?
        var count = 0

        for idx in 0..<30 {
            let now = start.addingTimeInterval(Double(idx * 10))
            let state = WorldState(
                timeContext: .twilight,
                movementState: .moving,
                currentSpeedMetersPerSecond: 1.5,
                sessionDistanceMeters: Double(idx * 25),
                activeTime: Double(idx * 10),
                bondLevel: 14,
                familiarity: 0.4,
                energy: 0.7,
                pressure: 0.4,
                lastEventAt: lastEventAt
            )
            if let event = generator.evaluate(state: state, now: now) {
                count += 1
                lastEventAt = event.occurredAt
            }
        }

        XCTAssertLessThanOrEqual(count, 8)
        XCTAssertGreaterThan(count, 0)
    }
}

private extension CompanionBehaviorState {
    static var allCasesForTests: [CompanionBehaviorState] {
        [.idle, .follow, .lead, .celebrate, .observe, .drawNear, .rest]
    }
}
