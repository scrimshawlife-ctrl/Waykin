import XCTest
@testable import WaykinCore

final class MovementTests: XCTestCase {
    func testDistanceAccumulatesWhenMoving() throws {
        let engine = MovementEngine()
        try engine.startSession(activity: .walk, experienceID: "test")
        engine.simulate(deltaSeconds: 10, speed: 1.5)
        guard let session = engine.currentSession else { XCTFail(); return }
        XCTAssertGreaterThan(session.distanceMeters, 10)
    }

    func testPausingStopsProgress() throws {
        let engine = MovementEngine()
        try engine.startSession(activity: .run, experienceID: "test")
        engine.simulate(deltaSeconds: 5, speed: 3.0)
        try engine.pauseSession()
        guard let session1 = engine.currentSession else { XCTFail(); return }
        let distBefore = session1.distanceMeters
        engine.simulate(deltaSeconds: 10, speed: 3.0)
        guard let session2 = engine.currentSession else { XCTFail(); return }
        XCTAssertEqual(session2.distanceMeters, distBefore, accuracy: 1.0)
    }

    func testSessionCompletes() throws {
        let engine = MovementEngine()
        try engine.startSession(activity: .walk, experienceID: "test")
        engine.simulate(deltaSeconds: 60, speed: 1.4)
        let ended = try engine.endSession()
        XCTAssertNotNil(ended.endedAt)
    }

    func testEndWithoutSessionThrows() {
        let engine = MovementEngine()
        XCTAssertThrowsError(try engine.endSession()) { error in
            XCTAssertEqual(error as? MovementError, MovementError.noActiveSession)
        }
    }
}