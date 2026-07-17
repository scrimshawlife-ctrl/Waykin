import CoreLocation
import Foundation

public protocol RealLocationProviding: AnyObject {
    var onLocationSample: ((LocationSample) -> Void)? { get set }
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)? { get set }
    var onSignalStateChange: ((LiveLocationSignalState) -> Void)? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    var locationServicesEnabled: Bool { get }

    func requestAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

public final class RealLocationProvider: NSObject, RealLocationProviding, CLLocationManagerDelegate {
    public var onLocationSample: ((LocationSample) -> Void)?
    public var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    public var onSignalStateChange: ((LiveLocationSignalState) -> Void)?

    private let manager = CLLocationManager()

    public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public private(set) var signalState: LiveLocationSignalState = .waitingForAuthorization
    public var locationServicesEnabled: Bool { CLLocationManager.locationServicesEnabled() }

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 2
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

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
            updateSignal(.failed("Location authorization is unavailable."))
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations.sorted(by: { $0.timestamp < $1.timestamp }) {
            onLocationSample?(
                LocationSample(
                    timestamp: location.timestamp,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    altitude: location.verticalAccuracy >= 0 ? location.altitude : nil,
                    horizontalAccuracy: location.horizontalAccuracy,
                    reportedSpeedMetersPerSecond: location.speed
                )
            )
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .locationUnknown {
            updateSignal(.degraded)
        } else {
            updateSignal(.failed("Location is unavailable."))
        }
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
