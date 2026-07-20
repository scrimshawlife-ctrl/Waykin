import CoreLocation
import Foundation
import MapKit

// Issue #155: presentation-only walking route guide. Does not own movement
// integrity, events, Bond, or navigation voice. Coordinates never enter
// VoiceOver strings or field receipts.

/// Status of a session planned walk route.
enum PlannedWalkRouteStatus: Equatable, Sendable {
    case none
    case searching
    case ready
    case failed(String)
}

/// Ephemeral planned route for the active session (not persisted).
struct PlannedWalkRoute: Equatable, Sendable {
    var destinationName: String
    var destinationLatitude: Double
    var destinationLongitude: Double
    var polyline: [TracePoint]
    var distanceMeters: Double
    var expectedTravelTime: TimeInterval
    var status: PlannedWalkRouteStatus

    static let empty = PlannedWalkRoute(
        destinationName: "",
        destinationLatitude: 0,
        destinationLongitude: 0,
        polyline: [],
        distanceMeters: 0,
        expectedTravelTime: 0,
        status: .none
    )

    var isReady: Bool { status == .ready && polyline.count >= 2 }

    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }

    /// Human summary for chrome (no raw coordinates).
    var summaryLabel: String {
        switch status {
        case .none:
            return "No route"
        case .searching:
            return "Planning route…"
        case .ready:
            let km = distanceMeters / 1000
            let minutes = max(1, Int((expectedTravelTime / 60).rounded()))
            let distanceText: String
            if distanceMeters < 1000 {
                distanceText = "\(Int(distanceMeters.rounded())) m"
            } else {
                distanceText = String(format: "%.1f km", km)
            }
            let name = destinationName.isEmpty ? "Destination" : destinationName
            return "\(name) · \(distanceText) · ~\(minutes) min"
        case .failed(let message):
            return message
        }
    }

    var accessibilitySummary: String {
        switch status {
        case .none:
            return "No walking route set."
        case .searching:
            return "Planning a walking route."
        case .ready:
            let minutes = max(1, Int((expectedTravelTime / 60).rounded()))
            let meters = max(0, Int(distanceMeters.rounded()))
            let name = destinationName.isEmpty ? "your destination" : destinationName
            return "Walking route to \(name), about \(meters) meters, about \(minutes) minutes."
        case .failed(let message):
            return message
        }
    }

    /// Prefix of polyline for draw-on reveal (progress 0…1).
    func revealedPolyline(progress: Double) -> [TracePoint] {
        let count = LiraSessionMotion.routeRevealPointCount(total: polyline.count, progress: progress)
        guard count > 0 else { return [] }
        return Array(polyline.prefix(count))
    }
}

/// Place search hit for route destination UI.
struct WalkRoutePlaceHit: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Abstraction over MapKit directions so tests can inject fixtures.
protocol WalkingRouteDirectionsProviding: AnyObject {
    func walkingRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> (coordinates: [CLLocationCoordinate2D], distance: Double, travelTime: TimeInterval)
}

enum WalkRoutePlanningError: Error, Equatable {
    case noRoute
    case invalidCoordinates
    case underlying(String)
}

final class MapKitWalkingDirections: WalkingRouteDirectionsProviding {
    func walkingRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> (coordinates: [CLLocationCoordinate2D], distance: Double, travelTime: TimeInterval) {
        guard CLLocationCoordinate2DIsValid(origin), CLLocationCoordinate2DIsValid(destination) else {
            throw WalkRoutePlanningError.invalidCoordinates
        }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        let response: MKDirections.Response
        do {
            response = try await directions.calculate()
        } catch {
            throw WalkRoutePlanningError.underlying(error.localizedDescription)
        }
        guard let route = response.routes.first else {
            throw WalkRoutePlanningError.noRoute
        }
        let coords = Self.coordinates(from: route.polyline)
        guard coords.count >= 2 else { throw WalkRoutePlanningError.noRoute }
        return (coords, route.distance, route.expectedTravelTime)
    }

    private static func coordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var coords = Array(repeating: kCLLocationCoordinate2DInvalid, count: polyline.pointCount)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
        return coords.filter { CLLocationCoordinate2DIsValid($0) }
    }
}

final class WalkRoutePlanner: @unchecked Sendable {
    private let directions: any WalkingRouteDirectionsProviding

    init(directions: (any WalkingRouteDirectionsProviding)? = nil) {
        self.directions = directions ?? MapKitWalkingDirections()
    }

    func plan(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        destinationName: String
    ) async -> PlannedWalkRoute {
        guard CLLocationCoordinate2DIsValid(origin), CLLocationCoordinate2DIsValid(destination) else {
            return PlannedWalkRoute(
                destinationName: destinationName,
                destinationLatitude: destination.latitude,
                destinationLongitude: destination.longitude,
                polyline: [],
                distanceMeters: 0,
                expectedTravelTime: 0,
                status: .failed("Need a valid location to plan a route.")
            )
        }
        do {
            let result = try await directions.walkingRoute(from: origin, to: destination)
            let points = result.coordinates.map {
                TracePoint(latitude: $0.latitude, longitude: $0.longitude)
            }
            return PlannedWalkRoute(
                destinationName: destinationName,
                destinationLatitude: destination.latitude,
                destinationLongitude: destination.longitude,
                polyline: points,
                distanceMeters: result.distance,
                expectedTravelTime: result.travelTime,
                status: .ready
            )
        } catch WalkRoutePlanningError.noRoute {
            return failed(name: destinationName, destination: destination, message: "No walking route found.")
        } catch WalkRoutePlanningError.invalidCoordinates {
            return failed(name: destinationName, destination: destination, message: "Need a valid location to plan a route.")
        } catch {
            return failed(name: destinationName, destination: destination, message: "Could not plan a walking route.")
        }
    }

    func searchPlaces(query: String, near center: CLLocationCoordinate2D) async -> [WalkRoutePlaceHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if CLLocationCoordinate2DIsValid(center) {
            request.region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.prefix(12).compactMap { item in
                let coord = item.placemark.coordinate
                guard CLLocationCoordinate2DIsValid(coord) else { return nil }
                let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let name, !name.isEmpty else { return nil }
                let subtitle = [
                    item.placemark.locality,
                    item.placemark.administrativeArea
                ]
                .compactMap { $0 }
                .joined(separator: ", ")
                return WalkRoutePlaceHit(
                    id: "\(name)|\(coord.latitude)|\(coord.longitude)",
                    name: name,
                    subtitle: subtitle,
                    latitude: coord.latitude,
                    longitude: coord.longitude
                )
            }
        } catch {
            return []
        }
    }

    private func failed(
        name: String,
        destination: CLLocationCoordinate2D,
        message: String
    ) -> PlannedWalkRoute {
        PlannedWalkRoute(
            destinationName: name,
            destinationLatitude: destination.latitude,
            destinationLongitude: destination.longitude,
            polyline: [],
            distanceMeters: 0,
            expectedTravelTime: 0,
            status: .failed(message)
        )
    }
}
