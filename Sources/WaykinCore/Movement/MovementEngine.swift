import Foundation

/// Platform-free coordinate. The app layer maps CLLocationCoordinate2D here;
/// tests and the simulator feed synthetic routes.
public struct GeoCoordinate: Codable, Equatable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Haversine distance in meters.
    public func distance(to other: GeoCoordinate) -> Double {
        let r = 6_371_000.0
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(latitude * .pi / 180) * cos(other.latitude * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

public enum ActivityType: String, Codable, CaseIterable {
    case walking, running

    public var displayName: String { rawValue.capitalized }
}

/// One GPS fix.
public struct MovementSample: Codable, Equatable {
    public var coordinate: GeoCoordinate
    public var timestamp: Date

    public init(coordinate: GeoCoordinate, timestamp: Date) {
        self.coordinate = coordinate
        self.timestamp = timestamp
    }
}

/// Live snapshot emitted after each sample — the sole input experiences see.
public struct MovementUpdate: Equatable {
    public var elapsedSeconds: TimeInterval
    public var distanceMeters: Double
    /// Rolling pace over the recent window, seconds per kilometer. Nil until enough data.
    public var paceSecondsPerKm: Double?
    /// Instantaneous speed in m/s over the last segment.
    public var speedMetersPerSecond: Double
    public var isMoving: Bool
    public var detectedActivity: ActivityType
    public var coordinate: GeoCoordinate
}

/// Completed session record.
public struct MovementSession: Codable, Identifiable, Equatable {
    public var id: UUID
    public var activity: ActivityType
    public var startedAt: Date
    public var endedAt: Date
    public var distanceMeters: Double
    public var route: [MovementSample]

    public init(id: UUID = UUID(), activity: ActivityType, startedAt: Date, endedAt: Date,
                distanceMeters: Double, route: [MovementSample]) {
        self.id = id
        self.activity = activity
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.route = route
    }

    public var durationSeconds: TimeInterval { endedAt.timeIntervalSince(startedAt) }
    public var averagePaceSecondsPerKm: Double? {
        guard distanceMeters > 1 else { return nil }
        return durationSeconds / (distanceMeters / 1000)
    }
}

/// Tracks one live session. Feed it GPS samples; it returns MovementUpdates
/// and produces the final MovementSession on end.
public final class MovementSessionTracker {
    /// Below this speed (m/s) the user counts as stopped. Walking is ~1.4 m/s.
    public static let movingSpeedThreshold = 0.4
    /// Above this speed (m/s) activity auto-detects as running.
    public static let runningSpeedThreshold = 2.2
    /// GPS jumps faster than this (m/s) are discarded as noise.
    public static let maxPlausibleSpeed = 12.0

    public private(set) var selectedActivity: ActivityType?
    private var samples: [MovementSample] = []
    private var startedAt: Date
    private var distanceMeters: Double = 0
    private var lastSpeed: Double = 0

    /// Pass `activity: nil` for auto-detection.
    public init(activity: ActivityType? = nil, startedAt: Date) {
        self.selectedActivity = activity
        self.startedAt = startedAt
    }

    /// Record a GPS fix. Returns nil for out-of-order or implausible samples.
    @discardableResult
    public func record(_ sample: MovementSample) -> MovementUpdate? {
        if let last = samples.last {
            let dt = sample.timestamp.timeIntervalSince(last.timestamp)
            guard dt > 0 else { return nil }
            let segment = last.coordinate.distance(to: sample.coordinate)
            let speed = segment / dt
            guard speed <= Self.maxPlausibleSpeed else { return nil }
            distanceMeters += segment
            lastSpeed = speed
        }
        samples.append(sample)

        let elapsed = sample.timestamp.timeIntervalSince(startedAt)
        let pace = rollingPace(endingAt: sample.timestamp)
        let detected: ActivityType = selectedActivity
            ?? (lastSpeed >= Self.runningSpeedThreshold ? .running : .walking)

        return MovementUpdate(
            elapsedSeconds: elapsed,
            distanceMeters: distanceMeters,
            paceSecondsPerKm: pace,
            speedMetersPerSecond: lastSpeed,
            isMoving: lastSpeed >= Self.movingSpeedThreshold,
            detectedActivity: detected,
            coordinate: sample.coordinate
        )
    }

    /// Rolling pace over the last 60 seconds of samples.
    private func rollingPace(endingAt end: Date) -> Double? {
        let windowStart = end.addingTimeInterval(-60)
        let window = samples.filter { $0.timestamp >= windowStart }
        guard window.count >= 2, let first = window.first, let last = window.last else { return nil }
        var meters = 0.0
        for i in 1..<window.count {
            meters += window[i - 1].coordinate.distance(to: window[i].coordinate)
        }
        let seconds = last.timestamp.timeIntervalSince(first.timestamp)
        guard meters > 5, seconds > 0 else { return nil }
        return seconds / (meters / 1000)
    }

    public func end(at date: Date) -> MovementSession {
        let activity: ActivityType
        if let selected = selectedActivity {
            activity = selected
        } else {
            // Majority auto-detection: running if average speed says so.
            let duration = date.timeIntervalSince(startedAt)
            let avgSpeed = duration > 0 ? distanceMeters / duration : 0
            activity = avgSpeed >= Self.runningSpeedThreshold ? .running : .walking
        }
        return MovementSession(
            activity: activity,
            startedAt: startedAt,
            endedAt: date,
            distanceMeters: distanceMeters,
            route: samples
        )
    }
}
