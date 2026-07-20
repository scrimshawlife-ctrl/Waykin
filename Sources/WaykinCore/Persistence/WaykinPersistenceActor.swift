import Foundation
import SwiftData

/// Serialized SwiftData authority for companion + session memory (WP-DB3).
///
/// Use `WaykinPersistenceGateway` to attach store URL / availability metadata
/// and expose `WaykinPersistenceServing`. The `@ModelActor` owns `modelContext`.
@ModelActor
public actor WaykinPersistenceActor {
    public func loadCanonicalCompanion() throws -> Companion? {
        try PersistenceContextOperations.loadCompanion(context: modelContext)
    }

    public func saveCompanion(_ companion: Companion) throws {
        try PersistenceContextOperations.saveCompanion(companion, context: modelContext)
    }

    public func saveMemory(
        _ memory: SessionMemory,
        storeURL: URL?
    ) throws -> PersistenceWriteReceipt {
        try PersistenceContextOperations.saveMemory(
            memory,
            context: modelContext,
            storeURL: storeURL
        )
    }

    public func memory(for sessionID: UUID) throws -> SessionMemory? {
        try PersistenceContextOperations.memory(for: sessionID, context: modelContext)
    }

    public func recentMemories(limit: Int) throws -> [SessionMemory] {
        let all = try PersistenceContextOperations.loadMemories(context: modelContext)
        guard limit > 0 else { return [] }
        return Array(all.prefix(limit))
    }

    public func memoryCount() throws -> Int {
        try PersistenceContextOperations.memoryCount(context: modelContext)
    }

    public func resetDemoData() throws {
        try PersistenceContextOperations.resetDemoData(context: modelContext)
    }
}

/// Sendable gateway: ModelActor + availability/URL metadata (WP-DB3).
public struct WaykinPersistenceGateway: WaykinPersistenceServing, Sendable {
    private let actor: WaykinPersistenceActor
    private let availabilityValue: PersistenceAvailability
    private let storeURLValue: URL?

    public init(
        modelContainer: ModelContainer,
        storeURL: URL?,
        availability: PersistenceAvailability
    ) {
        self.actor = WaykinPersistenceActor(modelContainer: modelContainer)
        self.availabilityValue = availability
        self.storeURLValue = storeURL
    }

    /// Convenience from factory open result.
    public static func fileBacked(reset: Bool = false) throws -> (gateway: WaykinPersistenceGateway, container: ModelContainer) {
        let opened = try WaykinPersistenceContainerFactory.makeFileBacked(reset: reset)
        let gateway = WaykinPersistenceGateway(
            modelContainer: opened.container,
            storeURL: opened.storeURL,
            availability: .availableFileBacked
        )
        return (gateway, opened.container)
    }

    public static func inMemory() throws -> (gateway: WaykinPersistenceGateway, container: ModelContainer) {
        let container = try WaykinPersistenceContainerFactory.makeInMemory()
        let gateway = WaykinPersistenceGateway(
            modelContainer: container,
            storeURL: nil,
            availability: .availableInMemory
        )
        return (gateway, container)
    }

    public var availability: PersistenceAvailability {
        get async { availabilityValue }
    }

    public var storeURL: URL? {
        get async { storeURLValue }
    }

    public func loadCanonicalCompanion() async throws -> Companion? {
        try await actor.loadCanonicalCompanion()
    }

    public func saveCompanion(_ companion: Companion) async throws {
        try await actor.saveCompanion(companion)
    }

    public func saveMemory(_ memory: SessionMemory) async throws -> PersistenceWriteReceipt {
        try await actor.saveMemory(memory, storeURL: storeURLValue)
    }

    public func memory(for sessionID: UUID) async throws -> SessionMemory? {
        try await actor.memory(for: sessionID)
    }

    public func recentMemories(limit: Int) async throws -> [SessionMemory] {
        try await actor.recentMemories(limit: limit)
    }

    public func memoryCount() async throws -> Int {
        try await actor.memoryCount()
    }

    public func resetDemoData() async throws {
        try await actor.resetDemoData()
    }
}

// MARK: - Shared context operations (store + actor)

