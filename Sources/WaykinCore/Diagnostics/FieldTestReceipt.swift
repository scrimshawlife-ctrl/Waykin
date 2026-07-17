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
    case audioDiagnostic
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
    public let audioDiagnosticKind: AudioPlaybackDiagnosticKind?
    public let audioCueKind: AudioCueKind?
    public let audioDiagnosticReasonCode: AudioPlaybackReasonCode?
    public let audioDiagnosticChannel: AudioDiagnosticChannel?
    public let audioRouteCategory: AudioOutputRouteCategory?
    public let audioRouteChangeReason: AudioRouteChangeReasonCode?
    public let audioInterruptionResumeDisposition: AudioInterruptionResumeDisposition?
    public let audioSessionPolicy: AudioSessionPolicyIdentifier?

    public init(
        timestamp: Date,
        category: FieldTestEntryCategory,
        code: String,
        disposition: MovementSampleDisposition? = nil,
        accuracyBucket: MovementAccuracyBucket? = nil,
        stabilizedSpeedMetersPerSecond: Double? = nil,
        accumulatedDistance: Bool? = nil,
        audioDiagnosticKind: AudioPlaybackDiagnosticKind? = nil,
        audioCueKind: AudioCueKind? = nil,
        audioDiagnosticReasonCode: AudioPlaybackReasonCode? = nil,
        audioDiagnosticChannel: AudioDiagnosticChannel? = nil,
        audioRouteCategory: AudioOutputRouteCategory? = nil,
        audioRouteChangeReason: AudioRouteChangeReasonCode? = nil,
        audioInterruptionResumeDisposition: AudioInterruptionResumeDisposition? = nil,
        audioSessionPolicy: AudioSessionPolicyIdentifier? = nil
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
        self.audioDiagnosticKind = audioDiagnosticKind
        self.audioCueKind = audioCueKind
        self.audioDiagnosticReasonCode = audioDiagnosticReasonCode
        self.audioDiagnosticChannel = audioDiagnosticChannel
        self.audioRouteCategory = audioRouteCategory
        self.audioRouteChangeReason = audioRouteChangeReason
        self.audioInterruptionResumeDisposition = audioInterruptionResumeDisposition
        self.audioSessionPolicy = audioSessionPolicy
    }
}

public struct FieldTestAudioDiagnosticSummary: Codable, Equatable, Sendable {
    public var cueReceiptCounts: [String: Int]
    public var plannerAcceptedCueCounts: [String: Int]
    public var suppressionReasonCounts: [String: Int]
    public var assetLifecycleCounts: [String: Int]
    public var audioSessionLifecycleCounts: [String: Int]
    public var playerLifecycleCounts: [String: Int]
    public var playbackLifecycleCounts: [String: Int]
    public var interruptionEventCounts: [String: Int]
    public var routeChangeReasonCounts: [String: Int]
    public var stopCount: Int
    public var fadeCount: Int
    public var lastRouteCategory: AudioOutputRouteCategory?

    public init() {
        cueReceiptCounts = [:]
        plannerAcceptedCueCounts = [:]
        suppressionReasonCounts = [:]
        assetLifecycleCounts = [:]
        audioSessionLifecycleCounts = [:]
        playerLifecycleCounts = [:]
        playbackLifecycleCounts = [:]
        interruptionEventCounts = [:]
        routeChangeReasonCounts = [:]
        stopCount = 0
        fadeCount = 0
        lastRouteCategory = nil
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
    public var audioDiagnostics: FieldTestAudioDiagnosticSummary

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
        audioDiagnostics = FieldTestAudioDiagnosticSummary()
    }

