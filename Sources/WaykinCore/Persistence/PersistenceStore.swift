import Foundation
import SwiftData

// MARK: - Errors

public enum PersistenceError: Error, Equatable, Sendable {
    case fileBackedStoreRequired
    case saveFailed(String)
    case verificationFetchFailed(UUID)
    case loadFailed(String)
    case fetchFailed(String)
    case notFound(String)
    case migrationFailed(String)
    case duplicateSessionMemory(UUID)
    case unavailable
}

// MARK: - Availability (WP-DB1)

/// Durable persistence health — never claim file-backed success when degraded/failed.
public enum PersistenceAvailability: String, Equatable, Sendable {
    /// Application Support `Waykin.store` is open and writable.
    case availableFileBacked
    /// Ephemeral / in-memory container (tests or intentional non-durable mode).
    case availableInMemory
    /// Could not open the file-backed store; running on an in-memory substitute.
    case degraded
    /// No usable store (operations must fail visibly).
    case failed
}

// MARK: - Canonical Lira identity (WP-DB2)

/// Stable product identity for the solo-MVP companion row.
public enum CanonicalCompanionIdentity {
    /// Fixed UUID — not random per install. Legacy rows are promoted to this id.
    public static let liraID = UUID(uuidString: "6C697261-0001-4000-8000-000000000001")!

    public static func defaultCompanion(bondLevel: Int = 12) -> Companion {
        Companion(
            id: liraID,
            name: "Lira",
            archetype: "explorer",
            bondLevel: bondLevel,
            lastSessionID: nil,
            memories: []
        )
    }
}

// MARK: - Versioned schema (WP-DB1)

public enum WaykinSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [CompanionRecord.self, SessionMemoryRecord.self]
    }
}

public enum WaykinMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [WaykinSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Container factory (WP-DB1)

/// Single entry point for production, tests, and degraded fallback containers.
public enum WaykinPersistenceContainerFactory {
    public static func schema() -> Schema {
        Schema(versionedSchema: WaykinSchemaV1.self)
    }

    /// File-backed Application Support store (or explicit URL for tests).
    public static func makeFileBacked(
        url: URL? = nil,
        reset: Bool = false,
        fileManager: FileManager = .default
    ) throws -> (container: ModelContainer, storeURL: URL) {
        let storeURL = try url ?? PersistenceConfiguration.persistentStoreURL(fileManager: fileManager)
        if reset {
            try? fileManager.removeItem(at: storeURL)
        }
        let schema = schema()
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: WaykinMigrationPlan.self,
                configurations: [config]
            )
            return (container, storeURL)
        } catch {
            throw PersistenceError.migrationFailed(String(describing: type(of: error)))
        }
    }

    /// In-memory container for unit tests and explicit degraded mode.
    public static func makeInMemory() throws -> ModelContainer {
        let schema = schema()
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: WaykinMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            throw PersistenceError.migrationFailed(String(describing: type(of: error)))
        }
    }
}

// MARK: - SwiftData Models (WaykinSchemaV1)

@Model
public final class CompanionRecord {
    @Attribute(.unique)
    public var id: UUID
    public var name: String
    public var archetype: String
    public var bondLevel: Int
    public var lastSessionID: UUID?