/// Pure ModelContext operations shared by `PersistenceStore` (sync tests) and
/// `WaykinPersistenceActor` (production serialized path). No gameplay rules.
enum PersistenceContextOperations {
    static func saveCompanion(_ companion: Companion, context: ModelContext) throws {
        do {
            let id = companion.id
            let descriptor = FetchDescriptor<CompanionRecord>(predicate: #Predicate { $0.id == id })
            if let existing = try context.fetch(descriptor).first {
                existing.name = companion.name
                existing.archetype = companion.archetype
                existing.bondLevel = companion.bondLevel
                existing.lastSessionID = companion.lastSessionID
            } else {
                context.insert(
                    CompanionRecord(
                        id: companion.id,
                        name: companion.name,
                        archetype: companion.archetype,
                        bondLevel: companion.bondLevel,
                        lastSessionID: companion.lastSessionID
                    )
                )
            }
            try context.save()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.saveFailed("companion")
        }
    }

    static func loadCompanion(context: ModelContext) throws -> Companion? {
        do {
            let liraID = CanonicalCompanionIdentity.liraID
            let byID = FetchDescriptor<CompanionRecord>(predicate: #Predicate { $0.id == liraID })
            if let record = try context.fetch(byID).first {
                return mapCompanion(record)
            }

            let legacyRecords = try context.fetch(FetchDescriptor<CompanionRecord>())
            guard !legacyRecords.isEmpty else { return nil }

            let winner = legacyRecords.sorted { a, b in
                if a.bondLevel != b.bondLevel { return a.bondLevel > b.bondLevel }
                return a.id.uuidString < b.id.uuidString
            }.first!

            let promoted = CompanionRecord(
                id: liraID,
                name: winner.name,
                archetype: winner.archetype,
                bondLevel: winner.bondLevel,
                lastSessionID: winner.lastSessionID
            )
            for record in legacyRecords {
                context.delete(record)
            }
            context.insert(promoted)
            try context.save()
            return mapCompanion(promoted)
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed("companion")
        }
    }

    static func saveMemory(
        _ memory: SessionMemory,
        context: ModelContext,
        storeURL: URL?
    ) throws -> PersistenceWriteReceipt {
        do {
            let sessionID = memory.sessionID
            let existingDescriptor = FetchDescriptor<SessionMemoryRecord>(
                predicate: #Predicate { $0.sessionID == sessionID }
            )
            if let existing = try context.fetch(existingDescriptor).first {
                throw PersistenceError.duplicateSessionMemory(existing.sessionID)
            }

            let record = SessionMemoryRecord(
                id: memory.id,
                sessionID: memory.sessionID,
                scenarioID: nil,
                text: memory.text,
                createdAt: memory.timestamp
            )
            context.insert(record)
            try context.save()

            let memoryID = memory.id
            let descriptor = FetchDescriptor<SessionMemoryRecord>(
                predicate: #Predicate { $0.id == memoryID }
            )
            guard let fetched = try context.fetch(descriptor).first, fetched.id == memory.id else {
                throw PersistenceError.verificationFetchFailed(memory.id)
            }

            return PersistenceWriteReceipt(
                recordID: memory.id,
                storeURL: storeURL ?? URL(fileURLWithPath: "/unknown-store"),
                savedAt: Date(),
                verificationFetchSucceeded: true
            )
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.saveFailed("memory")
        }
    }

    static func memory(for sessionID: UUID, context: ModelContext) throws -> SessionMemory? {
        do {
            let descriptor = FetchDescriptor<SessionMemoryRecord>(
                predicate: #Predicate { $0.sessionID == sessionID }
            )
            guard let record = try context.fetch(descriptor).first else { return nil }
            return SessionMemory(
                id: record.id,
                sessionID: record.sessionID,
                text: record.text,
                timestamp: record.createdAt
            )
        } catch {
            throw PersistenceError.fetchFailed("memory")
        }
    }

    static func loadMemories(context: ModelContext) throws -> [SessionMemory] {
        do {
            let descriptor = FetchDescriptor<SessionMemoryRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor).map { r in
                SessionMemory(
                    id: r.id,
                    sessionID: r.sessionID,
                    text: r.text,
                    timestamp: r.createdAt
                )
            }
        } catch {
            throw PersistenceError.fetchFailed("memories")
        }
    }

    static func memoryCount(context: ModelContext) throws -> Int {
        do {
            return try context.fetchCount(FetchDescriptor<SessionMemoryRecord>())
        } catch {
            throw PersistenceError.fetchFailed("memoryCount")
        }
    }

    static func resetDemoData(context: ModelContext) throws {
        do {
            try context.delete(model: CompanionRecord.self)
            try context.delete(model: SessionMemoryRecord.self)
            try context.save()
        } catch {
            throw PersistenceError.saveFailed("reset")
        }
    }

    private static func mapCompanion(_ record: CompanionRecord) -> Companion {
        Companion(
            id: record.id,
            name: record.name,
            archetype: record.archetype,
            bondLevel: record.bondLevel,
            lastSessionID: record.lastSessionID,
            memories: []
        )
    }
}
