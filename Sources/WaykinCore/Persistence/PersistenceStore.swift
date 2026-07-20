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
    /// Open failed after recovery attempt; original store should be quarantined, not deleted.
    case recoveryRequired
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
    /// Durable completion idempotency key (WP-DB2 / WP-DB4).
    @Attribute(.unique)
    public var sessionID: UUID
    public var scenarioID: String?
    public var text: String
    public var createdAt: Date
    // WP-DB4 structured aggregate fields (optional for legacy rows).
    public var walkMode: String?
    public var activityType: String?
    public var experienceID: String?
    public var startedAt: Date?
    public var completedAt: Date?
    /// Optional so pre-WP-DB4 stores migrate without mandatory defaults.
    public var activeDurationSeconds: Double?
    public var distanceMeters: Double?
    public var completionReason: String?
    public var bondBefore: Int?
    public var bondAfter: Int?
    public var pathRelation: String?

    public init(
        id: UUID = UUID(),
        sessionID: UUID,
        scenarioID: String? = nil,
        text: String,
        createdAt: Date = Date(),
        walkMode: String? = nil,
        activityType: String? = nil,
        experienceID: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        activeDurationSeconds: Double = 0,
        distanceMeters: Double = 0,
        completionReason: String? = nil,
        bondBefore: Int? = nil,
        bondAfter: Int? = nil,
        pathRelation: String? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.scenarioID = scenarioID
        self.text = text
        self.createdAt = createdAt
        self.walkMode = walkMode
        self.activityType = activityType
        self.experienceID = experienceID
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.activeDurationSeconds = max(0, activeDurationSeconds.isFinite ? activeDurationSeconds : 0)
        self.distanceMeters = max(0, distanceMeters.isFinite ? distanceMeters : 0)
        self.completionReason = completionReason
        self.bondBefore = bondBefore.map { max(0, $0) }
        self.bondAfter = bondAfter.map { max(0, $0) }
        self.pathRelation = pathRelation
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
        try PersistenceContextOperations.saveCompanion(companion, context: ctx)
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
        return try PersistenceContextOperations.loadCompanion(context: ctx)
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
        return try PersistenceContextOperations.saveMemory(
            memory,
            context: ctx,
            storeURL: storeURL
        )
    }

    public func loadMemories() throws -> [SessionMemory] {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            return inMemoryMemories.sorted { $0.timestamp > $1.timestamp }
        }
        return try PersistenceContextOperations.loadMemories(context: ctx)
    }

    public func memoryCount() throws -> Int {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            return inMemoryMemories.count
        }
        return try PersistenceContextOperations.memoryCount(context: ctx)
    }

    public func resetDemoData() throws {
        guard let ctx = modelContext else {
            guard availability != .failed else { throw PersistenceError.unavailable }
            inMemoryCompanions.removeAll()
            inMemoryMemories.removeAll()
            return
        }
        try PersistenceContextOperations.resetDemoData(context: ctx)
    }

    /// Gateway sharing this store's container (production orchestration path).
    public func makeGateway() -> WaykinPersistenceGateway? {
        guard let container = modelContext?.container else { return nil }
        return WaykinPersistenceGateway(
            modelContainer: container,
            storeURL: storeURL,
            availability: availability
        )
    }
}
