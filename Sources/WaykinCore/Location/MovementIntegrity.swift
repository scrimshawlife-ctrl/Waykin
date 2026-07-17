import CoreLocation
import Foundation

public struct MovementIntegrityConfiguration: Equatable, Sendable {
    public let maximumHorizontalAccuracyMeters: Double
    public let maximumSampleAge: TimeInterval
    public let maximumFutureSkew: TimeInterval
    public let minimumDisplacementMeters: Double
    public let maximumWalkingSpeedMetersPerSecond: Double
    public let maximumSingleDisplacementMeters: Double
    public let stationarySpeedThreshold: Double
    public let movingSpeedThreshold: Double
    public let anchorResetInterval: TimeInterval
    public let speedWindowSize: Int

    public init(
        maximumHorizontalAccuracyMeters: Double = 30,
        maximumSampleAge: TimeInterval = 15,
        maximumFutureSkew: TimeInterval = 2,
        minimumDisplacementMeters: Double = 1.5,
        maximumWalkingSpeedMetersPerSecond: Double = 4.5,
        maximumSingleDisplacementMeters: Double = 60,
        stationarySpeedThreshold: Double = 0.25,
        movingSpeedThreshold: Double = 0.55,
        anchorResetInterval: TimeInterval = 15,
        speedWindowSize: Int = 3
    ) {
        self.maximumHorizontalAccuracyMeters = max(1, maximumHorizontalAccuracyMeters)
        self.maximumSampleAge = max(1, maximumSampleAge)
        self.maximumFutureSkew = max(0, maximumFutureSkew)
        self.minimumDisplacementMeters = max(0, minimumDisplacementMeters)
        self.maximumWalkingSpeedMetersPerSecond = max(0.5, maximumWalkingSpeedMetersPerSecond)
        self.maximumSingleDisplacementMeters = max(1, maximumSingleDisplacementMeters)
        self.stationarySpeedThreshold = max(0, stationarySpeedThreshold)
        self.movingSpeedThreshold = max(self.stationarySpeedThreshold, movingSpeedThreshold)
        self.anchorResetInterval = max(1, anchorResetInterval)
        self.speedWindowSize = max(1, speedWindowSize)
    }

    public static let conservativeWalking = MovementIntegrityConfiguration()
}

public struct LocationSample: Equatable, Sendable {
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let horizontalAccuracy: Double
    public let reportedSpeedMetersPerSecond: Double

    public init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double,
        reportedSpeedMetersPerSecond: Double
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.reportedSpeedMetersPerSecond = reportedSpeedMetersPerSecond
    }
}

public enum MovementAccuracyBucket: String, Codable, Equatable, Sendable {
    case invalid
    case precise
    case usable
    case poor
}

public enum MovementSampleDisposition: String, Codable, Equatable, Sendable {
    case accepted
    case awaitingFreshAnchor
    case rejectedInvalid
    case rejectedNegativeAccuracy
    case rejectedAccuracy
    case rejectedStale
    case rejectedOutOfOrder
    case rejectedDuplicate
    case rejectedPaused
    case rejectedStopped
    case rejectedImplausibleDisplacement
}

public struct MovementSampleDiagnostic: Equatable, Sendable {
    public let timestamp: Date
    public let disposition: MovementSampleDisposition
    public let accuracyBucket: MovementAccuracyBucket
    public let derivedSpeedMetersPerSecond: Double
    public let accumulatedDistance: Bool

    public init(
        timestamp: Date,
        disposition: MovementSampleDisposition,
        accuracyBucket: MovementAccuracyBucket,
        derivedSpeedMetersPerSecond: Double = 0,
        accumulatedDistance: Bool = false
    ) {
        self.timestamp = timestamp
        self.disposition = disposition
        self.accuracyBucket = accuracyBucket
        self.derivedSpeedMetersPerSecond = max(0, derivedSpeedMetersPerSecond.isFinite ? derivedSpeedMetersPerSecond : 0)
        self.accumulatedDistance = accumulatedDistance
    }
}

public struct StabilizedMovementSample: Equatable, Sendable {
    public let point: RoutePoint?
    public let sampleInterval: TimeInterval
    public let distanceDelta: Double
    public let isMoving: Bool
    public let diagnostic: MovementSampleDiagnostic
}

public struct MovementIntegrityProcessor: Sendable {
    public let configuration: MovementIntegrityConfiguration
    private var anchor: LocationSample?
    private var recentSpeeds: [Double] = []
    private var isMoving = false

    public init(configuration: MovementIntegrityConfiguration = .conservativeWalking) {
        self.configuration = configuration
    }

    public mutating func resetAnchor() {
        anchor = nil
        recentSpeeds.removeAll()
        isMoving = false
    }

