import Foundation
import CoreLocation

public enum LocationRejectionReason: String, Equatable {
    case invalidAccuracy
    case staleTimestamp
    case nonfiniteCoordinate
    case speedSpike
    case distanceSpike
    case duplicate
}

public enum LocationSampleDisposition: Equatable {
    case accepted
    case rejected(LocationRejectionReason)
}

public final class RealLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {
    public var onLocationUpdate: ((RoutePoint) -> Void)?
    public var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    public var onSignalStateChange: ((LiveLocationSignalState) -> Void)?

    private let manager = CLLocationManager()
    private var lastAcceptedPoint: RoutePoint?
    private var lastUpdateTime: Date?
    private let maxHorizontalAccuracy: Double = 30.0   // meters for walking
    private let maxSpeedSpike: Double = 5.0             // m/s (~18 km/h) for walking validation
    private let minDistanceDelta: Double = 1.5          // meters

    public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public private(set) var signalState: LiveLocationSignalState = .waitingForAuthorization
    public private(set) var acceptedCount: Int = 0
    public private(set) var rejectedCount: Int = 0
    public private(set) var lastRejection: LocationRejectionReason?

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 2
        manager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - LocationProviding

    public func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    public func startUpdatingLocation() {
        manager.startUpdatingLocation()
        updateSignal(.waitingForFirstFix)
    }

    public func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        onAuthorizationChange?(authorizationStatus)

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            updateSignal(.waitingForFirstFix)
        case .denied, .restricted:
            updateSignal(.unavailable)
        case .notDetermined:
            updateSignal(.waitingForAuthorization)
        @unknown default:
            updateSignal(.failed("unknown auth"))
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let cl = locations.last else { return }

        let disposition = validateSample(cl)

        switch disposition {
        case .accepted:
            let point = RoutePoint(
                timestamp: cl.timestamp,
                latitude: cl.coordinate.latitude,
                longitude: cl.coordinate.longitude,
                altitude: cl.altitude,
                speed: max(cl.speed, 0)
            )

            // Basic de-dupe / small jump guard
            if let last = lastAcceptedPoint {
                let clLast = CLLocation(latitude: last.latitude, longitude: last.longitude)
                let dist = clLast.distance(from: CLLocation(latitude: point.latitude, longitude: point.longitude))
                if dist < minDistanceDelta {
                    recordRejection(.duplicate)
                    return
                }
            }

            lastAcceptedPoint = point
            lastUpdateTime = Date()
            acceptedCount += 1
            updateSignal(.active)
            onLocationUpdate?(point)

        case .rejected(let reason):
            recordRejection(reason)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        updateSignal(.failed(error.localizedDescription))
    }

    // MARK: - Validation

    private func validateSample(_ cl: CLLocation) -> LocationSampleDisposition {
        if cl.horizontalAccuracy < 0 || cl.horizontalAccuracy > maxHorizontalAccuracy {
            return .rejected(.invalidAccuracy)
        }
        if !cl.coordinate.latitude.isFinite || !cl.coordinate.longitude.isFinite {
            return .rejected(.nonfiniteCoordinate)
        }
        if cl.speed < 0 || !cl.speed.isFinite {
            return .rejected(.nonfiniteCoordinate)
        }
        if cl.timestamp.timeIntervalSinceNow < -30 {   // stale > 30s
            return .rejected(.staleTimestamp)
        }

        if let last = lastAcceptedPoint {
            let clLast = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let dist = clLast.distance(from: cl)
            let dt = cl.timestamp.timeIntervalSince(last.timestamp)
            if dt > 0 {
                let instSpeed = dist / dt
                if instSpeed > maxSpeedSpike {
                    return .rejected(.speedSpike)
                }
            }
            if dist > 100 {   // unrealistic jump for walking in one update
                return .rejected(.distanceSpike)
            }
        }

        return .accepted
    }

    private func recordRejection(_ reason: LocationRejectionReason) {
        rejectedCount += 1
        lastRejection = reason
    }

    private func updateSignal(_ state: LiveLocationSignalState) {
        signalState = state
        onSignalStateChange?(state)
    }
}

public enum LiveLocationSignalState: Equatable {
    case waitingForAuthorization
    case waitingForFirstFix
    case active
    case degraded
    case unavailable
    case failed(String)
}