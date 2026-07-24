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

    func testBehaviorTransitionMapsOntoProducedCueKinds() {
        XCTAssertEqual(AudioExperienceLayer.map(behavior: .drawNear)?.kind, .companionNear)
        XCTAssertEqual(AudioExperienceLayer.map(behavior: .lead)?.kind, .companionAhead)
        XCTAssertEqual(AudioExperienceLayer.map(behavior: .rest)?.kind, .quietShift)
        XCTAssertEqual(AudioExperienceLayer.map(behavior: .observe)?.kind, .quietShift)
        XCTAssertEqual(AudioExperienceLayer.map(behavior: .celebrate)?.kind, .bondMotif)
        XCTAssertNil(AudioExperienceLayer.map(behavior: .follow))
        XCTAssertNil(AudioExperienceLayer.map(behavior: .idle))
    }

    func testARPresentationMapsOntoProducedCueKinds() {
        // DCC / AR presentation vocabulary → existing WAV basenames only (no new kinds).
        XCTAssertEqual(AudioExperienceLayer.map(arPresentation: "celebrate")?.kind, .bondMotif)
        XCTAssertEqual(AudioExperienceLayer.map(arPresentation: "alert")?.kind, .pursuitPressure)
        XCTAssertEqual(AudioExperienceLayer.map(arPresentation: "investigate")?.kind, .quietShift)
        XCTAssertNil(AudioExperienceLayer.map(arPresentation: "follow"))
        XCTAssertNil(AudioExperienceLayer.map(arPresentation: "idle"))
        XCTAssertNil(AudioExperienceLayer.map(arPresentation: "unknown"))
        // Case / whitespace normalization.
        XCTAssertEqual(AudioExperienceLayer.map(arPresentation: "  Alert ")?.kind, .pursuitPressure)
        XCTAssertEqual(
            AudioExperienceLayer.map(arPresentation: "celebrate")?.debugLabel,
            "arPresentation:celebrate"
        )
        // Vocabulary covers App CompanionPresentationState / matrix strings.
        for raw in ["idle", "follow", "investigate", "alert", "celebrate"] {
            XCTAssertTrue(AudioExperienceLayer.arPresentationVocabulary.contains(raw))
        }
    }

    func testARPresentationTransitionCueCooldownAndFirstSeedSilent() {
        XCTAssertNil(
            AudioExperienceLayer.cueForARPresentationTransition(
                from: nil,
                to: "alert",
                sessionElapsed: 10,
                lastARPresentationAudioElapsed: nil
            )
        )
        let first = AudioExperienceLayer.cueForARPresentationTransition(
            from: "follow",
            to: "alert",
            sessionElapsed: 20,
            lastARPresentationAudioElapsed: nil
        )
        XCTAssertEqual(first?.kind, .pursuitPressure)
        XCTAssertEqual(first?.debugLabel, "arPresentation:alert")

        XCTAssertNil(
            AudioExperienceLayer.cueForARPresentationTransition(
                from: "alert",
                to: "investigate",
                sessionElapsed: 25,
                lastARPresentationAudioElapsed: 20
            )
        )
        let after = AudioExperienceLayer.cueForARPresentationTransition(
            from: "alert",
            to: "investigate",
            sessionElapsed: 20 + AudioExperienceLayer.arPresentationTransitionCooldown,
            lastARPresentationAudioElapsed: 20
        )
        XCTAssertEqual(after?.kind, .quietShift)

        // Unmapped destination (follow) yields nil even after cooldown.
        XCTAssertNil(
            AudioExperienceLayer.cueForARPresentationTransition(
                from: "alert",
                to: "follow",
                sessionElapsed: 100,
                lastARPresentationAudioElapsed: 20
            )
        )
    }

    func testBehaviorTransitionCueCooldownAndFirstSeedSilent() {
        // First presentation seeds without audio.
        XCTAssertNil(
            AudioExperienceLayer.cueForBehaviorTransition(
                from: nil,
                to: .drawNear,
                sessionElapsed: 10,
                lastBehaviorAudioElapsed: nil
            )
        )
        // Transition after seed emits produced companionNear.
        let first = AudioExperienceLayer.cueForBehaviorTransition(
            from: CompanionBehaviorState.follow.rawValue,
            to: .drawNear,
            sessionElapsed: 20,
            lastBehaviorAudioElapsed: nil
        )
        XCTAssertEqual(first?.kind, .companionNear)
        XCTAssertTrue(first?.debugLabel.hasPrefix("behavior:") == true)

        // Cooldown suppresses rapid flips.
        XCTAssertNil(
            AudioExperienceLayer.cueForBehaviorTransition(
                from: CompanionBehaviorState.drawNear.rawValue,
                to: .lead,
                sessionElapsed: 25,
                lastBehaviorAudioElapsed: 20
            )
        )
        // After cooldown, transition is accepted.
        let after = AudioExperienceLayer.cueForBehaviorTransition(
            from: CompanionBehaviorState.drawNear.rawValue,
            to: .lead,
            sessionElapsed: 20 + AudioExperienceLayer.behaviorTransitionCooldown,
            lastBehaviorAudioElapsed: 20
        )
        XCTAssertEqual(after?.kind, .companionAhead)
    }

    func testExperienceEmitsBehaviorCueWhenNoWorldEvent() {
        let exp = CompanionWalkExperience()
        // eventSeed with no eligible pressure/energy often stays event-silent on a short pause tick.
        let ctx = ExperienceContext(timeOfDay: TimeContext.midday.rawValue, activity: .walk, bondLevel: 1, eventSeed: 1)
        var state = exp.start(context: ctx)
        if case .companionWalk(var walk) = state.runtimeState {
            walk.lastPresentedBehavior = CompanionBehaviorState.follow.rawValue
            walk.movementSeconds = 5
            walk.lastBehaviorAudioElapsed = nil
            // High lastEventElapsed so generator tick spacing may suppress new events.
            walk.lastEventElapsed = 4.9
            state = ExperienceSessionState(runtimeState: .companionWalk(walk))
        } else {
            XCTFail("Expected companion walk")
            return
        }

        // Stationary → observe when no event.
        let snapshot = MovementSnapshot(
            timestamp: Date(timeIntervalSince1970: 9_000),
            speed: 0,
            distanceDelta: 0,
            isMoving: false
        )
        let update = exp.update(previousState: state, movement: snapshot, context: ctx)
        if let cue = update.semanticAudioCues.first {
            XCTAssertTrue(AudioCueKind.allCases.contains(cue.kind))
        }
        if case .companionWalk(let walk) = update.state.runtimeState {
            XCTAssertNotNil(walk.lastPresentedBehavior)
            if walk.lastEvent == nil {
                // follow → observe (stationary) without world event → quietShift behavior cue.
                XCTAssertEqual(walk.lastPresentedBehavior, CompanionBehaviorState.observe.rawValue)
                XCTAssertEqual(update.semanticAudioCues.first?.kind, .quietShift)
                XCTAssertEqual(update.semanticAudioCues.first?.debugLabel, "behavior:observe")
                XCTAssertEqual(walk.lastBehaviorAudioElapsed, walk.movementSeconds)
            } else {
                // Event path remains valid; cue must still be a produced kind when present.
                XCTAssertLessThanOrEqual(update.semanticAudioCues.count, 1)
            }
        } else {
            XCTFail("Expected companion walk after update")
        }
    }

    func testDemoScheduledEventPrefersEventCueOverBehavior() {
        let exp = CompanionWalkExperience()
        let ctx = ExperienceContext(timeOfDay: TimeContext.midday.rawValue, activity: .walk, bondLevel: 12, eventSeed: 3)
        var state = exp.start(context: ctx)
        if case .companionWalk(var walk) = state.runtimeState {
            walk.lastPresentedBehavior = CompanionBehaviorState.follow.rawValue
            walk.movementSeconds = 40
            state = ExperienceSessionState(runtimeState: .companionWalk(walk))
        }

        let snapshot = MovementSnapshot(
            timestamp: Date(timeIntervalSince1970: 10_000),
            speed: 1.4,
            distanceDelta: 40,
            isMoving: true
        )
        let update = exp.updateForDemo(
            previousState: state,
            movement: snapshot,
            context: ctx,
            scheduledEventKind: .companionDrawsNear
        )
        XCTAssertEqual(update.semanticAudioCues.first?.kind, .companionNear)
        XCTAssertEqual(update.semanticAudioCues.first?.debugLabel, WorldEventKind.companionDrawsNear.rawValue)
        if case .companionWalk(let walk) = update.state.runtimeState {
            XCTAssertEqual(walk.lastPresentedBehavior, CompanionBehaviorState.drawNear.rawValue)
            XCTAssertEqual(walk.lastEvent?.kind, .companionDrawsNear)
        } else {
            XCTFail("Expected companion walk")
        }
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