    private enum CodingKeys: String, CodingKey {
        case durationSeconds
        case activeDurationSeconds
        case pausedDurationSeconds
        case acceptedSampleCount
        case rejectedSampleCount
        case rejectionCounts
        case accumulatedDistanceMeters
        case finalMovementState
        case maximumStabilizedSpeedMetersPerSecond
        case averageStabilizedSpeedMetersPerSecond
        case freshAnchorResetCount
        case worldEventCounts
        case semanticAudioCueCounts
        case audioSuppressionCount
        case interruptionCount
        case lifecycleTransitionCount
        case startingBond
        case endingBond
        case bondDelta
        case memoryWritten
        case finalErrorCategory
        case audioDiagnostics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        activeDurationSeconds = try container.decode(TimeInterval.self, forKey: .activeDurationSeconds)
        pausedDurationSeconds = try container.decode(TimeInterval.self, forKey: .pausedDurationSeconds)
        acceptedSampleCount = try container.decode(Int.self, forKey: .acceptedSampleCount)
        rejectedSampleCount = try container.decode(Int.self, forKey: .rejectedSampleCount)
        rejectionCounts = try container.decode([String: Int].self, forKey: .rejectionCounts)
        accumulatedDistanceMeters = try container.decode(Double.self, forKey: .accumulatedDistanceMeters)
        finalMovementState = try container.decode(MovementState.self, forKey: .finalMovementState)
        maximumStabilizedSpeedMetersPerSecond = try container.decode(Double.self, forKey: .maximumStabilizedSpeedMetersPerSecond)
        averageStabilizedSpeedMetersPerSecond = try container.decode(Double.self, forKey: .averageStabilizedSpeedMetersPerSecond)
        freshAnchorResetCount = try container.decode(Int.self, forKey: .freshAnchorResetCount)
        worldEventCounts = try container.decode([String: Int].self, forKey: .worldEventCounts)
        semanticAudioCueCounts = try container.decode([String: Int].self, forKey: .semanticAudioCueCounts)
        audioSuppressionCount = try container.decode(Int.self, forKey: .audioSuppressionCount)
        interruptionCount = try container.decode(Int.self, forKey: .interruptionCount)
        lifecycleTransitionCount = try container.decode(Int.self, forKey: .lifecycleTransitionCount)
        startingBond = try container.decode(Int.self, forKey: .startingBond)
        endingBond = try container.decode(Int.self, forKey: .endingBond)
        bondDelta = try container.decode(Int.self, forKey: .bondDelta)
        memoryWritten = try container.decode(Bool.self, forKey: .memoryWritten)
        finalErrorCategory = try container.decodeIfPresent(FieldTestErrorCategory.self, forKey: .finalErrorCategory)
        audioDiagnostics = try container.decodeIfPresent(
            FieldTestAudioDiagnosticSummary.self,
            forKey: .audioDiagnostics
        ) ?? FieldTestAudioDiagnosticSummary()
    }
}

