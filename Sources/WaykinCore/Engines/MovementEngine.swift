import Foundation

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
    func startSession(activity: ActivityType, experienceID: String) -> MovementSession
    func pauseSession()
    func resumeSession()
    func endSession() -> MovementSession
    func simulateMovement(for session: inout MovementSession, deltaSeconds: TimeInterval, speed: Double)
    var currentSession: MovementSession? { get }
}

public final class MovementEngine: MovementSessionManaging {
    private var session: MovementSession?
    private let clock: ClockProviding
    private var lastUpdate: Date?

    public init(clock: ClockProviding? = nil) {
        self.clock = clock ?? SystemClock()
    }

    public var currentSession: MovementSession? { session }

    public func startSession(activity: ActivityType, experienceID: String) -> MovementSession {
        let newSession = MovementSession(activityType: activity, experienceID: experienceID)
        self.session = newSession
        self.lastUpdate = clock.now
        return newSession
    }

    public func pauseSession() {
        guard var s = session else { return }
        s.movementState = .paused
        session = s
    }

    public func resumeSession() {
        guard var s = session else { return }
        s.movementState = .moving
        lastUpdate = clock.now
        session = s
    }

    public func endSession() -> MovementSession {
        guard var s = session else { fatalError("No active session") }
        s.endedAt = clock.now
        s.movementState = .stopped
        session = s
        return s
    }

    public func simulateMovement(for session: inout MovementSession, deltaSeconds: TimeInterval, speed: Double) {
        guard session.movementState == .moving || session.movementState == .idle else { return }

        let now = clock.now
        session.elapsedTime += deltaSeconds
        if speed > 0.1 {
            session.activeTime += deltaSeconds
            session.currentSpeedMetersPerSecond = speed
            let distanceDelta = speed * deltaSeconds
            session.distanceMeters += distanceDelta
            session.averageSpeedMetersPerSecond = session.distanceMeters / max(session.activeTime, 0.001)

            // Add route point (simulated straight line for POC)
            let lastLat = session.routePoints.last?.latitude ?? 37.7749
            let lastLon = session.routePoints.last?.longitude ?? -122.4194
            let newPoint = RoutePoint(
                timestamp: now,
                latitude: lastLat + (distanceDelta * 0.00001), // crude
                longitude: lastLon,
                altitude: 10,
                speed: speed
            )
            session.routePoints.append(newPoint)
        } else {
            session.currentSpeedMetersPerSecond = 0
        }
        lastUpdate = now
        session.movementState = speed > 0.1 ? .moving : .paused
    }

    // Real location update would feed here in full app
    public func ingestRealLocation(_ point: RoutePoint) {
        guard var s = session, s.movementState == .moving else { return }
        // In real impl, calculate delta from previous
        s.routePoints.append(point)
        // Simplified distance calc
        if let last = s.routePoints.dropLast().last {
            let dist = sqrt(pow(point.latitude - last.latitude, 2) + pow(point.longitude - last.longitude, 2)) * 111000 // rough m
            s.distanceMeters += dist
        }
        session = s
    }
}
