import Foundation

/// Relation of the walker to the *semantic* companion path (not turn-by-turn navigation).
public enum PathRelation: String, Codable, CaseIterable, Sendable, Equatable {
    /// Waiting for first accepted sample / demo tick.
    case establishing
    /// Accepting movement along the walk.
    case onPath
    /// Integrity strain or stalled motion under an active walk.
    case strained
    /// Sustained rejection / non-walking input while session expects progress.
    case offPath
    /// Recovering toward on-path after off-path.
    case recovered
}

/// Platform-neutral path progress for Companion Walk.
public struct PathProgressSnapshot: Codable, Equatable, Sendable {
    public var metersAlongPath: Double
    public var relation: PathRelation
    /// 0…1 presentation pressure (higher → rival/hunter lean).
    public var integrityPressure: Double
    public var acceptedSampleCount: Int
    public var rejectedStreak: Int
    public var isDemo: Bool

    public init(
        metersAlongPath: Double = 0,
        relation: PathRelation = .establishing,
        integrityPressure: Double = 0,
        acceptedSampleCount: Int = 0,
        rejectedStreak: Int = 0,
        isDemo: Bool = false
    ) {
        self.metersAlongPath = max(0, metersAlongPath.finiteOrZero)
        self.relation = relation
        self.integrityPressure = integrityPressure.clamped01
        self.acceptedSampleCount = max(0, acceptedSampleCount)
        self.rejectedStreak = max(0, rejectedStreak)
        self.isDemo = isDemo
    }

    public static let empty = PathProgressSnapshot()
}

/// Accumulates accepted walking progress and integrity strain into a path relation.
///
/// Does **not** store coordinates or plan routes. Demo and real walk share the same rules;
/// only the caller decides when to call `recordAccepted` vs `recordRejected`.
public final class PathProgressEngine: @unchecked Sendable {
    public private(set) var snapshot: PathProgressSnapshot = .empty

    private var consecutiveMovingAccepts = 0
    private var consecutiveStationaryAccepts = 0

    public init() {}

    public func reset(isDemo: Bool) {
        snapshot = PathProgressSnapshot(isDemo: isDemo)
        consecutiveMovingAccepts = 0
        consecutiveStationaryAccepts = 0
    }

    public func recordAccepted(_ movement: MovementSnapshot) {
        var next = snapshot
        next.acceptedSampleCount += 1
        next.rejectedStreak = 0
        if movement.isMoving {
            next.metersAlongPath += max(0, movement.distanceDelta.finiteOrZero)
            consecutiveMovingAccepts += 1
            consecutiveStationaryAccepts = 0
        } else {
            consecutiveStationaryAccepts += 1
            consecutiveMovingAccepts = 0
        }
        next.relation = Self.relationAfterAccept(
            previous: next.relation,
            isMoving: movement.isMoving,
            consecutiveMoving: consecutiveMovingAccepts,
            consecutiveStationary: consecutiveStationaryAccepts,
            acceptedCount: next.acceptedSampleCount
        )
        next.integrityPressure = Self.pressure(
            relation: next.relation,
            rejectedStreak: 0,
            consecutiveStationary: consecutiveStationaryAccepts
        )
        snapshot = next
    }

    public func recordRejected() {
        var next = snapshot
        next.rejectedStreak += 1
        consecutiveMovingAccepts = 0
        next.relation = Self.relationAfterReject(
            previous: next.relation,
            rejectedStreak: next.rejectedStreak
        )
        next.integrityPressure = Self.pressure(
            relation: next.relation,
            rejectedStreak: next.rejectedStreak,
            consecutiveStationary: consecutiveStationaryAccepts
        )
        snapshot = next
    }

    // MARK: - Pure transitions (testable)

    public static func relationAfterAccept(
        previous: PathRelation,
        isMoving: Bool,
        consecutiveMoving: Int,
        consecutiveStationary: Int,
        acceptedCount: Int
    ) -> PathRelation {
        if acceptedCount <= 0 { return .establishing }
        if acceptedCount == 1 { return .establishing }

        switch previous {
        case .establishing:
            return isMoving ? .onPath : .establishing
        case .offPath, .recovered:
            if isMoving && consecutiveMoving >= 2 { return .onPath }
            if isMoving { return .recovered }
            return previous == .offPath ? .offPath : .recovered
        case .strained:
            if isMoving && consecutiveMoving >= 1 { return .onPath }
            if !isMoving && consecutiveStationary >= 4 { return .strained }
            return .strained
        case .onPath:
            if !isMoving && consecutiveStationary >= 5 { return .strained }
            return .onPath
        }
    }

    public static func relationAfterReject(
        previous: PathRelation,
        rejectedStreak: Int
    ) -> PathRelation {
        if rejectedStreak >= 8 { return .offPath }
        if rejectedStreak >= 3 {
            return previous == .offPath ? .offPath : .strained
        }
        if previous == .establishing { return .establishing }
        return previous
    }

    public static func pressure(
        relation: PathRelation,
        rejectedStreak: Int,
        consecutiveStationary: Int
    ) -> Double {
        let base: Double
        switch relation {
        case .establishing: base = 0.05
        case .onPath: base = 0.0
        case .recovered: base = 0.15
        case .strained: base = 0.45
        case .offPath: base = 0.75
        }
        let rejectBoost = min(0.25, Double(rejectedStreak) * 0.03)
        let stallBoost = min(0.15, Double(max(0, consecutiveStationary - 3)) * 0.03)
        return min(1, base + rejectBoost + stallBoost)
    }
}
