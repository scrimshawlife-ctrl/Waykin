import Foundation

/// Deterministic in-memory repository for unit tests (WP-DB3).
/// No SwiftData — inject to exercise orchestration without a container.
public actor InMemoryPersistenceRepository: WaykinPersistenceServing {
    private var companion: Companion?
    private var memories: [SessionMemory] = []
    public let configuredAvailability: PersistenceAvailability

    public init(
        companion: Companion? = nil,
        memories: [SessionMemory] = [],
        availability: PersistenceAvailability = .availableInMemory
    ) {
        self.companion = companion
        self.memories = memories
        self.configuredAvailability = availability
    }

    public var availability: PersistenceAvailability {
        get async { configuredAvailability }
    }

    public var storeURL: URL? {
        get async { nil }
    }

    public func loadCanonicalCompanion() async throws -> Companion? {
        if let companion, companion.id == CanonicalCompanionIdentity.liraID {
            return companion
        }
        return companion
    }

    public func saveCompanion(_ companion: Companion) async throws {
        self.companion = companion
    }

    public func saveMemory(_ memory: SessionMemory) async throws -> PersistenceWriteReceipt {
        if memories.contains(where: { $0.sessionID == memory.sessionID }) {
            throw PersistenceError.duplicateSessionMemory(memory.sessionID)
        }
        memories.append(memory)
        return PersistenceWriteReceipt(
            recordID: memory.id,
            storeURL: URL(fileURLWithPath: "/in-memory"),
            savedAt: Date(),
            verificationFetchSucceeded: true
        )
    }

    public func memory(for sessionID: UUID) async throws -> SessionMemory? {
        memories.first { $0.sessionID == sessionID }
    }

    public func recentMemories(limit: Int) async throws -> [SessionMemory] {
        let sorted = memories.sorted { $0.timestamp > $1.timestamp }
        guard limit > 0 else { return [] }
        return Array(sorted.prefix(limit))
    }

    public func memoryCount() async throws -> Int {
        memories.count
    }

    public func resetDemoData() async throws {
        companion = nil
        memories.removeAll()
    }
}

/// Injectable failure double for latency / error tests (WP-DB3).
public actor FailingPersistenceRepository: WaykinPersistenceServing {
    public var error: PersistenceError
    public var delayNanoseconds: UInt64

    public init(error: PersistenceError = .unavailable, delayNanoseconds: UInt64 = 0) {
        self.error = error
        self.delayNanoseconds = delayNanoseconds
    }

    public var availability: PersistenceAvailability {
        get async { .failed }
    }

    public var storeURL: URL? {
        get async { nil }
    }

    public func loadCanonicalCompanion() async throws -> Companion? {
        try await fail()
    }

    public func saveCompanion(_ companion: Companion) async throws {
        try await fail()
    }

    public func saveMemory(_ memory: SessionMemory) async throws -> PersistenceWriteReceipt {
        try await fail()
    }

    public func memory(for sessionID: UUID) async throws -> SessionMemory? {
        try await fail()
    }

    public func recentMemories(limit: Int) async throws -> [SessionMemory] {
        try await fail()
    }

    public func memoryCount() async throws -> Int {
        try await fail()
    }

    public func resetDemoData() async throws {
        try await fail()
    }

    private func fail() async throws -> Never {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        throw error
    }
}
