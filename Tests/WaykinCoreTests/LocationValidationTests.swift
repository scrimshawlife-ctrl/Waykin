import XCTest
@testable import WaykinCore

final class LocationValidationTests: XCTestCase {
    private let originLatitude = 37.7749
    private let originLongitude = -122.4194

    func testAccuracyAndTimestampValidationRejectsUnsafeSamples() {
        let now = Date(timeIntervalSince1970: 1_000)
        var processor = MovementIntegrityProcessor()

        XCTAssertEqual(
            processor.process(sample(at: now, accuracy: -1), receivedAt: now).diagnostic.disposition,
            .rejectedNegativeAccuracy
        )
        XCTAssertEqual(
            processor.process(sample(at: now, accuracy: 31), receivedAt: now).diagnostic.disposition,
            .rejectedAccuracy
        )
        XCTAssertEqual(
            processor.process(sample(at: now.addingTimeInterval(-16)), receivedAt: now).diagnostic.disposition,
            .rejectedStale
        )
        XCTAssertEqual(
            processor.process(sample(at: now.addingTimeInterval(3)), receivedAt: now).diagnostic.disposition,
            .rejectedInvalid
        )
    }

    func testDuplicateOutOfOrderAndImplausibleSamplesAreRejected() {
        let now = Date(timeIntervalSince1970: 2_000)
        var processor = MovementIntegrityProcessor()
        XCTAssertEqual(processor.process(sample(at: now), receivedAt: now).diagnostic.disposition, .awaitingFreshAnchor)
        XCTAssertEqual(processor.process(sample(at: now), receivedAt: now).diagnostic.disposition, .rejectedDuplicate)
        XCTAssertEqual(
            processor.process(sample(at: now.addingTimeInterval(-1)), receivedAt: now).diagnostic.disposition,
            .rejectedOutOfOrder
        )
        XCTAssertEqual(
            processor.process(sample(at: now.addingTimeInterval(1), northMeters: 100), receivedAt: now.addingTimeInterval(1)).diagnostic.disposition,
            .rejectedImplausibleDisplacement
        )
    }

    func testNegativeReportedSpeedFallsBackToDistanceOverTime() {
        let now = Date(timeIntervalSince1970: 3_000)
        var processor = MovementIntegrityProcessor(
            configuration: MovementIntegrityConfiguration(speedWindowSize: 1)
        )
        _ = processor.process(sample(at: now, speed: -1), receivedAt: now)
        let result = processor.process(
            sample(at: now.addingTimeInterval(2), northMeters: 2, speed: -1),
            receivedAt: now.addingTimeInterval(2)
        )

        XCTAssertEqual(result.diagnostic.disposition, .accepted)
        XCTAssertEqual(result.diagnostic.derivedSpeedMetersPerSecond, 1, accuracy: 0.08)
        XCTAssertTrue(result.isMoving)
    }

    func testMovementHysteresisAvoidsSingleLowSpeedStateFlip() {
        let now = Date(timeIntervalSince1970: 4_000)
        var processor = MovementIntegrityProcessor(
            configuration: MovementIntegrityConfiguration(speedWindowSize: 3)
        )
        _ = processor.process(sample(at: now), receivedAt: now)
        let moving = processor.process(
            sample(at: now.addingTimeInterval(1), northMeters: 1, speed: 0.8),
            receivedAt: now.addingTimeInterval(1)
        )
        let noisyLow = processor.process(
            sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 0.1),
            receivedAt: now.addingTimeInterval(2)
        )