    public init(id: UUID = CanonicalCompanionIdentity.liraID, name: String, archetype: String, bondLevel: Int, lastSessionID: UUID? = nil) {
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
    /// Durable completion idempotency key (WP-DB2).
    @Attribute(.unique)
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

public struct PersistenceWriteReceipt: Equatable, Sendable {
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
    public private(set) var storeURL: URL?
    public private(set) var availability: PersistenceAvailability

    public init(
        modelContainer: ModelContainer? = nil,
        storeURL: URL? = nil,
        availability: PersistenceAvailability? = nil
    ) {
        if let container = modelContainer {
            self.modelContext = ModelContext(container)
            self.storeURL = storeURL
            if let availability {
                self.availability = availability
            } else if storeURL != nil {
                self.availability = .availableFileBacked
            } else {
                self.availability = .availableInMemory
            }
        } else {
            self.modelContext = nil
            self.storeURL = nil
            self.availability = availability ?? .availableInMemory
        }
    }

    /// Production / UI-test file-backed open (WP-DB1).
    public static func openFileBacked(reset: Bool = false) throws -> PersistenceStore {
        let (container, url) = try WaykinPersistenceContainerFactory.makeFileBacked(reset: reset)
        return PersistenceStore(
            modelContainer: container,
            storeURL: url,
            availability: .availableFileBacked
        )
    }

    /// Back-compat alias used by tests and app — routes through the factory.
    public static func makeFileBackedContainer(reset: Bool = false) throws -> ModelContainer {
        try WaykinPersistenceContainerFactory.makeFileBacked(reset: reset).container
    }

    /// Ephemeral store for unit tests (shared factory path).
    public static func makeEphemeral() throws -> PersistenceStore {
        let container = try WaykinPersistenceContainerFactory.makeInMemory()
        return PersistenceStore(
            modelContainer: container,
            storeURL: nil,
            availability: .availableInMemory
        )
    }

    public func currentStoreURLForDiagnostics() -> URL? { storeURL }

    public var isDurable: Bool {
        availability == .availableFileBacked
    }

    // MARK: Companion

    public func saveCompanion(_ companion: Companion) throws {
        // Always persist under the domain id the caller supplies; production uses liraID.
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            if let idx = inMemoryCompanions.firstIndex(where: { $0.id == companion.id }) {
                inMemoryCompanions[idx] = companion
            } else {
                inMemoryCompanions.removeAll { $0.id == CanonicalCompanionIdentity.liraID }
                inMemoryCompanions.append(companion)
            }
            return
        }

        do {
            let id = companion.id
            let descriptor = FetchDescriptor<CompanionRecord>(predicate: #Predicate { $0.id == id })
            if let existing = try ctx.fetch(descriptor).first {
                existing.name = companion.name
                existing.archetype = companion.archetype
                existing.bondLevel = companion.bondLevel
                existing.lastSessionID = companion.lastSessionID
            } else {
                ctx.insert(
                    CompanionRecord(
                        id: companion.id,
                        name: companion.name,
                        archetype: companion.archetype,
                        bondLevel: companion.bondLevel,
                        lastSessionID: companion.lastSessionID
                    )
                )
            }
            try ctx.save()
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.saveFailed("companion")
        }
    }

    /// Deterministic canonical Lira load (WP-DB2). Promotes legacy rows to `liraID`.
    public func loadCompanion() throws -> Companion? {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            if let canonical = inMemoryCompanions.first(where: { $0.id == CanonicalCompanionIdentity.liraID }) {
                return canonical
            }
            return inMemoryCompanions.sorted { $0.id.uuidString < $1.id.uuidString }.first
        }

        do {
            let liraID = CanonicalCompanionIdentity.liraID
            let byID = FetchDescriptor<CompanionRecord>(predicate: #Predicate { $0.id == liraID })
            if let record = try ctx.fetch(byID).first {
                return mapCompanion(record)
            }

            // Legacy: any companions — promote the richest deterministic winner.
            let legacyRecords = try ctx.fetch(FetchDescriptor<CompanionRecord>())
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
                ctx.delete(record)
            }
            ctx.insert(promoted)
            try ctx.save()
            return mapCompanion(promoted)
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed("companion")
        }
    }

    // MARK: Session memory

    @discardableResult
    public func saveMemory(_ memory: SessionMemory) throws -> PersistenceWriteReceipt {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
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

        do {
            let sessionID = memory.sessionID
            let existingDescriptor = FetchDescriptor<SessionMemoryRecord>(
                predicate: #Predicate { $0.sessionID == sessionID }
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

            let memoryID = memory.id
            let descriptor = FetchDescriptor<SessionMemoryRecord>(
                predicate: #Predicate { $0.id == memoryID }
            )
            guard let fetched = try ctx.fetch(descriptor).first, fetched.id == memory.id else {
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

    public func loadMemories() throws -> [SessionMemory] {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            return inMemoryMemories.sorted { $0.timestamp > $1.timestamp }
        }
        do {
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
        } catch {
            throw PersistenceError.fetchFailed("memories")
        }
    }

    public func memoryCount() throws -> Int {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            return inMemoryMemories.count
        }
        do {
            return try ctx.fetchCount(FetchDescriptor<SessionMemoryRecord>())
        } catch {
            throw PersistenceError.fetchFailed("memoryCount")
        }
    }

    public func resetDemoData() throws {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            inMemoryCompanions.removeAll()
            inMemoryMemories.removeAll()
            return
        }
        do {
            try ctx.delete(model: CompanionRecord.self)
            try ctx.delete(model: SessionMemoryRecord.self)
            try ctx.save()
        } catch {
            throw PersistenceError.saveFailed("reset")
        }
    }

    private func mapCompanion(_ record: CompanionRecord) -> Companion {
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
