import Foundation

// Field-test receipts, a pattern adopted from the first Waykin implementation:
// every session produces a machine-readable diagnostic record, so real-world
// walks can be validated after the fact (GPS quality, event flow, outcome)
// without a debugger attached.

public enum SessionMode: String, Codable, Equatable {
    case simulated   // waykin-sim / scripted GPS
    case physical    // real device, real GPS
}

/// One completed session's diagnostic record.
public struct SessionReceipt: Codable, Identifiable, Equatable {
    public var id: UUID
    public var mode: SessionMode
    public var companionName: String
    public var experienceID: String
    public var experienceName: String
    public var locationName: String

    public var startedAt: Date
    public var endedAt: Date
    public var durationSeconds: TimeInterval
    public var distanceMeters: Double
    public var averagePaceSecondsPerKm: Double?
    public var activity: String
    public var sampleCount: Int

    /// How many of each experience-event kind fired ("dialogue", "milestone",
    /// "audio.chime", "behavior.run", …). The tension channels record their
    /// peak instead: threat.max / ghostGap.max.
    public var eventCounts: [String: Int]
    public var peakThreat: Double?
    public var maxGhostGapMeters: Double?

    public var succeeded: Bool
    public var bondDelta: Int
    public var memoryWritten: Bool
    public var memoryText: String?
    public var summaryLine: String

    public init(id: UUID = UUID(), mode: SessionMode, companionName: String,
                experienceID: String, experienceName: String, locationName: String,
                startedAt: Date, endedAt: Date, durationSeconds: TimeInterval,
                distanceMeters: Double, averagePaceSecondsPerKm: Double?,
                activity: String, sampleCount: Int,
                eventCounts: [String: Int], peakThreat: Double?, maxGhostGapMeters: Double?,
                succeeded: Bool, bondDelta: Int, memoryWritten: Bool,
                memoryText: String?, summaryLine: String) {
        self.id = id
        self.mode = mode
        self.companionName = companionName
        self.experienceID = experienceID
        self.experienceName = experienceName
        self.locationName = locationName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
        self.activity = activity
        self.sampleCount = sampleCount
        self.eventCounts = eventCounts
        self.peakThreat = peakThreat
        self.maxGhostGapMeters = maxGhostGapMeters
        self.succeeded = succeeded
        self.bondDelta = bondDelta
        self.memoryWritten = memoryWritten
        self.memoryText = memoryText
        self.summaryLine = summaryLine
    }
}

/// Accumulates events during a live session and finalizes into a receipt.
/// Feed it the same ExperienceEvent stream the presentation layer consumes.
public final class SessionReceiptBuilder {
    private let mode: SessionMode
    private var eventCounts: [String: Int] = [:]
    private var peakThreat: Double?
    private var maxGhostGap: Double?

    public init(mode: SessionMode) {
        self.mode = mode
    }

    public func record(_ events: [ExperienceEvent]) {
        for event in events {
            switch event {
            case .dialogue: bump("dialogue")
            case .milestone: bump("milestone")
            case .companionBehavior(let behavior): bump("behavior.\(behavior.rawValue)")
            case .audio(let cue): bump("audio.\(cue.rawValue)")
            case .threatLevel(let threat):
                peakThreat = max(peakThreat ?? 0, threat)
            case .ghostDistance(let gap):
                maxGhostGap = max(maxGhostGap ?? -.infinity, gap)
            }
        }
    }

    public func finalize(session: MovementSession,
                         outcome: ExperienceOutcome,
                         companionName: String,
                         experienceID: String,
                         experienceName: String,
                         locationName: String,
                         memory: Memory?) -> SessionReceipt {
        SessionReceipt(
            mode: mode,
            companionName: companionName,
            experienceID: experienceID,
            experienceName: experienceName,
            locationName: locationName,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            durationSeconds: session.durationSeconds,
            distanceMeters: session.distanceMeters,
            averagePaceSecondsPerKm: session.averagePaceSecondsPerKm,
            activity: session.activity.rawValue,
            sampleCount: session.route.count,
            eventCounts: eventCounts,
            peakThreat: peakThreat,
            maxGhostGapMeters: maxGhostGap == -.infinity ? nil : maxGhostGap,
            succeeded: outcome.succeeded,
            bondDelta: outcome.bondDelta,
            memoryWritten: memory != nil,
            memoryText: memory?.text,
            summaryLine: outcome.summaryLine
        )
    }

    private func bump(_ key: String) {
        eventCounts[key, default: 0] += 1
    }
}

/// Writes receipts as pretty JSON files (one per session) and reads them back.
public final class FileReceiptStore {
    public let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL) {
        self.directory = directory
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    @discardableResult
    public func save(_ receipt: SessionReceipt) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: receipt.endedAt)
            .replacingOccurrences(of: ":", with: "-")
        let url = directory.appendingPathComponent("receipt-\(stamp)-\(receipt.id.uuidString.prefix(8)).json")
        try encoder.encode(receipt).write(to: url, options: .atomic)
        return url
    }

    public func loadAll() -> [SessionReceipt] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(SessionReceipt.self, from: Data(contentsOf: $0)) }
            .sorted { $0.endedAt > $1.endedAt }
    }
}
