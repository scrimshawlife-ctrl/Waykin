import CoreLocation
import WaykinCore
import XCTest
@testable import WaykinApp

/// Issue #121: GPS/maps presentation surfaces — walked-path trace semantics
/// and GPS signal presentation.
final class SessionMapPresentationTests: XCTestCase {

    // MARK: Walked-path trace

    func testTraceDedupsPointsCloserThanSpacingFloor() {
        var trace = WalkPathTrace()
        trace.append(latitude: 37.0000, longitude: -122.0000)
        // ~1.1 m north — under the 4 m floor, must be ignored.
        trace.append(latitude: 37.00001, longitude: -122.0000)
        XCTAssertEqual(trace.count, 1)
        // ~11 m north — kept.
        trace.append(latitude: 37.0001, longitude: -122.0000)
        XCTAssertEqual(trace.count, 2)
    }

    func testTraceCapsAtMaxPointsDroppingOldest() {
        var trace = WalkPathTrace()
        // Each step ~11 m apart, well over the spacing floor.
        for step in 0..<(WalkPathTrace.maxPoints + 25) {
            trace.append(latitude: 37.0 + Double(step) * 0.0001, longitude: -122.0)
        }
        XCTAssertEqual(trace.count, WalkPathTrace.maxPoints)
        // Oldest dropped: the first kept point is no longer latitude 37.0.
        XCTAssertEqual(trace.points.first?.latitude ?? 0, 37.0 + 25 * 0.0001, accuracy: 1e-9)
        // Newest preserved.
        XCTAssertEqual(trace.points.last?.latitude ?? 0,
                       37.0 + Double(WalkPathTrace.maxPoints + 24) * 0.0001, accuracy: 1e-9)
    }

    func testTraceResetAndNonFiniteRejection() {
        var trace = WalkPathTrace()
        trace.append(latitude: 37, longitude: -122)
        trace.append(latitude: .nan, longitude: -122)
        trace.append(latitude: 37.001, longitude: .infinity)
        XCTAssertEqual(trace.count, 1, "non-finite fixes must never enter the trace")
        trace.reset()
        XCTAssertTrue(trace.isEmpty)
    }

    func testTraceSpacingApproximationIsSane() {
        let a = TracePoint(latitude: 37.0, longitude: -122.0)
        let b = TracePoint(latitude: 37.001, longitude: -122.0) // ~111 m
        XCTAssertEqual(WalkPathTrace.approximateMeters(from: a, to: b), 111.3, accuracy: 1.5)
    }

    // MARK: GPS signal presentation

    func testEverySignalStateHasDistinctHumanPresentation() {
        let states: [LiveLocationSignalState] = [
            .waitingForAuthorization, .waitingForFirstFix, .active,
            .degraded, .unavailable, .failed("CLError 17 kCLErrorDomain"),
        ]
        let presentations = states.map(GPSSignalPresentation.init)
        XCTAssertEqual(Set(presentations.map(\.label)).count, states.count,
                       "every state needs a distinct label")
        for presentation in presentations {
            XCTAssertFalse(presentation.label.isEmpty)
            XCTAssertFalse(presentation.accessibilityValue.isEmpty)
            XCTAssertTrue(presentation.accessibilityValue.hasSuffix("."))
        }
    }

    func testFailedStateNeverLeaksRawErrorText() {
        let presentation = GPSSignalPresentation(
            state: .failed("kCLErrorDomain error 17 /private/var/db/locationd"))
        XCTAssertEqual(presentation.label, "GPS error")
        XCTAssertFalse(presentation.accessibilityValue.contains("kCLErrorDomain"))
        XCTAssertFalse(presentation.accessibilityValue.contains("/private"))
        XCTAssertTrue(presentation.isProblem)
    }

    func testProblemFlagMatchesStateSeverity() {
        XCTAssertFalse(GPSSignalPresentation(state: .active).isProblem)
        XCTAssertFalse(GPSSignalPresentation(state: .waitingForFirstFix).isProblem)
        for state in [LiveLocationSignalState.degraded, .unavailable,
                      .waitingForAuthorization, .failed("x")] {
            XCTAssertTrue(GPSSignalPresentation(state: state).isProblem)
        }
    }

