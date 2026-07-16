import Foundation
import CoreLocation

public enum MovementError: Error, Equatable {
    case noActiveSession
    case sessionAlreadyActive
}

public protocol LocationProviding {
    func requestAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    var onLocationUpdate: ((RoutePoint) -> Void)? { get set }
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
    private let clock: ClockProviding
    private var lastUpdate: Date?

    public init(clock: ClockProviding? = nil) {
        self.clock = clock ?? SystemClock()
    }

    public func startSession(activity: ActivityType, experienceID: String) throws {
        if currentSession != nil {
            throw MovementError.sessionAlreadyActive
        }
        let newSession = MovementSession(activityType: activity, experienceID: experienceID)
        currentSession = newSession
        lastUpdate = clock.now
    }

    public func pauseSession() throws {
        guard var s = currentSession else { throw MovementError.noActiveSession }
        s.movementState = .paused
        currentSession = s
    }

    public func resumeSession() throws {
        guard var s = currentSession else { throw MovementError.noActiveSession }
        s.movementState = .moving
        lastUpdate = clock.now
        currentSession = s
    }

    public func endSession() throws -> MovementSession {
        guard var s = currentSession else { throw MovementError.noActiveSession }
        s.endedAt = clock.now
        s.movementState = .stopped
        let ended = s
        currentSession = nil
        return ended
    }

    public func simulate(deltaSeconds: TimeInterval, speed: Double) {
        guard var s = currentSession,
              s.movementState == .moving || s.movementState == .idle else { return }

        let now = clock.now
        s.elapsedTime += deltaSeconds

        if speed > 0.1 {
            s.activeTime += deltaSeconds
            s.currentSpeedMetersPerSecond = speed
            let distanceDelta = speed * deltaSeconds
            s.distanceMeters += distanceDelta
            s.averageSpeedMetersPerSecond = s.distanceMeters / max(s.activeTime, 0.001)

            let lastLat = s.routePoints.last?.latitude ?? 37.7749
            let lastLon = s.routePoints.last?.longitude ?? -122.4194
            let newPoint = RoutePoint(
                timestamp: now,
                latitude: lastLat + (distanceDelta * 0.00001),
                longitude: lastLon,
                altitude: 10,
                speed: speed
            )
            s.routePoints.append(newPoint)
        } else {
            s.currentSpeedMetersPerSecond = 0
        }

        s.movementState = speed > 0.1 ? .moving : .paused
        lastUpdate = now
        currentSession = s
    }

    public func ingestRealLocation(_ point: RoutePoint) {
        guard var s = currentSession, s.movementState == .moving else { return }

        s.routePoints.append(point)

        if let last = s.routePoints.dropLast().last {
            let clLast = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let clNew = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let dist = clLast.distance(from: clNew)
            s.distanceMeters += dist
        }

        currentSession = s
    }
}
