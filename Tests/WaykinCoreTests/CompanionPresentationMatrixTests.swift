import XCTest
@testable import WaykinCore

final class CompanionPresentationMatrixTests: XCTestCase {
    func testQuietIntervalIsRestEverywhere() {
        let resolved = CompanionPresentationMatrix.resolve(eventKind: .quietInterval)
        XCTAssertEqual(resolved.behavior, .rest)
        XCTAssertEqual(resolved.relativeDistance, 2.0, accuracy: 0.001)

        var runtime = CompanionRuntime()
        runtime.apply(event: WorldEvent(
            kind: .quietInterval,
            occurredAt: Date(timeIntervalSince1970: 1),
            intensity: 0.2,
            debugLabel: "quiet"
        ))
        XCTAssertEqual(runtime.state, .rest)
        XCTAssertEqual(runtime.relativeDistance, 2.0, accuracy: 0.001)

        XCTAssertEqual(
            CompanionPresentationMatrix.arBehaviorString(state: .rest, event: .quietInterval),
            "idle"
        )
    }

    func testLeadUsesFarDistanceAndFollowStringWithAheadSemantics() {
        let resolved = CompanionPresentationMatrix.resolve(eventKind: .companionMovesAhead)
        XCTAssertEqual(resolved.behavior, .lead)
        XCTAssertEqual(resolved.relativeDistance, 4.0, accuracy: 0.001)
        XCTAssertEqual(
            CompanionPresentationMatrix.arBehaviorString(state: .lead, event: .companionMovesAhead),
            "follow"
        )
    }

    func testBondMomentCelebrates() {
        XCTAssertEqual(
            CompanionPresentationMatrix.arBehaviorString(state: .drawNear, event: .bondMoment),
            "celebrate"
        )
        let r = CompanionPresentationMatrix.resolve(eventKind: .bondMoment)
        XCTAssertEqual(r.behavior, .drawNear)
        XCTAssertEqual(r.relativeDistance, 1.2, accuracy: 0.001)
    }

    func testNoEventMovingAndPaused() {
        let moving = CompanionPresentationMatrix.resolve(event: nil, moving: true)
        XCTAssertEqual(moving.behavior, .follow)
        XCTAssertEqual(moving.relativeDistance, 1.8, accuracy: 0.001)

        let paused = CompanionPresentationMatrix.resolve(event: nil, moving: false)
        XCTAssertEqual(paused.behavior, .observe)
        XCTAssertEqual(paused.relativeDistance, 2.5, accuracy: 0.001)
    }

    func testPathSoftBiasWhenPursuitQuiet() {
        XCTAssertEqual(
            CompanionPresentationMatrix.arBehaviorString(
                state: .follow,
                event: nil,
                pursuitState: .inactive,
                pathRelation: .strained
            ),
            "investigate"
        )
        XCTAssertEqual(
            CompanionPresentationMatrix.arBehaviorString(
                state: .follow,
                event: nil,
                pursuitState: .inactive,
                pathRelation: .offPath
            ),
            "alert"
        )
        // Pursuit drama wins over path.
        XCTAssertEqual(
            CompanionPresentationMatrix.arBehaviorString(
                state: .follow,
                event: .pursuitIntensifies,
                pursuitState: .close,
                pathRelation: .offPath
            ),
            "alert"
        )
        // Event quiet still idle, not path investigate.
        XCTAssertEqual(
            CompanionPresentationMatrix.arBehaviorString(
                state: .rest,
                event: .quietInterval,
                pursuitState: .inactive,
                pathRelation: .strained
            ),
            "idle"
        )
    }

    func testExperienceEmitsDistanceWithBehavior() {
        let exp = CompanionWalkExperience()
        let ctx = ExperienceContext(timeOfDay: TimeContext.midday.rawValue, activity: .walk, bondLevel: 2, eventSeed: 7)
        var state = exp.start(context: ctx)
        let snapshot = MovementSnapshot(
            timestamp: Date(timeIntervalSince1970: 50),
            speed: 1.5,
            distanceDelta: 5,
            isMoving: true
        )
        let update = exp.updateForDemo(
            previousState: state,
            movement: snapshot,
            context: ctx,
            scheduledEventKind: .companionMovesAhead
        )
        XCTAssertTrue(update.companionCommands.contains {
            if case .setBehavior(let b) = $0 { return b == CompanionBehaviorState.lead.rawValue }
            return false
        })
        XCTAssertTrue(update.companionCommands.contains {
            if case .setRelativeDistance(let d) = $0 { return abs(d - 4.0) < 0.001 }
            return false
        })

        var runtime = CompanionRuntime()
        update.companionCommands.forEach { runtime.apply(command: $0) }
        XCTAssertEqual(runtime.state, .lead)
        XCTAssertEqual(runtime.relativeDistance, 4.0, accuracy: 0.001)

        // No-event pause updates distance without freezing last event band.
        state = update.state
        if case .companionWalk(var walk) = state.runtimeState {
            walk.lastEvent = nil
            state = ExperienceSessionState(runtimeState: .companionWalk(walk))
        }
        let pause = MovementSnapshot(
            timestamp: Date(timeIntervalSince1970: 60),
            speed: 0,
            distanceDelta: 0,
            isMoving: false
        )
        let pauseUpdate = exp.updateForDemo(
            previousState: state,
            movement: pause,
            context: ctx,
            scheduledEventKind: nil
        )
        XCTAssertTrue(pauseUpdate.companionCommands.contains {
            if case .setRelativeDistance(let d) = $0 { return abs(d - 2.5) < 0.001 }
            return false
        })
    }
}