    // MARK: Map accessibility

    func testMapAccessibilityMentionsWalkedPathOnlyWithRealTrace() {
        var trace = WalkPathTrace()
        let waiting = CompactSessionMap(latitude: nil, longitude: nil, trace: trace)
        XCTAssertEqual(waiting.locationAccessibilityValue, "Waiting for a location update.")

        let located = CompactSessionMap(latitude: 37, longitude: -122, trace: trace)
        XCTAssertEqual(located.locationAccessibilityValue,
                       "Current location is available for this walk.")

        trace.append(latitude: 37.0, longitude: -122.0)
        trace.append(latitude: 37.0001, longitude: -122.0)
        let traced = CompactSessionMap(latitude: 37.0001, longitude: -122, trace: trace)
        XCTAssertEqual(traced.locationAccessibilityValue,
                       "Current location and the walked path so far are shown.")
        // Never coordinates in VoiceOver.
        XCTAssertFalse(traced.locationAccessibilityValue.contains("37"))
    }

    func testPlannedRouteSummaryOmitsCoordinates() {
        let route = PlannedWalkRoute(
            destinationName: "Park",
            destinationLatitude: 37.77,
            destinationLongitude: -122.42,
            polyline: [
                TracePoint(latitude: 37.77, longitude: -122.42),
                TracePoint(latitude: 37.78, longitude: -122.41)
            ],
            distanceMeters: 1500,
            expectedTravelTime: 900,
            status: .ready
        )
        XCTAssertTrue(route.isReady)
        XCTAssertTrue(route.summaryLabel.contains("Park"))
        XCTAssertTrue(route.summaryLabel.contains("1.5 km") || route.summaryLabel.contains("1500"))
        XCTAssertFalse(route.summaryLabel.contains("37.77"))
        XCTAssertFalse(route.accessibilitySummary.contains("37"))
        XCTAssertTrue(route.accessibilitySummary.contains("Park"))
    }

    func testRoutePlannerUsesInjectedDirections() async {
        final class FixtureDirections: WalkingRouteDirectionsProviding {
            func walkingRoute(
                from origin: CLLocationCoordinate2D,
                to destination: CLLocationCoordinate2D
            ) async throws -> (coordinates: [CLLocationCoordinate2D], distance: Double, travelTime: TimeInterval) {
                (
                    [
                        origin,
                        CLLocationCoordinate2D(
                            latitude: (origin.latitude + destination.latitude) / 2,
                            longitude: (origin.longitude + destination.longitude) / 2
                        ),
                        destination
                    ],
                    800,
                    600
                )
            }
        }
        let planner = WalkRoutePlanner(directions: FixtureDirections())
        let route = await planner.plan(
            from: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.42),
            to: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.41),
            destinationName: "Cafe"
        )
        XCTAssertEqual(route.status, .ready)
        XCTAssertEqual(route.destinationName, "Cafe")
        XCTAssertEqual(route.polyline.count, 3)
        XCTAssertEqual(route.distanceMeters, 800, accuracy: 0.1)
        XCTAssertEqual(route.expectedTravelTime, 600, accuracy: 0.1)
    }

    func testRoutePlannerFailsWithoutValidOrigin() async {
        let planner = WalkRoutePlanner(directions: FixtureAlwaysFail())
        let route = await planner.plan(
            from: kCLLocationCoordinate2DInvalid,
            to: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.41),
            destinationName: "X"
        )
        if case .failed = route.status {
            // expected
        } else {
            XCTFail("Expected failed status for invalid origin")
        }
    }
}

private final class FixtureAlwaysFail: WalkingRouteDirectionsProviding {
    func walkingRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> (coordinates: [CLLocationCoordinate2D], distance: Double, travelTime: TimeInterval) {
        throw WalkRoutePlanningError.noRoute
    }
}
