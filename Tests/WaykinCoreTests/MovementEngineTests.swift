import XCTest
@testable import WaykinCore

final class MovementEngineTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    /// Walk due north at a constant speed, one fix per `interval` seconds.
    func makeRoute(speed: Double, seconds: Int, interval: Int = 5) -> [MovementSample] {
        var coordinate = GeoCoordinate(latitude: 37.0, longitude: -122.0)
        var samples = [MovementSample(coordinate: coordinate, timestamp: start)]
        for t in stride(from: interval, through: seconds, by: interval) {
            coordinate.latitude += (speed * Double(interval)) / 111_111
            samples.append(MovementSample(coordinate: coordinate, timestamp: start.addingTimeInterval(TimeInterval(t))))
        }
        return samples
    }

    func testHaversineKnownDistance() {
        // ~1 degree of latitude ≈ 111.19 km
        let a = GeoCoordinate(latitude: 37.0, longitude: -122.0)
        let b = GeoCoordinate(latitude: 38.0, longitude: -122.0)
        XCTAssertEqual(a.distance(to: b), 111_195, accuracy: 300)
    }

    func testSessionAccumulatesDistanceAndPace() {
        let tracker = MovementSessionTracker(activity: .walking, startedAt: start)
        for sample in makeRoute(speed: 1.4, seconds: 600) {
            tracker.record(sample)
        }
        let session = tracker.end(at: start.addingTimeInterval(600))
        XCTAssertEqual(session.distanceMeters, 840, accuracy: 10) // 1.4 m/s × 600 s
        XCTAssertEqual(session.durationSeconds, 600, accuracy: 0.01)
        let pace = try! XCTUnwrap(session.averagePaceSecondsPerKm)
        XCTAssertEqual(pace, 714, accuracy: 15) // ~11:54 per km
    }

    func testActivityAutoDetection() {
        let walker = MovementSessionTracker(activity: nil, startedAt: start)
        for sample in makeRoute(speed: 1.4, seconds: 300) { walker.record(sample) }
        XCTAssertEqual(walker.end(at: start.addingTimeInterval(300)).activity, .walking)

        let runner = MovementSessionTracker(activity: nil, startedAt: start)
        for sample in makeRoute(speed: 3.0, seconds: 300) { runner.record(sample) }
        XCTAssertEqual(runner.end(at: start.addingTimeInterval(300)).activity, .running)
    }

    func testStopDetection() {
        let tracker = MovementSessionTracker(activity: .walking, startedAt: start)
        var lastUpdate: MovementUpdate?
        for sample in makeRoute(speed: 1.4, seconds: 60) {
            lastUpdate = tracker.record(sample) ?? lastUpdate
        }
        XCTAssertEqual(lastUpdate?.isMoving, true)

        // Same coordinate 30 s later → stopped.
        let stopped = tracker.record(MovementSample(
            coordinate: lastUpdate!.coordinate,
            timestamp: start.addingTimeInterval(90)))
        XCTAssertEqual(stopped?.isMoving, false)
    }

    func testRejectsGPSNoiseAndOutOfOrderSamples() {
        let tracker = MovementSessionTracker(activity: .walking, startedAt: start)
        tracker.record(MovementSample(coordinate: GeoCoordinate(latitude: 37.0, longitude: -122.0), timestamp: start))

        // Teleport 5 km in 5 s → implausible, rejected.
        let jump = tracker.record(MovementSample(
            coordinate: GeoCoordinate(latitude: 37.045, longitude: -122.0),
            timestamp: start.addingTimeInterval(5)))
        XCTAssertNil(jump)

        // Timestamp going backwards → rejected.
        let backwards = tracker.record(MovementSample(
            coordinate: GeoCoordinate(latitude: 37.0001, longitude: -122.0),
            timestamp: start.addingTimeInterval(-5)))
        XCTAssertNil(backwards)

        let session = tracker.end(at: start.addingTimeInterval(10))
        XCTAssertEqual(session.distanceMeters, 0, accuracy: 0.001)
    }
}
