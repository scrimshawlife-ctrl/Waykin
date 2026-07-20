import XCTest
@testable import WaykinCore

final class CompletedSessionPersistenceTests: XCTestCase {

    func testAtomicSaveCompletedSessionWritesBondAndStructuredFacts() async throws {
        let (gateway, _) = try WaykinPersistenceGateway.inMemory()
        let sessionID = UUID()
        let started = Date(timeIntervalSince1970: 1_700_000_000)
        let completed = started.addingTimeInterval(600)
        let aggregate = CompletedSession(
            id: UUID(),
            sessionID: sessionID,
            scenarioID: "calmDayWalk",
            walkMode: "trail",
            activityType: "walk",
            experienceID: "companion_walk",
            startedAt: started,
            completedAt: completed,
            activeDurationSeconds: 480,
            distanceMeters: 1200,
            completionReason: "completed",
            bondBefore: 12,
            bondAfter: 13,
            memoryText: "Lira stayed close.",
            pathRelation: PathRelation.onPath.rawValue
        )
        var companion = CanonicalCompanionIdentity.defaultCompanion(bondLevel: 12)
        companion.lastSessionID = nil

        let receipt = try await gateway.saveCompletedSession(aggregate, companion: companion)
        XCTAssertEqual(receipt.recordID, aggregate.id)

        let loadedCompanion = try await gateway.loadCanonicalCompanion()
        XCTAssertEqual(loadedCompanion?.bondLevel, 13)
        XCTAssertEqual(loadedCompanion?.lastSessionID, sessionID)

        guard let loaded = try await gateway.completedSession(for: sessionID) else {
            return XCTFail("expected completed session")
        }
        XCTAssertEqual(loaded.distanceMeters, 1200, accuracy: 0.001)
        XCTAssertEqual(loaded.activeDurationSeconds, 480, accuracy: 0.001)
        XCTAssertEqual(loaded.bondBefore, 12)
        XCTAssertEqual(loaded.bondAfter, 13)
        XCTAssertEqual(loaded.completionReason, "completed")
        XCTAssertEqual(loaded.walkMode, "trail")
        XCTAssertEqual(loaded.pathRelation, PathRelation.onPath.rawValue)
        XCTAssertEqual(loaded.memoryText, "Lira stayed close.")

        let mem = try await gateway.memory(for: sessionID)
        XCTAssertEqual(mem?.text, "Lira stayed close.")
        let count = try await gateway.memoryCount()
        XCTAssertEqual(count, 1)
    }

    func testCompletedSessionIsIdempotentOnSessionID() async throws {
        let (gateway, _) = try WaykinPersistenceGateway.inMemory()
        let sessionID = UUID()
        let base = CompletedSession(
            sessionID: sessionID,
            startedAt: Date(),
            completedAt: Date(),
            activeDurationSeconds: 10,
            distanceMeters: 50,
            completionReason: "userEnded",
            bondBefore: 1,
            bondAfter: 2,
            memoryText: "once"
        )
        _ = try await gateway.saveCompletedSession(
            base,
            companion: CanonicalCompanionIdentity.defaultCompanion(bondLevel: 2)
        )
        do {
            _ = try await gateway.saveCompletedSession(
                CompletedSession(
                    sessionID: sessionID,
                    startedAt: Date(),
                    completedAt: Date(),
                    activeDurationSeconds: 1,
                    distanceMeters: 1,
                    completionReason: "userEnded",
                    bondBefore: 2,
                    bondAfter: 3,
                    memoryText: "twice"
                ),
                companion: CanonicalCompanionIdentity.defaultCompanion(bondLevel: 3)
            )
            XCTFail("expected duplicate")
        } catch let error as PersistenceError {
            XCTAssertEqual(error, .duplicateSessionMemory(sessionID))
        }
        let companion = try await gateway.loadCanonicalCompanion()
        XCTAssertEqual(companion?.bondLevel, 2, "failed second write must not change bond")
    }

    func testLegacyMemoryOnlyRowsDoNotFabricateCompletedSession() async throws {
        let (gateway, _) = try WaykinPersistenceGateway.inMemory()
        let sessionID = UUID()
        _ = try await gateway.saveMemory(SessionMemory(sessionID: sessionID, text: "legacy prose only"))
        let structured = try await gateway.completedSession(for: sessionID)
        XCTAssertNil(structured, "must not invent bond/duration from prose-only rows")
        let mem = try await gateway.memory(for: sessionID)
        XCTAssertEqual(mem?.text, "legacy prose only")
    }

    func testInMemoryAggregateDoesNotRequireParsingProse() async throws {
        let repo = InMemoryPersistenceRepository()
        let sessionID = UUID()
        _ = try await repo.saveCompletedSession(
            CompletedSession(
                sessionID: sessionID,
                walkMode: "hunt",
                startedAt: Date(timeIntervalSince1970: 10),
                completedAt: Date(timeIntervalSince1970: 100),
                activeDurationSeconds: 70,
                distanceMeters: 900,
                completionReason: "completed",
                bondBefore: 5,
                bondAfter: 6,
                memoryText: "poetic line that should not be required for facts"
            ),
            companion: CanonicalCompanionIdentity.defaultCompanion(bondLevel: 6)
        )
        guard let facts = try await repo.completedSession(for: sessionID) else {
            return XCTFail("expected facts")
        }
        XCTAssertEqual(facts.distanceMeters, 900)
        XCTAssertEqual(facts.bondDelta, 1)
        XCTAssertEqual(facts.walkMode, "hunt")
        XCTAssertFalse(facts.memoryText.contains("900"))
    }
}
