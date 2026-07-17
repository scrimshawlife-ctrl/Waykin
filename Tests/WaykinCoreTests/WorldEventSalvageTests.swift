import XCTest
@testable import WaykinCore

final class WorldEventSalvageTests: XCTestCase {
    func testSameKindRespectsPerKindCooldown() {
        let configuration = WorldEventGeneratorConfiguration(
            minimumTickSpacing: 10,
            rules: [WorldEventRule(kind: .quietInterval, weight: 1, cooldown: 100)]
        )
        var generator = WorldEventGenerator(seed: 7, configuration: configuration)
        let state = worldState(pressure: 0.1)
        let now = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(generator.evaluate(state: state, now: now, elapsed: 0)?.kind, .quietInterval)
        XCTAssertNil(generator.evaluate(state: state, now: now, elapsed: 50))
        XCTAssertEqual(generator.evaluate(state: state, now: now, elapsed: 100)?.kind, .quietInterval)
    }

    func testUnrelatedEligibleKindIsNotBlockedByAnotherKindsCooldown() {
        let configuration = WorldEventGeneratorConfiguration(
            minimumTickSpacing: 10,
            rules: [
                WorldEventRule(kind: .quietInterval, maximumPressure: 0.2, weight: 1, cooldown: 100),
                WorldEventRule(kind: .companionObserves, minimumPressure: 0.8, weight: 1, cooldown: 100)
            ]
        )
        var generator = WorldEventGenerator(seed: 7, configuration: configuration)
        let now = Date(timeIntervalSince1970: 2_000)

        XCTAssertEqual(generator.evaluate(
            state: worldState(pressure: 0.1),
            now: now,
            elapsed: 0
        )?.kind, .quietInterval)
        XCTAssertEqual(generator.evaluate(
            state: worldState(pressure: 0.9),
            now: now,
            elapsed: 20
        )?.kind, .companionObserves)
    }

    func testMinimumGlobalSpacingStillBlocksDifferentKind() {
        let configuration = WorldEventGeneratorConfiguration(
            minimumTickSpacing: 10,
            rules: [
                WorldEventRule(kind: .quietInterval, maximumPressure: 0.2, weight: 1, cooldown: 100),
                WorldEventRule(kind: .companionObserves, minimumPressure: 0.8, weight: 1, cooldown: 100)
            ]
        )
        var generator = WorldEventGenerator(seed: 7, configuration: configuration)
        let now = Date(timeIntervalSince1970: 3_000)

        XCTAssertNotNil(generator.evaluate(state: worldState(pressure: 0.1), now: now, elapsed: 0))
        XCTAssertNil(generator.evaluate(state: worldState(pressure: 0.9), now: now, elapsed: 5))
    }

    func testSeedReplayRemainsDeterministic() {
        func replay() -> [WorldEventKind] {
            var generator = WorldEventGenerator(seed: 42)
            return stride(from: 0.0, through: 400.0, by: 20).compactMap { elapsed in
                generator.evaluate(
                    state: worldState(pressure: elapsed < 200 ? 0.2 : 0.45),
                    now: Date(timeIntervalSince1970: 4_000 + elapsed),
                    elapsed: elapsed
                )?.kind
            }
        }

        XCTAssertFalse(replay().isEmpty)
        XCTAssertEqual(replay(), replay())
    }

    func testPursuitTransitionsRequireCoherentOrdering() {
        let experience = CompanionWalkExperience()
        let context = ExperienceContext(
            timeOfDay: TimeContext.midday.rawValue,
            activity: .walk,
            bondLevel: 12,
            eventSeed: 7
        )
        var state = experience.start(context: context)

        let invalidIntensify = experience.updateForDemo(
            previousState: state,
            movement: movement(elapsed: 40),
            context: context,
            scheduledEventKind: .pursuitIntensifies
        )
        XCTAssertTrue(invalidIntensify.narrativeEvents.isEmpty)
        state = invalidIntensify.state
        XCTAssertEqual(walkState(state).pursuitState, .inactive)

        let invalidFade = experience.updateForDemo(
            previousState: state,
            movement: movement(elapsed: 80),
            context: context,
            scheduledEventKind: .pursuitFades
        )
        XCTAssertTrue(invalidFade.narrativeEvents.isEmpty)
        state = invalidFade.state
        XCTAssertEqual(walkState(state).pursuitState, .inactive)

        let orderedKinds: [WorldEventKind] = [
            .distantPresence,
            .pursuitBegins,
            .pursuitIntensifies,
            .pursuitFades
        ]
        let expectedStates: [PursuitState] = [.noticed, .approaching, .close, .fading]

        for (index, kind) in orderedKinds.enumerated() {
            let update = experience.updateForDemo(
                previousState: state,
                movement: movement(elapsed: Double(index + 3) * 40),
                context: context,
                scheduledEventKind: kind
            )
            state = update.state
            XCTAssertEqual(update.narrativeEvents, [kind.rawValue])
            XCTAssertEqual(walkState(state).pursuitState, expectedStates[index])
        }
        XCTAssertEqual(walkState(state).eventHistory.map(\.kind), orderedKinds)
    }

    func testShortPhysicalFixtureDoesNotGuaranteePursuit() {
        let experience = CompanionWalkExperience()
        let context = ExperienceContext(
            timeOfDay: TimeContext.midday.rawValue,
            activity: .walk,
            bondLevel: 0,
            eventSeed: 3
        )
        var state = experience.start(context: context)

        for index in 1...4 {
            state = experience.update(
                previousState: state,
                movement: MovementSnapshot(
                    timestamp: Date(timeIntervalSince1970: Double(index * 8)),
                    speed: 0.8,
                    distanceDelta: 6.4,
                    isMoving: true
                ),
                context: context
            ).state
        }

        let pursuitKinds: Set<WorldEventKind> = [
            .distantPresence,
            .pursuitBegins,
            .pursuitIntensifies,
            .pursuitFades
        ]
        XCTAssertTrue(walkState(state).eventHistory.allSatisfy { !pursuitKinds.contains($0.kind) })
        XCTAssertEqual(walkState(state).pursuitState, .inactive)
    }

    func testEventVocabularyRemainsExactlyBounded() {
        XCTAssertEqual(Set(WorldEventKind.allCases), [
            .companionDrawsNear,
            .companionMovesAhead,
            .companionObserves,
            .distantPresence,
            .pursuitBegins,
            .pursuitIntensifies,
            .pursuitFades,
            .familiarPlaceStirs,
            .quietInterval,
            .bondMoment
        ])
        XCTAssertFalse(WorldEventKind.allCases.map(\.rawValue).contains("wandering-paths"))
    }

    private func worldState(pressure: Double) -> WorldState {
        WorldState(
            timeContext: .midday,
            movementState: .moving,
            currentSpeedMetersPerSecond: 1.4,
            sessionDistanceMeters: 100,
            activeTime: 0,
            bondLevel: 12,
            familiarity: 0,
            energy: 0.7,
            pressure: pressure
        )
    }

    private func movement(elapsed: TimeInterval) -> MovementSnapshot {
        MovementSnapshot(
            timestamp: Date(timeIntervalSince1970: 5_000 + elapsed),
            speed: 1.4,
            distanceDelta: 56,
            isMoving: true
        )
    }

    private func walkState(_ state: ExperienceSessionState) -> CompanionWalkState {
        guard case .companionWalk(let walkState) = state.runtimeState else {
            XCTFail("Expected Companion Walk state")
            return CompanionWalkState(
                accumulatedBondProgress: 0,
                movementSeconds: 0,
                milestoneIndex: 0,
                tone: "invalid"
            )
        }
        return walkState
    }
}
