import Foundation
import SwiftData

// MARK: - SwiftData Models
@Model
public final class CompanionRecord {
    public var id: UUID
    public var name: String
    public var archetype: String
    public var bondLevel: Int
    public var lastSessionID: UUID?

    public init(id: UUID = UUID(), name: String, archetype: String, bondLevel: Int, lastSessionID: UUID? = nil) {
        self.id = id
        self.name = name
        self.archetype = archetype
        self.bondLevel = bondLevel
        self.lastSessionID = lastSessionID
    }
}

@Model
public final class SessionMemoryRecord {
    public var id: UUID
    public var sessionID: UUID
    public var scenarioID: String?
    public var text: String
    public var createdAt: Date

    public init(id: UUID = UUID(), sessionID: UUID, scenarioID: String? = nil, text: String, createdAt: Date = Date()) {
        self.id = id
        self.sessionID = sessionID
        self.scenarioID = scenarioID
        self.text = text
        self.createdAt = createdAt
    }
}

// MARK: - Persistence Configuration (stable URL)
public enum PersistenceConfiguration {
    public static let storeFileName = "Waykin.store"

    public static func persistentStoreURL(fileManager: FileManager = .default) throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let waykinDir = appSupport.appendingPathComponent("Waykin", isDirectory: true)
        try fileManager.createDirectory(at: waykinDir, withIntermediateDirectories: true)
        return waykinDir.appendingPathComponent(storeFileName)
    }
}

// MARK: - Persistence Write Receipt (for diagnostics)
public struct PersistenceWriteReceipt {
    public let recordID: UUID
    public let storeURL: URL
    public let savedAt: Date
    public let verificationFetchSucceeded: Bool
}

// MARK: - PersistenceStore
public final class PersistenceStore {
    private var inMemoryCompanions: [Companion] = []
    private var inMemoryMemories: [SessionMemory] = []
    private var modelContext: ModelContext?
    private var currentStoreURL: URL?

    public init(modelContainer: ModelContainer? = nil) {
        if let container = modelContainer {
            self.modelContext = ModelContext(container)
            // Best-effort capture of URL if possible
        }
    }

    /// For UI tests: create a container with explicit stable URL
    public static func makeFileBackedContainer(reset: Bool = false) throws -> ModelContainer {
        let url = try PersistenceConfiguration.persistentStoreURL()
        if reset {
            try? FileManager.default.removeItem(at: url)
        }
        let config = ModelConfiguration(url: url)
        return try ModelContainer(for: CompanionRecord.self, SessionMemoryRecord.self, configurations: config)
    }

    public func currentStoreURLForDiagnostics() -> URL? {
        return currentStoreURL
    }

    public func saveCompanion(_ companion: Companion) {
        if let ctx = modelContext {
            let descriptor = FetchDescriptor<CompanionRecord>(predicate: #Predicate { $0.id == companion.id })
            if let existing = try? ctx.fetch(descriptor).first {
                existing.name = companion.name
                existing.archetype = companion.archetype
                existing.bondLevel = companion.bondLevel
                existing.lastSessionID = companion.lastSessionID
            } else {
                let record = CompanionRecord(
                    id: companion.id,
                    name: companion.name,
                    archetype: companion.archetype,
                    bondLevel: companion.bondLevel,
                    lastSessionID: companion.lastSessionID
                )
                ctx.insert(record)
            }
            try? ctx.save()
        } else {
            if let idx = inMemoryCompanions.firstIndex(where: { $0.id == companion.id }) {
                inMemoryCompanions[idx] = companion
            } else {
                inMemoryCompanions.append(companion)
            }
        }
    }

    public func loadCompanion() -> Companion? {
        if let ctx = modelContext {
            let descriptor = FetchDescriptor<CompanionRecord>()
            if let record = try? ctx.fetch(descriptor).last {
                return Companion(
                    id: record.id,
                    name: record.name,
                    archetype: record.archetype,
                    bondLevel: record.bondLevel,
                    lastSessionID: record.lastSessionID,
                    memories: []
                )
            }
            return nil
        } else {
            return inMemoryCompanions.last
        }
    }

    @discardableResult
    public func saveMemory(_ memory: SessionMemory) -> PersistenceWriteReceipt? {
        if let ctx = modelContext {
            let record = SessionMemoryRecord(
                sessionID: memory.sessionID,
                scenarioID: nil,
                text: memory.text,
                createdAt: memory.timestamp
            )
            ctx.insert(record)
            try? ctx.save()

            // Verify immediately
            let id = record.id
            let fetchDesc = FetchDescriptor<SessionMemoryRecord>(predicate: #Predicate { $0.id == id })
            let verificationSucceeded = (try? ctx.fetch(fetchDesc).first) != nil

            return PersistenceWriteReceipt(
                recordID: id,
                storeURL: currentStoreURL ?? URL(fileURLWithPath: "/unknown"),
                savedAt: Date(),
                verificationFetchSucceeded: verificationSucceeded
            )
        } else {
            inMemoryMemories.append(memory)
            return nil
        }
    }

    public func loadMemories() -> [SessionMemory] {
        if let ctx = modelContext {
            let descriptor = FetchDescriptor<SessionMemoryRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            if let records = try? ctx.fetch(descriptor) {
                return records.map {
                    SessionMemory(
                        id: $0.id,
                        sessionID: $0.sessionID,
                        text: $0.text,
                        timestamp: $0.createdAt
                    )
                }
            }
            return []
        } else {
            return inMemoryMemories.sorted { $0.timestamp > $1.timestamp }
        }
    }

    public func memoryCount() -> Int {
        if let ctx = modelContext {
            let descriptor = FetchDescriptor<SessionMemoryRecord>()
            return (try? ctx.fetchCount(descriptor)) ?? 0
        } else {
            return inMemoryMemories.count
        }
    }

    public func resetDemoData() {
        if let ctx = modelContext {
            try? ctx.delete(model: CompanionRecord.self)
            try? ctx.delete(model: SessionMemoryRecord.self)
            try? ctx.save()
        } else {
            inMemoryCompanions.removeAll()
            inMemoryMemories.removeAll()
        }
    }
}