        XCTAssertTrue(moving.isMoving)
        XCTAssertTrue(noisyLow.isMoving)
    }

    func testEngineAccumulatesOnlyAcceptedMovingDistanceAndTime() throws {
        let now = Date(timeIntervalSince1970: 5_000)
        let clock = TestClock(now: now)
        let engine = MovementEngine(
            clock: clock,
            integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1)
        )
        try engine.startSession(activity: .walk, experienceID: "companion_walk")
        try engine.resumeSession()

        XCTAssertNil(engine.ingestRealLocationSample(sample(at: now), receivedAt: now).snapshot)
        let result = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 1),
            receivedAt: now.addingTimeInterval(2)
        )

        XCTAssertEqual(result.snapshot?.distanceDelta ?? -1, 2, accuracy: 0.08)
        XCTAssertEqual(engine.currentSession?.distanceMeters ?? -1, 2, accuracy: 0.08)
        XCTAssertEqual(engine.currentSession?.elapsedTime, 2)
        XCTAssertEqual(engine.currentSession?.activeTime, 2)
        XCTAssertEqual(engine.currentSession?.averageSpeedMetersPerSecond ?? -1, 1, accuracy: 0.08)
    }

    func testStationaryJitterDoesNotAccumulateDistance() throws {
        let now = Date(timeIntervalSince1970: 6_000)
        let engine = MovementEngine(integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1))
        try engine.startSession(activity: .walk, experienceID: "companion_walk")
        try engine.resumeSession()
        _ = engine.ingestRealLocationSample(sample(at: now), receivedAt: now)
        let result = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(2), northMeters: 0.4, speed: 0.1),
            receivedAt: now.addingTimeInterval(2)
        )

        XCTAssertEqual(result.snapshot?.distanceDelta, 0)
        XCTAssertEqual(engine.currentSession?.distanceMeters, 0)
        XCTAssertEqual(engine.currentSession?.activeTime, 0)
    }

    func testPauseRejectsSamplesAndResumeRequiresFreshAnchor() throws {
        let now = Date(timeIntervalSince1970: 7_000)
        let engine = MovementEngine(integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1))
        try engine.startSession(activity: .walk, experienceID: "companion_walk")
        try engine.resumeSession()
        _ = engine.ingestRealLocationSample(sample(at: now), receivedAt: now)
        _ = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 1),
            receivedAt: now.addingTimeInterval(2)
        )
        let distanceBeforePause = engine.currentSession?.distanceMeters

        try engine.pauseSession()
        let paused = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(4), northMeters: 50, speed: 1),
            receivedAt: now.addingTimeInterval(4)
        )
        XCTAssertEqual(paused.diagnostic.disposition, .rejectedPaused)
        XCTAssertEqual(engine.currentSession?.distanceMeters, distanceBeforePause)

        try engine.resumeSession()
        let freshAnchor = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(5), northMeters: 50, speed: 1),
            receivedAt: now.addingTimeInterval(5)
        )
        XCTAssertEqual(freshAnchor.diagnostic.disposition, .awaitingFreshAnchor)
        XCTAssertNil(freshAnchor.snapshot)
        XCTAssertEqual(engine.currentSession?.distanceMeters, distanceBeforePause)
    }

    func testRejectedSampleDoesNotMutateSessionOrCreateSnapshot() throws {
        let now = Date(timeIntervalSince1970: 8_000)
        let engine = MovementEngine()
        try engine.startSession(activity: .walk, experienceID: "companion_walk")
        try engine.resumeSession()
        _ = engine.ingestRealLocationSample(sample(at: now), receivedAt: now)
        let before = engine.currentSession?.routePoints

        let result = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(1), northMeters: 100),
            receivedAt: now.addingTimeInterval(1)
        )

        XCTAssertNil(result.snapshot)
        XCTAssertEqual(result.diagnostic.disposition, .rejectedImplausibleDisplacement)
        XCTAssertEqual(engine.currentSession?.routePoints, before)
    }

    func testLifecycleTransitionsRejectDuplicatesAndConcurrentSessions() throws {
        let engine = MovementEngine()
        try engine.startSession(activity: .walk, experienceID: "companion_walk")
        XCTAssertThrowsError(try engine.startSession(activity: .walk, experienceID: "companion_walk"))
        XCTAssertThrowsError(try engine.pauseSession()) { error in
            XCTAssertEqual(error as? MovementError, .invalidTransition(from: .idle, to: .paused))
        }
        try engine.resumeSession()
        XCTAssertThrowsError(try engine.resumeSession()) { error in
            XCTAssertEqual(error as? MovementError, .invalidTransition(from: .moving, to: .moving))
        }
        try engine.pauseSession()
        XCTAssertThrowsError(try engine.pauseSession()) { error in
            XCTAssertEqual(error as? MovementError, .invalidTransition(from: .paused, to: .paused))
        }
        _ = try engine.endSession()
        XCTAssertThrowsError(try engine.endSession())
    }

    func testStoppedEngineRejectsWithoutSessionMutation() {
        let now = Date(timeIntervalSince1970: 9_000)
        let engine = MovementEngine()
        let result = engine.ingestRealLocationSample(sample(at: now), receivedAt: now)
        XCTAssertEqual(result.diagnostic.disposition, .rejectedStopped)
        XCTAssertNil(result.snapshot)
        XCTAssertNil(engine.currentSession)
    }

    func testCompletionFreezesFinalMovementValues() throws {
        let now = Date(timeIntervalSince1970: 10_000)
        let engine = MovementEngine(integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1))
        try engine.startSession(activity: .walk, experienceID: "companion_walk")
        try engine.resumeSession()
        _ = engine.ingestRealLocationSample(sample(at: now), receivedAt: now)
        _ = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 1),
            receivedAt: now.addingTimeInterval(2)
        )

        let completed = try engine.endSession()
        let afterEnd = engine.ingestRealLocationSample(
            sample(at: now.addingTimeInterval(4), northMeters: 4, speed: 1),
            receivedAt: now.addingTimeInterval(4)
        )

        XCTAssertEqual(afterEnd.diagnostic.disposition, .rejectedStopped)
        XCTAssertNil(afterEnd.snapshot)
        XCTAssertEqual(completed.distanceMeters, 2, accuracy: 0.08)
        XCTAssertEqual(completed.activeTime, 2)
        XCTAssertEqual(completed.elapsedTime, 2)
    }

    func testRealAndDemoSnapshotsShareTheSameDownstreamContract() throws {
        let now = Date(timeIntervalSince1970: 11_000)
        let engine = MovementEngine(integrityConfiguration: MovementIntegrityConfiguration(speedWindowSize: 1))
        try engine.startSession(activity: .walk, experienceID: "companion_walk")
        try engine.resumeSession()
        _ = engine.ingestRealLocationSample(sample(at: now), receivedAt: now)
        let realSnapshot = try XCTUnwrap(
            engine.ingestRealLocationSample(
                sample(at: now.addingTimeInterval(2), northMeters: 2, speed: 1),
                receivedAt: now.addingTimeInterval(2)
            ).snapshot
        )
        let demoSnapshot = MovementSnapshot(
            timestamp: realSnapshot.timestamp,
            speed: realSnapshot.speed,
            distanceDelta: realSnapshot.distanceDelta,
            isMoving: realSnapshot.isMoving
        )
        let experience = CompanionWalkExperience()
        let context = ExperienceContext(timeOfDay: "day", activity: .walk, bondLevel: 12, eventSeed: 42)
        let initialState = experience.start(context: context)

        let realUpdate = experience.update(previousState: initialState, movement: realSnapshot, context: context)
        let demoUpdate = experience.update(previousState: initialState, movement: demoSnapshot, context: context)

        XCTAssertEqual(realUpdate.state.runtimeState, demoUpdate.state.runtimeState)
        XCTAssertEqual(realUpdate.audioCues, demoUpdate.audioCues)
        XCTAssertEqual(realUpdate.narrativeEvents, demoUpdate.narrativeEvents)
        XCTAssertEqual(realUpdate.rewardEvents, demoUpdate.rewardEvents)
    }

    private func sample(
        at timestamp: Date,
        northMeters: Double = 0,
        accuracy: Double = 5,
        speed: Double = 0
    ) -> LocationSample {
        LocationSample(
            timestamp: timestamp,
            latitude: originLatitude + northMeters / 111_111,
            longitude: originLongitude,
            altitude: 10,
            horizontalAccuracy: accuracy,
            reportedSpeedMetersPerSecond: speed
        )
    }
}

private final class TestClock: ClockProviding {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}