public struct FieldTestReceipt: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2

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
    private var recordedSparseAudioEvidence: Set<String> = []

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

    public func recordAudioDiagnostic(_ diagnostic: AudioPlaybackDiagnostic) {
        summarizeAudioDiagnostic(diagnostic)
        let entry = FieldTestEntry(
            timestamp: diagnostic.timestamp,
            category: .audioDiagnostic,
            code: diagnostic.kind.rawValue,
            audioDiagnosticKind: diagnostic.kind,
            audioCueKind: diagnostic.cueKind,
            audioDiagnosticReasonCode: diagnostic.reasonCode,
            audioDiagnosticChannel: diagnostic.channel,
            audioRouteCategory: diagnostic.routeCategory,
            audioRouteChangeReason: diagnostic.routeChangeReason,
            audioInterruptionResumeDisposition: diagnostic.interruptionResumeDisposition,
            audioSessionPolicy: diagnostic.sessionPolicy
        )
        switch diagnostic.kind {
        case .playbackStopRequested, .playbackFadeRequested, .playbackStopped:
            appendRequired(entry)
        case .cueReceived:
            appendSparse(entry, key: "cueReceived")
        case .plannerSuppressed:
            appendSparse(entry, key: "plannerSuppressed:\(diagnostic.reasonCode?.rawValue ?? "unknown")")
        case .assetMissing,
             .playerInitializationFailed,
             .audioSessionConfigurationFailed,
             .playerObservedActive,
             .playbackDidNotStart:
            appendSparse(entry, key: diagnostic.kind.rawValue)
        case .playbackInterrupted, .playbackInterruptionEnded:
            appendSparse(
                entry,
                key: "interruption:\(diagnostic.kind.rawValue):\(diagnostic.reasonCode?.rawValue ?? "none"):\(diagnostic.interruptionResumeDisposition?.rawValue ?? "none")"
            )
        case .routeChanged:
            appendSparse(
                entry,
                key: "route:\(diagnostic.routeChangeReason?.rawValue ?? "unknown")"
            )
        default:
            break
        }
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

    private func summarizeAudioDiagnostic(_ diagnostic: AudioPlaybackDiagnostic) {
        if let routeCategory = diagnostic.routeCategory {
            receipt.summary.audioDiagnostics.lastRouteCategory = routeCategory
        }

        switch diagnostic.kind {
        case .cueReceived:
            increment(&receipt.summary.audioDiagnostics.cueReceiptCounts, key: diagnostic.cueKind?.rawValue)
        case .plannerAccepted:
            increment(&receipt.summary.audioDiagnostics.plannerAcceptedCueCounts, key: diagnostic.cueKind?.rawValue)
        case .plannerSuppressed:
            receipt.summary.audioSuppressionCount += 1
            increment(&receipt.summary.audioDiagnostics.suppressionReasonCounts, key: diagnostic.reasonCode?.rawValue)
        case .assetLookupStarted, .assetResolved, .assetMissing:
            increment(&receipt.summary.audioDiagnostics.assetLifecycleCounts, key: diagnostic.kind.rawValue)
        case .audioSessionConfigurationStarted, .audioSessionConfigured, .audioSessionConfigurationFailed:
            increment(&receipt.summary.audioDiagnostics.audioSessionLifecycleCounts, key: diagnostic.kind.rawValue)
        case .playerInitialized, .playerInitializationFailed:
            increment(&receipt.summary.audioDiagnostics.playerLifecycleCounts, key: diagnostic.kind.rawValue)
        case .playbackRequested,
             .playRequestAccepted,
             .playbackDidNotStart,
             .playerObservedActive,
             .playbackFinished,
             .playbackDecodeError,
             .playbackSuspended,
             .playbackResumed,
             .playbackStopRequested,
             .playbackFadeRequested,
             .playbackStopped:
            increment(&receipt.summary.audioDiagnostics.playbackLifecycleCounts, key: diagnostic.kind.rawValue)
            if diagnostic.kind == .playbackStopRequested {
                receipt.summary.audioDiagnostics.stopCount += 1
            } else if diagnostic.kind == .playbackFadeRequested {
                receipt.summary.audioDiagnostics.fadeCount += 1
            }
        case .playbackInterrupted, .playbackInterruptionEnded:
            increment(&receipt.summary.audioDiagnostics.interruptionEventCounts, key: diagnostic.kind.rawValue)
        case .routeChanged:
            increment(&receipt.summary.audioDiagnostics.routeChangeReasonCounts, key: diagnostic.routeChangeReason?.rawValue)
        }
    }

    private func append(_ entry: FieldTestEntry) {
        guard receipt.timeline.count < Self.maximumTimelineEntries else { return }
        receipt.timeline.append(entry)
    }

    private func appendSparse(_ entry: FieldTestEntry, key: String) {
        guard recordedSparseAudioEvidence.insert(key).inserted else { return }
        append(entry)
    }

    private func appendRequired(_ entry: FieldTestEntry) {
        if receipt.timeline.count == Self.maximumTimelineEntries {
            let isTerminalEntry = entry.category == .memoryWriteResult || entry.category == .sessionCompleted
            let removableIndex = receipt.timeline.lastIndex {
                return $0.category != .memoryWriteResult
                    && $0.category != .sessionCompleted
                    && !($0.category == .audioLifecycleAction && $0.code == "stop")
                    && !($0.category == .audioDiagnostic && isRequiredAudioDiagnostic($0.audioDiagnosticKind))
            }
            if let removableIndex {
                receipt.timeline.remove(at: removableIndex)
            } else if isTerminalEntry {
                let fallbackIndex = receipt.timeline.lastIndex {
                    $0.category != .memoryWriteResult && $0.category != .sessionCompleted
                }
                if let fallbackIndex {
                    receipt.timeline.remove(at: fallbackIndex)
                }
            }
        }
        receipt.timeline.append(entry)
    }

    private func isRequiredAudioDiagnostic(_ kind: AudioPlaybackDiagnosticKind?) -> Bool {
        switch kind {
        case .playbackStopRequested, .playbackFadeRequested, .playbackStopped:
            true
        default:
            false
        }
    }

    private func finiteNonnegative(_ value: Double) -> Double {
        max(0, value.isFinite ? value : 0)
    }

    private func increment(_ counts: inout [String: Int], key: String?) {
        guard let key else { return }
        counts[key, default: 0] += 1
    }
}
