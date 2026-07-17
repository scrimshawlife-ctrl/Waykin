import Foundation

public enum FieldTestSessionMode: String, Codable, Equatable, Sendable {
    case demo
    case physical
}

public enum FieldTestOutcome: String, Codable, Equatable, Sendable {
    case inProgress
    case completed
    case userEnded
    case permissionDenied
    case providerFailed
    case persistenceFailed
    case interrupted
    case invalidState
}

public enum FieldTestPersistenceResult: String, Codable, Equatable, Sendable {
    case notAttempted
    case succeeded
    case failed
}

public enum FieldTestErrorCategory: String, Codable, Equatable, Sendable {
    case permissionDenied
    case locationServicesDisabled
    case providerUnavailable
    case persistence
    case invalidState
}

public enum FieldTestSessionState: String, Codable, Equatable, Sendable {
    case idle
    case requestingPermission
    case active
    case paused
    case ending
    case completed
    case failed
}

public enum FieldTestEntryCategory: String, Codable, Equatable, Sendable {
    case sessionStateTransition
    case movementSampleDisposition
    case movementStateTransition
    case freshAnchorRequested
    case worldEventEmitted
    case audioCueRequested
    case audioCueSuppressed
    case audioLifecycleAction
    case appLifecycleTransition
    case permissionTransition
    case providerFailure
    case memoryWriteResult
    case sessionCompleted
}

public struct FieldTestEntry: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let category: FieldTestEntryCategory
    public let code: String
    public let disposition: MovementSampleDisposition?
    public let accuracyBucket: MovementAccuracyBucket?
    public let stabilizedSpeedMetersPerSecond: Double?
    public let accumulatedDistance: Bool?

    public init(
        timestamp: Date,
        category: FieldTestEntryCategory,
        code: String,
        disposition: MovementSampleDisposition? = nil,
        accuracyBucket: MovementAccuracyBucket? = nil,
        stabilizedSpeedMetersPerSecond: Double? = nil,
        accumulatedDistance: Bool? = nil
    ) {
        self.timestamp = timestamp
        self.category = category
        self.code = code
        self.disposition = disposition
        self.accuracyBucket = accuracyBucket
        if let speed = stabilizedSpeedMetersPerSecond {
            self.stabilizedSpeedMetersPerSecond = max(0, speed.isFinite ? speed : 0)
        } else {
            self.stabilizedSpeedMetersPerSecond = nil
        }
        self.accumulatedDistance = accumulatedDistance
    }
}

public struct FieldTestSummary: Codable, Equatable, Sendable {
    public var durationSeconds: TimeInterval
    public var activeDurationSeconds: TimeInterval
    public var pausedDurationSeconds: TimeInterval
    public var acceptedSampleCount: Int
    public var rejectedSampleCount: Int
    public var rejectionCounts: [String: Int]
    public var accumulatedDistanceMeters: Double
    public var finalMovementState: MovementState
    public var maximumStabilizedSpeedMetersPerSecond: Double
    public var averageStabilizedSpeedMetersPerSecond: Double
    public var freshAnchorResetCount: Int
    public var worldEventCounts: [String: Int]
    public var semanticAudioCueCounts: [String: Int]
    public var audioSuppressionCount: Int
    public var interruptionCount: Int
    public var lifecycleTransitionCount: Int
    public var startingBond: Int
    public var endingBond: Int
    public var bondDelta: Int
    public var memoryWritten: Bool
    public var finalErrorCategory: FieldTestErrorCategory?

    public init(startingBond: Int) {
        durationSeconds = 0
        activeDurationSeconds = 0
        pausedDurationSeconds = 0
        acceptedSampleCount = 0
        rejectedSampleCount = 0
        rejectionCounts = [:]
        accumulatedDistanceMeters = 0
        finalMovementState = .idle
        maximumStabilizedSpeedMetersPerSecond = 0
        averageStabilizedSpeedMetersPerSecond = 0
        freshAnchorResetCount = 0
        worldEventCounts = [:]
        semanticAudioCueCounts = [:]
        audioSuppressionCount = 0
        interruptionCount = 0
        lifecycleTransitionCount = 0
        self.startingBond = max(0, startingBond)
        endingBond = max(0, startingBond)
        bondDelta = 0
        memoryWritten = false
        finalErrorCategory = nil
    }
}

