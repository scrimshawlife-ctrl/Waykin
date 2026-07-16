import Foundation
import SwiftData

// SwiftData models (visible to iOS app target)
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

// PersistenceStore supports both SwiftData (for iOS app) and in-memory (for package/CLI/tests)
public final class PersistenceStore {
    private var inMemoryCompanions: [Companion] = []
    private var inMemoryMemories: [SessionMemory] = []
    private var modelContext: ModelContext?

    public init(modelContainer: ModelContainer? = nil) {
        if let container = modelContainer {
            self.modelContext = ModelContext(container)
        }
    }

    public func saveCompanion(_ companion: Companion) {
        if let ctx = modelContext {
            // Upsert CompanionRecord
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

    public func saveMemory(_ memory: SessionMemory) {
        if let ctx = modelContext {
            let record = SessionMemoryRecord(
                sessionID: memory.sessionID,
                text: memory.text
            )
            ctx.insert(record)
            try? ctx.save()
        } else {
            inMemoryMemories.append(memory)
        }
    }

    public func loadMemories() -> [SessionMemory] {
        if let ctx = modelContext {
            let descriptor = FetchDescriptor<SessionMemoryRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            if let records = try? ctx.fetch(descriptor) {
                return records.map { SessionMemory(sessionID: $0.sessionID, text: $0.text) }
            }
            return []
        } else {
            return inMemoryMemories.sorted { $0.timestamp > $1.timestamp }
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
