import Foundation
import CoreLocation
import Observation
import WaykinCore

/// Wraps CLLocationManager and feeds fixes into a MovementSessionTracker.
/// Also reverse-geocodes a friendly location name for the memory engine.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private(set) var authorization: CLAuthorizationStatus = .notDetermined
    private(set) var latestUpdate: MovementUpdate?
    private(set) var locationName = "Somewhere new"

    private var tracker: MovementSessionTracker?
    var onUpdate: ((MovementUpdate) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.allowsBackgroundLocationUpdates = false
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startSession(activity: ActivityType?) {
        tracker = MovementSessionTracker(activity: activity, startedAt: Date())
        latestUpdate = nil
        manager.startUpdatingLocation()
    }

    func endSession() -> MovementSession? {
        manager.stopUpdatingLocation()
        defer { tracker = nil }
        return tracker?.end(at: Date())
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let tracker else { return }
        for location in locations where location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 {
            let sample = MovementSample(
                coordinate: GeoCoordinate(latitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude),
                timestamp: location.timestamp)
            if let update = tracker.record(sample) {
                latestUpdate = update
                onUpdate?(update)
            }
        }
        if locationName == "Somewhere new", let last = locations.last {
            resolveName(for: last)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Transient GPS errors are expected outdoors; the tracker just
        // waits for the next good fix.
    }

    private func resolveName(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }
            self.locationName = placemark.areasOfInterest?.first
                ?? placemark.thoroughfare
                ?? placemark.locality
                ?? "Somewhere new"
        }
    }
}