public struct FieldTestReceipt: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var receiptID: UUID
    public var sessionID: UUID
    public var mode: FieldTestSessionMode
    public var startedAt: Date
    public var endedAt: Date?
    public var outcome: FieldTestOutcome
    public var summary: FieldTestSummary
    public var timeline: [FieldTestEntry]
    public var persistence: FieldTestPersistenceResult

    public init(
        schemaVersion: Int = FieldTestReceipt.currentSchemaVersion,
        receiptID: UUID = UUID(),
        sessionID: UUID,
        mode: FieldTestSessionMode,
        startedAt: Date,
        endedAt: Date? = nil,
        outcome: FieldTestOutcome = .inProgress,
        summary: FieldTestSummary,
        timeline: [FieldTestEntry] = [],
        persistence: FieldTestPersistenceResult = .notAttempted
    ) {
        self.schemaVersion = schemaVersion
        self.receiptID = receiptID
        self.sessionID = sessionID
        self.mode = mode
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.outcome = outcome
        self.summary = summary
        self.timeline = timeline
        self.persistence = persistence
    }
}

public final class FieldTestReceiptBuilder {
    public static let maximumTimelineEntries = 200

    private(set) public var receipt: FieldTestReceipt
    private var speedTotal = 0.0
    private var speedCount = 0
    private var pausedAt: Date?
    private var accumulatedPausedDuration: TimeInterval = 0
    private var lastWorldEventKey: String?

    public init(
        receiptID: UUID = UUID(),
        sessionID: UUID,
        mode: FieldTestSessionMode,
        startedAt: Date,
        startingBond: Int
    ) {
        receipt = FieldTestReceipt(
            receiptID: receiptID,
            sessionID: sessionID,
            mode: mode,
            startedAt: startedAt,
            summary: FieldTestSummary(startingBond: startingBond)
        )
    }

    public func attachSessionID(_ sessionID: UUID) {
        receipt.sessionID = sessionID
    }

    public func recordSessionTransition(
        from: FieldTestSessionState,
        to: FieldTestSessionState,
        at timestamp: Date
    ) {
        if to == .paused, pausedAt == nil {
            pausedAt = timestamp
        } else if from == .paused, let pauseStart = pausedAt {
            accumulatedPausedDuration += max(0, timestamp.timeIntervalSince(pauseStart))
            pausedAt = nil
        }
        append(FieldTestEntry(
            timestamp: timestamp,
            category: .sessionStateTransition,
            code: "\(from.rawValue)_to_\(to.rawValue)"
        ))
    }

    public func recordMovementStateTransition(from: MovementState, to: MovementState, at timestamp: Date) {
        guard from != to else { return }
        append(FieldTestEntry(
            timestamp: timestamp,
            category: .movementStateTransition,
            code: "\(from.rawValue)_to_\(to.rawValue)"
        ))
    }

    public func recordMovement(_ diagnostic: MovementSampleDiagnostic) {
        switch diagnostic.disposition {
        case .accepted:
            receipt.summary.acceptedSampleCount += 1
            recordSpeed(diagnostic.derivedSpeedMetersPerSecond)
        case .awaitingFreshAnchor:
            receipt.summary.acceptedSampleCount += 1
            receipt.summary.freshAnchorResetCount += 1
            append(FieldTestEntry(
                timestamp: diagnostic.timestamp,
                category: .freshAnchorRequested,
                code: diagnostic.disposition.rawValue,
                disposition: diagnostic.disposition,
                accuracyBucket: diagnostic.accuracyBucket,
                stabilizedSpeedMetersPerSecond: diagnostic.derivedSpeedMetersPerSecond,
                accumulatedDistance: diagnostic.accumulatedDistance
            ))
        default:
            receipt.summary.rejectedSampleCount += 1
            receipt.summary.rejectionCounts[diagnostic.disposition.rawValue, default: 0] += 1
            append(FieldTestEntry(
                timestamp: diagnostic.timestamp,
                category: .movementSampleDisposition,
                code: diagnostic.disposition.rawValue,
                disposition: diagnostic.disposition,
                accuracyBucket: diagnostic.accuracyBucket,
                stabilizedSpeedMetersPerSecond: diagnostic.derivedSpeedMetersPerSecond,
                accumulatedDistance: diagnostic.accumulatedDistance
            ))
        }
    }

    public func recordMovementSnapshot(_ snapshot: MovementSnapshot) {
        recordSpeed(snapshot.speed)
    }

    public func recordWorldEvent(_ event: WorldEvent) {
        let key = "\(event.kind.rawValue):\(event.occurredAt.timeIntervalSince1970)"
        guard lastWorldEventKey != key else { return }
        lastWorldEventKey = key
        receipt.summary.worldEventCounts[event.kind.rawValue, default: 0] += 1
        append(FieldTestEntry(timestamp: event.occurredAt, category: .worldEventEmitted, code: event.kind.rawValue))
    }

    public func recordAudioCue(_ cue: AudioCue, at timestamp: Date) {
        receipt.summary.semanticAudioCueCounts[cue.kind.rawValue, default: 0] += 1
        append(FieldTestEntry(timestamp: timestamp, category: .audioCueRequested, code: cue.kind.rawValue))
    }

