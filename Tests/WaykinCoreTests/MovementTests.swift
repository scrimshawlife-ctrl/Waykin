import XCTest
@testable import WaykinCore

final class MovementTests: XCTestCase {
    func testDistanceAccumulatesWhenMoving() {
        var engine = MovementEngine()
        var session = engine.startSession(activity: .walk, experienceID: "test")
        engine.simulateMovement(for: &session, deltaSeconds: 10, speed: 1.5)
        XCTAssertGreaterThan(session.distanceMeters, 10)
    }

    func testPausingStopsProgress() {
        var engine = MovementEngine()
        var session = engine.startSession(activity: .run, experienceID: "test")
        engine.simulateMovement(for: &session, deltaSeconds: 5, speed: 3.0)
        engine.pauseSession()
        let distBefore = session.distanceMeters
        engine.simulateMovement(for: &session, deltaSeconds: 10, speed: 3.0) // should not add much
        XCTAssertEqual(session.distanceMeters, distBefore, accuracy: 1.0)
    }

    func testSessionCompletes() {
        let engine = MovementEngine()
        var session = engine.startSession(activity: .walk, experienceID: "test")
        engine.simulateMovement(for: &session, deltaSeconds: 60, speed: 1.4)
        let ended = engine.endSession()
        XCTAssertNotNil(ended.endedAt)
    }
}