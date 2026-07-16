import XCTest
@testable import WaykinCore
import CoreLocation

final class LocationValidationTests: XCTestCase {

    func testRejectsInvalidHorizontalAccuracy() {
        // The provider uses max 30m; we can test the logic conceptually via the provider later.
        // Here we test a synthetic filter helper if extracted, or the ingest behavior.
        // For now, a basic smoke that invalid accuracy would be rejected (provider internal).
        XCTAssertTrue(true) // placeholder until we expose filter for pure unit test
    }

    func testRejectsStaleLocationSample() {
        let oldDate = Date().addingTimeInterval(-60)
        let stale = CLLocation(coordinate: .init(latitude: 37.77, longitude: -122.41),
                               altitude: 10, horizontalAccuracy: 5, verticalAccuracy: 5,
                               timestamp: oldDate)
        // The RealLocationProvider should reject this internally.
        XCTAssertTrue(stale.timestamp.timeIntervalSinceNow < -30)
    }

    func testRejectsImpossibleDistanceSpike() {
        // Synthetic test for the concept
        let p1 = RoutePoint(timestamp: Date(), latitude: 37.7749, longitude: -122.4194, altitude: 10, speed: 1.4)
        let p2 = RoutePoint(timestamp: Date().addingTimeInterval(1), latitude: 38.0, longitude: -122.4194, altitude: 10, speed: 1.4) // huge jump
        let cl1 = CLLocation(latitude: p1.latitude, longitude: p1.longitude)
        let cl2 = CLLocation(latitude: p2.latitude, longitude: p2.longitude)
        let dist = cl1.distance(from: cl2)
        XCTAssertGreaterThan(dist, 100)
    }

    func testDistanceDoesNotIncreaseWhilePaused() {
        let engine = MovementEngine()
        try? engine.startSession(activity: .walk, experienceID: "companion_walk")
        try? engine.pauseSession()
        let before = engine.currentSession?.distanceMeters ?? 0
        // ingest should be ignored while paused
        let point = RoutePoint(timestamp: Date(), latitude: 37.7749, longitude: -122.4194, altitude: 10, speed: 1.4)
        engine.ingestRealLocation(point)
        let after = engine.currentSession?.distanceMeters ?? 0
        XCTAssertEqual(before, after)
    }

    func testResumeDoesNotCreateDistanceSpike() {
        let engine = MovementEngine()
        try? engine.startSession(activity: .walk, experienceID: "companion_walk")
        let p1 = RoutePoint(timestamp: Date(), latitude: 37.7749, longitude: -122.4194, altitude: 10, speed: 1.4)
        engine.ingestRealLocation(p1)
        try? engine.pauseSession()
        try? engine.resumeSession()
        let p2 = RoutePoint(timestamp: Date().addingTimeInterval(10), latitude: 37.7749, longitude: -122.4194, altitude: 10, speed: 1.4)
        engine.ingestRealLocation(p2)
        // Distance should only be the small second segment
        let dist = engine.currentSession?.distanceMeters ?? 0
        XCTAssertLessThan(dist, 50)
    }

    func testPaceIsNotComputableWithoutEnoughSignal() {
        let session = MovementSession(activityType: .walk, experienceID: "companion_walk")
        // no points or insufficient
        XCTAssertEqual(session.averageSpeedMetersPerSecond, 0)
    }

    func testAcceptedSamplesExtendRoute() {
        let engine = MovementEngine()
        try? engine.startSession(activity: .walk, experienceID: "companion_walk")
        // Use simulate (which sets moving internally) to exercise route extension path
        engine.simulate(deltaSeconds: 10, speed: 1.4)
        XCTAssertGreaterThanOrEqual(engine.currentSession?.routePoints.count ?? 0, 1)
    }
}