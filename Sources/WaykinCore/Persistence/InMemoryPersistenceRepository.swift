import Foundation

/// Deterministic in-memory repository for unit tests (WP-DB3 / WP-DB4).
/// No SwiftData — inject to exercise orchestration without a container.
public actor InMemoryPersistenceRepository: WaykinPersistenceServing {
    private var companion: Companion?
    private var memories: [SessionMemory] = []
    private var completedSessions: [CompletedSession] = []
    public let configuredAvailability: PersistenceAvailability

    public init(
        companion: Companion? = nil,
        memories: [SessionMemory] = [],
        completedSessions: [CompletedSession] = [],
        availability: PersistenceAvailability = .availableInMemory
    ) {
        self.companion = companion
        self.memories = memories
        self.completedSessions = completedSessions
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
        if memories.contains(where: { $0.sessionID == memory.sessionID })
            || completedSessions.contains(where: { $0.sessionID == memory.sessionID }) {
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
        if let mem = memories.first(where: { $0.sessionID == sessionID }) {
            return mem
        }
        return completedSessions.first { $0.sessionID == sessionID }?.asSessionMemory
    }

    public func recentMemories(limit: Int) async throws -> [SessionMemory] {
        let fromAggregate = completedSessions.map(\.asSessionMemory)
        let sorted = (memories + fromAggregate).sorted { $0.timestamp > $1.timestamp }
        guard limit > 0 else { return [] }
        return Array(sorted.prefix(limit))
    }

    public func memoryCount() async throws -> Int {
        // Unique session IDs across memory-only + aggregate rows.
        let ids = Set(memories.map(\.sessionID)).union(completedSessions.map(\.sessionID))
        return ids.count
    }

    public func saveCompletedSession(
        _ session: CompletedSession,
        companion: Companion
    ) async throws -> PersistenceWriteReceipt {
        if completedSessions.contains(where: { $0.sessionID == session.sessionID })
            || memories.contains(where: { $0.sessionID == session.sessionID }) {
            throw PersistenceError.duplicateSessionMemory(session.sessionID)
        }
        var linked = companion
        linked.lastSessionID = session.sessionID
        linked.bondLevel = session.bondAfter
        self.companion = linked
        completedSessions.append(session)
        return PersistenceWriteReceipt(
            recordID: session.id,
            storeURL: URL(fileURLWithPath: "/in-memory"),
            savedAt: Date(),
            verificationFetchSucceeded: true
        )
    }

    public func completedSession(for sessionID: UUID) async throws -> CompletedSession? {
        completedSessions.first { $0.sessionID == sessionID }
    }

    public func recentCompletedSessions(limit: Int) async throws -> [CompletedSession] {
        let sorted = completedSessions.sorted { $0.completedAt > $1.completedAt }
        guard limit > 0 else { return [] }
        return Array(sorted.prefix(limit))
    }

    public func resetDemoData() async throws {
        companion = nil
        memories.removeAll()
        completedSessions.removeAll()
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

    public func saveCompletedSession(
        _ session: CompletedSession,
        companion: Companion
    ) async throws -> PersistenceWriteReceipt {
        try await fail()
    }

    public func completedSession(for sessionID: UUID) async throws -> CompletedSession? {
        try await fail()
    }

    public func recentCompletedSessions(limit: Int) async throws -> [CompletedSession] {
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
