import Foundation
import SwiftData

@Model
final class CompanionRecord {
    var id: UUID
    var name: String
    var archetype: String
    var bondLevel: Int
    var lastSessionID: UUID?
    
    init(id: UUID, name: String, archetype: String, bondLevel: Int, lastSessionID: UUID? = nil) {
        self.id = id
        self.name = name
        self.archetype = archetype
        self.bondLevel = bondLevel
        self.lastSessionID = lastSessionID
    }
}

@Model
final class SessionMemoryRecord {
    var id: UUID
    var sessionID: UUID
    var text: String
    var timestamp: Date
    
    init(id: UUID, sessionID: UUID, text: String, timestamp: Date) {
        self.id = id
        self.sessionID = sessionID
        self.text = text
        self.timestamp = timestamp
    }
}

@MainActor
public final class PersistenceStore {
    private var modelContext: ModelContext?
    
    public init() {
        // Context will be injected from the app
    }
    
    public func configure(context: ModelContext) {
        self.modelContext = context
    }
    
    public func saveCompanion(_ companion: Companion) {
        guard let context = modelContext else { return }
        let record = CompanionRecord(
            id: companion.id,
            name: companion.name,
            archetype: companion.archetype,
            bondLevel: companion.bondLevel,
            lastSessionID: companion.lastSessionID
        )
        context.insert(record)
        try? context.save()
    }
    
    public func loadCompanion() -> Companion? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CompanionRecord>()
        if let record = try? context.fetch(descriptor).first {
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
    }
    
    public func saveMemory(_ memory: SessionMemory) {
        guard let context = modelContext else { return }
        let record = SessionMemoryRecord(
            id: memory.id,
            sessionID: memory.sessionID,
            text: memory.text,
            timestamp: memory.timestamp
        )
        context.insert(record)
        try? context.save()
    }
    
    public func loadMemories() -> [SessionMemory] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SessionMemoryRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        if let records = try? context.fetch(descriptor) {
            return records.map { SessionMemory(id: $0.id, sessionID: $0.sessionID, text: $0.text, timestamp: $0.timestamp) }
        }
        return []
    }
}
