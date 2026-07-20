import CoreLocation
import Foundation
import SwiftUI
import WaykinCore

// Issue #121: GPS/maps presentation surfaces. Presentation-only — consumes
// existing model state (accepted coordinates, LiveLocationSignalState) and
// owns no gameplay or measurement truth.

/// One displayed breadcrumb point. Plain doubles so the trace is Equatable
/// and testable without CoreLocation types.
struct TracePoint: Equatable {
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Presentation-side walked-path trace for the *current* session only.
///
/// Not a route recording: spacing-deduped, hard-capped, reset on session end,
/// never persisted, never exposed to VoiceOver as coordinates. The measured
/// route (movement truth) remains owned by the core movement engine.
struct WalkPathTrace: Equatable {
    static let maxPoints = 400
    static let minSpacingMeters: Double = 4

    private(set) var points: [TracePoint] = []

    var isEmpty: Bool { points.isEmpty }
    var count: Int { points.count }

    /// Append an accepted fix. Ignored when closer than the spacing floor to
    /// the previous kept point; oldest points drop past the cap.
    mutating func append(latitude: Double, longitude: Double) {
        guard latitude.isFinite, longitude.isFinite else { return }
        let candidate = TracePoint(latitude: latitude, longitude: longitude)
        if let last = points.last,
           Self.approximateMeters(from: last, to: candidate) < Self.minSpacingMeters {
            return
        }
        points.append(candidate)
        if points.count > Self.maxPoints {
            points.removeFirst(points.count - Self.maxPoints)
        }
    }

    mutating func reset() {
        points.removeAll(keepingCapacity: false)
    }

    /// Equirectangular approximation — plenty for a 4 m spacing gate at
    /// walking distances; avoids reaching into core movement math.
    static func approximateMeters(from a: TracePoint, to b: TracePoint) -> Double {
        let metersPerDegreeLat = 111_320.0
        let dLat = (b.latitude - a.latitude) * metersPerDegreeLat
        let dLon = (b.longitude - a.longitude) * metersPerDegreeLat
            * cos(a.latitude * .pi / 180)
        return (dLat * dLat + dLon * dLon).squareRoot()
    }
}

/// Human presentation of the existing `LiveLocationSignalState`. The raw
/// failure string never reaches the HUD or VoiceOver — session diagnostics
/// already carry it where it belongs.
struct GPSSignalPresentation: Equatable {
    let label: String
    let symbolName: String
    let isProblem: Bool
    let accessibilityValue: String

    init(state: LiveLocationSignalState) {
        switch state {
        case .waitingForAuthorization:
            label = "Location permission"
            symbolName = "location.slash"
            isProblem = true
            accessibilityValue = "Waiting for location permission."
        case .waitingForFirstFix:
            label = "Searching GPS"
            symbolName = "location.viewfinder"
            isProblem = false
            accessibilityValue = "Searching for a GPS fix."
        case .active:
            label = "GPS active"
            symbolName = "location.fill"
            isProblem = false
            accessibilityValue = "GPS signal is active."
        case .degraded:
            label = "GPS weak"
            symbolName = "location"
            isProblem = true
            accessibilityValue = "GPS signal is weak; distance may update slowly."
        case .unavailable:
            label = "GPS unavailable"
            symbolName = "location.slash"
            isProblem = true
            accessibilityValue = "GPS is unavailable."
        case .failed:
            label = "GPS error"
            symbolName = "exclamationmark.triangle"
            isProblem = true
            accessibilityValue = "GPS stopped working; the walk keeps its last measured state."
        }
    }
}