    public mutating func process(_ sample: LocationSample, receivedAt: Date) -> StabilizedMovementSample {
        let accuracyBucket = accuracyBucket(for: sample.horizontalAccuracy)

        guard sample.latitude.isFinite,
              sample.longitude.isFinite,
              (-90...90).contains(sample.latitude),
              (-180...180).contains(sample.longitude),
              sample.horizontalAccuracy.isFinite else {
            return rejected(sample, disposition: .rejectedInvalid, accuracyBucket: accuracyBucket)
        }
        guard sample.horizontalAccuracy >= 0 else {
            return rejected(sample, disposition: .rejectedNegativeAccuracy, accuracyBucket: .invalid)
        }
        guard sample.horizontalAccuracy <= configuration.maximumHorizontalAccuracyMeters else {
            return rejected(sample, disposition: .rejectedAccuracy, accuracyBucket: accuracyBucket)
        }

        let age = receivedAt.timeIntervalSince(sample.timestamp)
        guard age <= configuration.maximumSampleAge else {
            return rejected(sample, disposition: .rejectedStale, accuracyBucket: accuracyBucket)
        }
        guard age >= -configuration.maximumFutureSkew else {
            return rejected(sample, disposition: .rejectedInvalid, accuracyBucket: accuracyBucket)
        }

        guard let previous = anchor else {
            return establishAnchor(sample, accuracyBucket: accuracyBucket)
        }

        let interval = sample.timestamp.timeIntervalSince(previous.timestamp)
        guard interval > 0 else {
            let disposition: MovementSampleDisposition = interval == 0 ? .rejectedDuplicate : .rejectedOutOfOrder
            return rejected(sample, disposition: disposition, accuracyBucket: accuracyBucket)
        }
        if interval > configuration.anchorResetInterval {
            return establishAnchor(sample, accuracyBucket: accuracyBucket)
        }

        let distance = distanceMeters(from: previous, to: sample)
        let distanceSpeed = distance / interval
        guard distance.isFinite,
              distance <= configuration.maximumSingleDisplacementMeters,
              distanceSpeed <= configuration.maximumWalkingSpeedMetersPerSecond else {
            return rejected(
                sample,
                disposition: .rejectedImplausibleDisplacement,
                accuracyBucket: accuracyBucket,
                derivedSpeed: distanceSpeed
            )
        }

        let sourceSpeed = sample.reportedSpeedMetersPerSecond
        let candidateSpeed: Double
        if sourceSpeed.isFinite,
           sourceSpeed >= 0,
           sourceSpeed <= configuration.maximumWalkingSpeedMetersPerSecond {
            candidateSpeed = sourceSpeed
        } else {
            candidateSpeed = distanceSpeed
        }

        recentSpeeds.append(min(configuration.maximumWalkingSpeedMetersPerSecond, max(0, candidateSpeed)))
        if recentSpeeds.count > configuration.speedWindowSize {
            recentSpeeds.removeFirst(recentSpeeds.count - configuration.speedWindowSize)
        }
        let stabilizedSpeed = recentSpeeds.reduce(0, +) / Double(recentSpeeds.count)

        if isMoving {
            if stabilizedSpeed <= configuration.stationarySpeedThreshold {
                isMoving = false
            }
        } else if stabilizedSpeed >= configuration.movingSpeedThreshold {
            isMoving = true
        }

        let accumulatedDistance = isMoving && distance >= configuration.minimumDisplacementMeters
        let distanceDelta = accumulatedDistance ? distance : 0
        anchor = sample

        let diagnostic = MovementSampleDiagnostic(
            timestamp: sample.timestamp,
            disposition: .accepted,
            accuracyBucket: accuracyBucket,
            derivedSpeedMetersPerSecond: stabilizedSpeed,
            accumulatedDistance: accumulatedDistance
        )
        return StabilizedMovementSample(
            point: RoutePoint(
                timestamp: sample.timestamp,
                latitude: sample.latitude,
                longitude: sample.longitude,
                altitude: sample.altitude,
                speed: stabilizedSpeed
            ),
            sampleInterval: interval,
            distanceDelta: distanceDelta,
            isMoving: isMoving,
            diagnostic: diagnostic
        )
    }

    private mutating func establishAnchor(
        _ sample: LocationSample,
        accuracyBucket: MovementAccuracyBucket
    ) -> StabilizedMovementSample {
        anchor = sample
        recentSpeeds.removeAll()
        isMoving = false
        let diagnostic = MovementSampleDiagnostic(
            timestamp: sample.timestamp,
            disposition: .awaitingFreshAnchor,
            accuracyBucket: accuracyBucket
        )
        return StabilizedMovementSample(
            point: RoutePoint(
                timestamp: sample.timestamp,
                latitude: sample.latitude,
                longitude: sample.longitude,
                altitude: sample.altitude,
                speed: 0
            ),
            sampleInterval: 0,
            distanceDelta: 0,
            isMoving: false,
            diagnostic: diagnostic
        )
    }

    private func rejected(
        _ sample: LocationSample,
        disposition: MovementSampleDisposition,
        accuracyBucket: MovementAccuracyBucket,
        derivedSpeed: Double = 0
    ) -> StabilizedMovementSample {
        StabilizedMovementSample(
            point: nil,
            sampleInterval: 0,
            distanceDelta: 0,
            isMoving: false,
            diagnostic: MovementSampleDiagnostic(
                timestamp: sample.timestamp,
                disposition: disposition,
                accuracyBucket: accuracyBucket,
                derivedSpeedMetersPerSecond: derivedSpeed,
                accumulatedDistance: false
            )
        )
    }

    private func accuracyBucket(for accuracy: Double) -> MovementAccuracyBucket {
        guard accuracy.isFinite, accuracy >= 0 else { return .invalid }
        if accuracy <= 10 { return .precise }
        if accuracy <= configuration.maximumHorizontalAccuracyMeters { return .usable }
        return .poor
    }

    private func distanceMeters(from lhs: LocationSample, to rhs: LocationSample) -> Double {
        CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
    }
}