    public func recordAudioSuppression(_ code: String, at timestamp: Date) {
        receipt.summary.audioSuppressionCount += 1
        append(FieldTestEntry(timestamp: timestamp, category: .audioCueSuppressed, code: code))
    }

    public func recordAudioLifecycle(_ code: String, at timestamp: Date) {
        let entry = FieldTestEntry(timestamp: timestamp, category: .audioLifecycleAction, code: code)
        code == "stop" ? appendRequired(entry) : append(entry)
    }

    public func recordLifecycle(_ code: String, at timestamp: Date) {
        if code == "inactive" || code == "background" {
            receipt.summary.lifecycleTransitionCount += 1
        }
        append(FieldTestEntry(timestamp: timestamp, category: .appLifecycleTransition, code: code))
    }

    public func recordInterruption(_ code: String, at timestamp: Date) {
        if !code.lowercased().contains("ended") {
            receipt.summary.interruptionCount += 1
        }
        append(FieldTestEntry(timestamp: timestamp, category: .appLifecycleTransition, code: code))
    }

    public func recordPermission(_ code: String, at timestamp: Date) {
        append(FieldTestEntry(timestamp: timestamp, category: .permissionTransition, code: code))
    }

    public func recordProviderFailure(_ category: FieldTestErrorCategory, at timestamp: Date) {
        receipt.summary.finalErrorCategory = category
        append(FieldTestEntry(timestamp: timestamp, category: .providerFailure, code: category.rawValue))
    }

    public func finish(
        session: MovementSession?,
        outcome: FieldTestOutcome,
        endingBond: Int,
        memoryWritten: Bool,
        persistence: FieldTestPersistenceResult,
        errorCategory: FieldTestErrorCategory? = nil,
        endedAt: Date
    ) -> FieldTestReceipt {
        if let pauseStart = pausedAt {
            accumulatedPausedDuration += max(0, endedAt.timeIntervalSince(pauseStart))
            pausedAt = nil
        }

        receipt.endedAt = endedAt
        receipt.outcome = outcome
        receipt.persistence = persistence
        let duration = receipt.mode == .demo
            ? finiteNonnegative(session?.elapsedTime ?? 0) + finiteNonnegative(accumulatedPausedDuration)
            : finiteNonnegative(endedAt.timeIntervalSince(receipt.startedAt))
        receipt.summary.durationSeconds = finiteNonnegative(duration)
        receipt.summary.activeDurationSeconds = finiteNonnegative(session?.activeTime ?? 0)
        receipt.summary.pausedDurationSeconds = finiteNonnegative(accumulatedPausedDuration)
        receipt.summary.accumulatedDistanceMeters = finiteNonnegative(session?.distanceMeters ?? 0)
        receipt.summary.finalMovementState = session?.movementState ?? .stopped
        receipt.summary.averageStabilizedSpeedMetersPerSecond = speedCount > 0
            ? finiteNonnegative(speedTotal / Double(speedCount))
            : 0
        receipt.summary.endingBond = max(0, endingBond)
        receipt.summary.bondDelta = receipt.summary.endingBond - receipt.summary.startingBond
        receipt.summary.memoryWritten = memoryWritten
        receipt.summary.finalErrorCategory = errorCategory ?? receipt.summary.finalErrorCategory
        appendRequired(FieldTestEntry(timestamp: endedAt, category: .memoryWriteResult, code: persistence.rawValue))
        appendRequired(FieldTestEntry(timestamp: endedAt, category: .sessionCompleted, code: outcome.rawValue))
        return receipt
    }

    private func recordSpeed(_ speed: Double) {
        let safeSpeed = finiteNonnegative(speed)
        speedTotal += safeSpeed
        speedCount += 1
        receipt.summary.maximumStabilizedSpeedMetersPerSecond = max(
            receipt.summary.maximumStabilizedSpeedMetersPerSecond,
            safeSpeed
        )
    }

    private func append(_ entry: FieldTestEntry) {
        guard receipt.timeline.count < Self.maximumTimelineEntries else { return }
        receipt.timeline.append(entry)
    }

    private func appendRequired(_ entry: FieldTestEntry) {
        if receipt.timeline.count == Self.maximumTimelineEntries {
            let removableIndex = receipt.timeline.lastIndex {
                $0.category != .memoryWriteResult
                    && $0.category != .sessionCompleted
                    && !($0.category == .audioLifecycleAction && $0.code == "stop")
            } ?? receipt.timeline.startIndex
            receipt.timeline.remove(at: removableIndex)
        }
        receipt.timeline.append(entry)
    }

    private func finiteNonnegative(_ value: Double) -> Double {
        max(0, value.isFinite ? value : 0)
    }
}
