import Foundation

// MARK: - Repository contracts (WP-DB3)
//
// Sendable async boundaries. SwiftData stays behind `WaykinPersistenceActor`.
// Gameplay engines must not import these for rules — only orchestration (app model)
// and tests call repositories.

/// Canonical Lira companion durable store.
public protocol CompanionRepository: Sendable {
    func loadCanonicalCompanion() async throws -> Companion?
    func saveCompanion(_ companion: Companion) async throws
}

/// Concise session memory durable store (idempotent on `sessionID`).
public protocol SessionMemoryRepository: Sendable {
    @discardableResult
    func saveMemory(_ memory: SessionMemory) async throws -> PersistenceWriteReceipt
    func memory(for sessionID: UUID) async throws -> SessionMemory?
    func recentMemories(limit: Int) async throws -> [SessionMemory]
    func memoryCount() async throws -> Int
}

/// Structured completed-session aggregate (WP-DB4). Idempotent on `sessionID`.
public protocol SessionCompletionRepository: Sendable {
    /// Atomically persists companion bond linkage + completed-session aggregate.
    @discardableResult
    func saveCompletedSession(
        _ session: CompletedSession,
        companion: Companion
    ) async throws -> PersistenceWriteReceipt
    func completedSession(for sessionID: UUID) async throws -> CompletedSession?
    func recentCompletedSessions(limit: Int) async throws -> [CompletedSession]
}

/// Explicit demo/UI-test reset (never silent).
public protocol PersistenceResetting: Sendable {
    func resetDemoData() async throws
}

/// Combined local-first persistence surface for app orchestration.
public protocol WaykinPersistenceServing: CompanionRepository, SessionMemoryRepository, SessionCompletionRepository, PersistenceResetting, Sendable {
    var availability: PersistenceAvailability { get async }
    var storeURL: URL? { get async }
}
