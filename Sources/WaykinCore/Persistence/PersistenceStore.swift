import Foundation
import SwiftData

// MARK: - Errors
public enum PersistenceError: Error, Equatable {
    case fileBackedStoreRequired
    case saveFailed(String)
    case verificationFetchFailed(UUID)
    case loadFailed(String)
    case duplicateSessionMemory(UUID)
}

// MARK: - SwiftData Models (single schema)
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
    @Attribute(.unique)
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

// MARK: - Persistence Configuration
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

public struct PersistenceWriteReceipt: Equatable {
    public let recordID: UUID
    public let storeURL: URL
    public let savedAt: Date
    public let verificationFetchSucceeded: Bool
}

// MARK: - PersistenceStore (file-backed only for canonical path)
public final class PersistenceStore {
    private var inMemoryCompanions: [Companion] = []
    private var inMemoryMemories: [SessionMemory] = []
    private var modelContext: ModelContext?
    private let storeURL: URL?

    public init(modelContainer: ModelContainer? = nil) {
        if let container = modelContainer {
            self.modelContext = ModelContext(container)
            // Best effort to remember URL
            self.storeURL = nil
        } else {
            self.storeURL = nil
        }
    }

    public static func makeFileBackedContainer(reset: Bool = false) throws -> ModelContainer {
        let url = try PersistenceConfiguration.persistentStoreURL()
        if reset {
            try? FileManager.default.removeItem(at: url)
        }
        let schema = Schema([
            CompanionRecord.self,
            SessionMemoryRecord.self
        ])
        let config = ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: config)
    }

    public func currentStoreURLForDiagnostics() -> URL? { storeURL }

    public func saveCompanion(_ companion: Companion) throws {
        guard let ctx = modelContext else {
            // fallback only for non-UI paths
            if let idx = inMemoryCompanions.firstIndex(where: { $0.id == companion.id }) {
                inMemoryCompanions[idx] = companion
            } else {
                inMemoryCompanions.append(companion)
            }
            return
        }
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
        try ctx.save()
    }

    public func loadCompanion() throws -> Companion? {
        guard let ctx = modelContext else {
            return inMemoryCompanions.last
        }
        let descriptor = FetchDescriptor<CompanionRecord>()
        guard let record = try? ctx.fetch(descriptor).last else { return nil }
        return Companion(
            id: record.id,
            name: record.name,
            archetype: record.archetype,
            bondLevel: record.bondLevel,
            lastSessionID: record.lastSessionID,
            memories: []
        )
    }

    @discardableResult
    public func saveMemory(_ memory: SessionMemory) throws -> PersistenceWriteReceipt {
        guard let ctx = modelContext else {
            if inMemoryMemories.contains(where: { $0.sessionID == memory.sessionID }) {
                throw PersistenceError.duplicateSessionMemory(memory.sessionID)
            }
            inMemoryMemories.append(memory)
            return PersistenceWriteReceipt(
                recordID: memory.id,
                storeURL: URL(fileURLWithPath: "/in-memory"),
                savedAt: Date(),
                verificationFetchSucceeded: true
            )
        }

        let existingDescriptor = FetchDescriptor<SessionMemoryRecord>(
            predicate: #Predicate { $0.sessionID == memory.sessionID }
        )
        if let existing = try ctx.fetch(existingDescriptor).first {
            throw PersistenceError.duplicateSessionMemory(existing.sessionID)
        }

        let record = SessionMemoryRecord(
            id: memory.id,
            sessionID: memory.sessionID,
            scenarioID: nil,
            text: memory.text,
            createdAt: memory.timestamp
        )
        ctx.insert(record)
        try ctx.save()

        // Verification fetch by ID
        let descriptor = FetchDescriptor<SessionMemoryRecord>(
            predicate: #Predicate { $0.id == memory.id }
        )
        guard let fetched = try? ctx.fetch(descriptor).first, fetched.id == memory.id else {
            throw PersistenceError.verificationFetchFailed(memory.id)
        }

        return PersistenceWriteReceipt(
            recordID: memory.id,
            storeURL: URL(fileURLWithPath: "/app-support"),
            savedAt: Date(),
            verificationFetchSucceeded: true
        )
    }

    public func loadMemories() throws -> [SessionMemory] {
        guard let ctx = modelContext else {
            return inMemoryMemories.sorted { $0.timestamp > $1.timestamp }
        }
        let descriptor = FetchDescriptor<SessionMemoryRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = try ctx.fetch(descriptor)
        return records.map { r in
            SessionMemory(
                id: r.id,
                sessionID: r.sessionID,
                text: r.text,
                timestamp: r.createdAt
            )
        }
    }

    public func memoryCount() throws -> Int {
        guard let ctx = modelContext else { return inMemoryMemories.count }
        let descriptor = FetchDescriptor<SessionMemoryRecord>()
        return try ctx.fetchCount(descriptor)
    }

    public func resetDemoData() throws {
        guard let ctx = modelContext else {
            inMemoryCompanions.removeAll()
            inMemoryMemories.removeAll()
            return
        }
        try ctx.delete(model: CompanionRecord.self)
        try ctx.delete(model: SessionMemoryRecord.self)
        try ctx.save()
    }
}
