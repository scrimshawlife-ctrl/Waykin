import XCTest
@testable import WaykinCore

final class PathProgressEngineTests: XCTestCase {
    func testResetEstablishesDemoFlag() {
        let engine = PathProgressEngine()
        engine.reset(isDemo: true)
        XCTAssertEqual(engine.snapshot.relation, .establishing)
        XCTAssertTrue(engine.snapshot.isDemo)
        XCTAssertEqual(engine.snapshot.metersAlongPath, 0)
    }

    func testAcceptedMovingProgressAdvancesOnPath() {
        let engine = PathProgressEngine()
        engine.reset(isDemo: false)
        let t0 = Date(timeIntervalSince1970: 1_000)
        engine.recordAccepted(MovementSnapshot(timestamp: t0, speed: 1.2, distanceDelta: 2, isMoving: true))
        XCTAssertEqual(engine.snapshot.relation, .establishing)
        engine.recordAccepted(MovementSnapshot(timestamp: t0.addingTimeInterval(1), speed: 1.3, distanceDelta: 2, isMoving: true))
        XCTAssertEqual(engine.snapshot.relation, .onPath)
        XCTAssertEqual(engine.snapshot.metersAlongPath, 4, accuracy: 0.001)
        XCTAssertEqual(engine.snapshot.integrityPressure, 0, accuracy: 0.001)
    }

    func testRejectStreakMovesToStrainedThenOffPath() {
        let engine = PathProgressEngine()
        engine.reset(isDemo: false)
        let t = Date(timeIntervalSince1970: 2_000)
        engine.recordAccepted(MovementSnapshot(timestamp: t, speed: 1, distanceDelta: 2, isMoving: true))
        engine.recordAccepted(MovementSnapshot(timestamp: t.addingTimeInterval(1), speed: 1, distanceDelta: 2, isMoving: true))
        XCTAssertEqual(engine.snapshot.relation, .onPath)

        for _ in 0..<3 { engine.recordRejected() }
        XCTAssertEqual(engine.snapshot.relation, .strained)
        XCTAssertGreaterThan(engine.snapshot.integrityPressure, 0.3)

        for _ in 0..<5 { engine.recordRejected() }
        XCTAssertEqual(engine.snapshot.relation, .offPath)
        XCTAssertGreaterThanOrEqual(engine.snapshot.integrityPressure, 0.75)
    }

    func testRecoveryFromOffPathRequiresMovingAccepts() {
        let engine = PathProgressEngine()
        engine.reset(isDemo: true)
        let t = Date(timeIntervalSince1970: 3_000)
        engine.recordAccepted(MovementSnapshot(timestamp: t, speed: 1, distanceDelta: 1, isMoving: true))
        engine.recordAccepted(MovementSnapshot(timestamp: t.addingTimeInterval(1), speed: 1, distanceDelta: 1, isMoving: true))
        for _ in 0..<8 { engine.recordRejected() }
        XCTAssertEqual(engine.snapshot.relation, .offPath)

        engine.recordAccepted(MovementSnapshot(timestamp: t.addingTimeInterval(10), speed: 1.1, distanceDelta: 1.5, isMoving: true))
        XCTAssertEqual(engine.snapshot.relation, .recovered)
        engine.recordAccepted(MovementSnapshot(timestamp: t.addingTimeInterval(11), speed: 1.1, distanceDelta: 1.5, isMoving: true))
        XCTAssertEqual(engine.snapshot.relation, .onPath)
    }

    func testPressureHelpersAreBounded() {
        for relation in PathRelation.allCases {
            for streak in [0, 3, 8, 20] {
                let p = PathProgressEngine.pressure(
                    relation: relation,
                    rejectedStreak: streak,
                    consecutiveStationary: streak
                )
                XCTAssertGreaterThanOrEqual(p, 0)
                XCTAssertLessThanOrEqual(p, 1)
            }
        }
    }
}
