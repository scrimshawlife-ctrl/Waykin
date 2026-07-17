import Foundation

public enum MovementError: Error, Equatable {
    case noActiveSession
    case sessionAlreadyActive
    case invalidTransition(from: MovementState, to: MovementState)
}

public protocol MotionProviding {
    func startMotionUpdates()
    func stopMotionUpdates()
}

public protocol ClockProviding {
    var now: Date { get }
}

public final class SystemClock: ClockProviding {
    public var now: Date { Date() }
}

public struct MovementIngestResult: Equatable, Sendable {
    public let diagnostic: MovementSampleDiagnostic
    public let snapshot: MovementSnapshot?

    public init(diagnostic: MovementSampleDiagnostic, snapshot: MovementSnapshot?) {
        self.diagnostic = diagnostic
        self.snapshot = snapshot
    }
}

public protocol MovementSessionManaging {
    var currentSession: MovementSession? { get }
    func startSession(activity: ActivityType, experienceID: String) throws
    func pauseSession() throws
    func resumeSession() throws
    func endSession() throws -> MovementSession
    func simulate(deltaSeconds: TimeInterval, speed: Double)
    func ingestRealLocation(_ point: RoutePoint)
}

public final class MovementEngine: MovementSessionManaging {
    private(set) public var currentSession: MovementSession?
    private(set) public var lastDiagnostic: MovementSampleDiagnostic?
    private(set) public var acceptedSampleCount = 0
    private(set) public var rejectedSampleCount = 0

    private let clock: ClockProviding
    private var integrityProcessor: MovementIntegrityProcessor
    private var lastUpdate: Date?

    public init(
        clock: ClockProviding? = nil,
        integrityConfiguration: MovementIntegrityConfiguration = .conservativeWalking
    ) {
        self.clock = clock ?? SystemClock()
        self.integrityProcessor = MovementIntegrityProcessor(configuration: integrityConfiguration)
    }

    public func startSession(activity: ActivityType, experienceID: String) throws {
        guard currentSession == nil else { throw MovementError.sessionAlreadyActive }
        currentSession = MovementSession(activityType: activity, experienceID: experienceID, startedAt: clock.now)
        lastUpdate = clock.now
        acceptedSampleCount = 0
        rejectedSampleCount = 0
        lastDiagnostic = nil
        integrityProcessor.resetAnchor()
    }

    public func pauseSession() throws {
        guard var session = currentSession else { throw MovementError.noActiveSession }
        guard session.movementState == .moving else {
            throw MovementError.invalidTransition(from: session.movementState, to: .paused)
        }
        session.movementState = .paused
        session.currentSpeedMetersPerSecond = 0
        currentSession = session
        integrityProcessor.resetAnchor()
    }

    public func resumeSession() throws {
        guard var session = currentSession else { throw MovementError.noActiveSession }
        guard session.movementState == .idle || session.movementState == .paused else {
            throw MovementError.invalidTransition(from: session.movementState, to: .moving)
        }
        session.movementState = .moving
        lastUpdate = clock.now
        currentSession = session
        integrityProcessor.resetAnchor()
    }

    public func endSession() throws -> MovementSession {
        guard var session = currentSession else { throw MovementError.noActiveSession }
        session.endedAt = clock.now
        session.movementState = .stopped
        session.currentSpeedMetersPerSecond = 0
        let ended = session
        currentSession = nil
        lastUpdate = nil
        integrityProcessor.resetAnchor()
        return ended
    }

    public func simulate(deltaSeconds: TimeInterval, speed: Double) {
        guard var session = currentSession,
              session.movementState == .moving || session.movementState == .idle else { return }

        let safeDelta = deltaSeconds.isFinite ? max(0, deltaSeconds) : 0
        let safeSpeed = speed.isFinite ? max(0, speed) : 0
        let now = clock.now
        session.elapsedTime += safeDelta

        if safeSpeed > 0.1 {
            session.activeTime += safeDelta
            session.currentSpeedMetersPerSecond = safeSpeed
            let distanceDelta = safeSpeed * safeDelta
            session.distanceMeters += distanceDelta
            session.averageSpeedMetersPerSecond = session.distanceMeters / max(session.activeTime, 0.001)

            let lastLatitude = session.routePoints.last?.latitude ?? 37.7749
            let lastLongitude = session.routePoints.last?.longitude ?? -122.4194
            session.routePoints.append(
                RoutePoint(
                    timestamp: now,
                    latitude: lastLatitude + (distanceDelta * 0.00001),
                    longitude: lastLongitude,
                    altitude: 10,
                    speed: safeSpeed
                )
            )
        } else {
            session.currentSpeedMetersPerSecond = 0
        }

        session.movementState = safeSpeed > 0.1 ? .moving : .paused
        lastUpdate = now
        currentSession = session
    }

    @discardableResult
    public func ingestRealLocationSample(
        _ sample: LocationSample,
        receivedAt: Date? = nil
    ) -> MovementIngestResult {
        guard var session = currentSession else {
            return rejectedResult(for: sample, disposition: .rejectedStopped)
        }
        guard session.movementState == .moving else {
            return rejectedResult(for: sample, disposition: .rejectedPaused)
        }

        let stabilized = integrityProcessor.process(sample, receivedAt: receivedAt ?? clock.now)
        lastDiagnostic = stabilized.diagnostic

        guard stabilized.diagnostic.disposition == .accepted ||
                stabilized.diagnostic.disposition == .awaitingFreshAnchor else {
            rejectedSampleCount += 1
            return MovementIngestResult(diagnostic: stabilized.diagnostic, snapshot: nil)
        }

        acceptedSampleCount += 1
        if let point = stabilized.point {
            session.routePoints.append(point)
        }
        guard stabilized.diagnostic.disposition == .accepted else {
            currentSession = session
            return MovementIngestResult(diagnostic: stabilized.diagnostic, snapshot: nil)
        }

        session.elapsedTime += max(0, stabilized.sampleInterval)
        session.currentSpeedMetersPerSecond = stabilized.isMoving
            ? stabilized.diagnostic.derivedSpeedMetersPerSecond
            : 0
        if stabilized.isMoving {
            session.activeTime += max(0, stabilized.sampleInterval)
        }
        session.distanceMeters += max(0, stabilized.distanceDelta)
        session.averageSpeedMetersPerSecond = session.activeTime > 0
            ? session.distanceMeters / session.activeTime
            : 0
        currentSession = session

        let snapshot = MovementSnapshot(
            timestamp: sample.timestamp,
            speed: session.currentSpeedMetersPerSecond,
            distanceDelta: stabilized.distanceDelta,
            isMoving: stabilized.isMoving
        )
        return MovementIngestResult(diagnostic: stabilized.diagnostic, snapshot: snapshot)
    }

    public func ingestRealLocation(_ point: RoutePoint) {
        _ = ingestRealLocationSample(
            LocationSample(
                timestamp: point.timestamp,
                latitude: point.latitude,
                longitude: point.longitude,
                altitude: point.altitude,
                horizontalAccuracy: 0,
                reportedSpeedMetersPerSecond: point.speed
            ),
            receivedAt: point.timestamp
        )
    }

    private func rejectedResult(
        for sample: LocationSample,
        disposition: MovementSampleDisposition
    ) -> MovementIngestResult {
        let diagnostic = MovementSampleDiagnostic(
            timestamp: sample.timestamp,
            disposition: disposition,
            accuracyBucket: .invalid
        )
        lastDiagnostic = diagnostic
        rejectedSampleCount += 1
        return MovementIngestResult(diagnostic: diagnostic, snapshot: nil)
    }
}
