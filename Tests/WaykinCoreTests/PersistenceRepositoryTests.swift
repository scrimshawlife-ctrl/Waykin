import XCTest
@testable import WaykinCore
import SwiftData

final class PersistenceRepositoryTests: XCTestCase {

    func testGatewayRoundTripCompanionAndMemory() async throws {
        let (gateway, _) = try WaykinPersistenceGateway.inMemory()
        let availability = await gateway.availability
        XCTAssertEqual(availability, .availableInMemory)

        let companion = CanonicalCompanionIdentity.defaultCompanion(bondLevel: 15)
        try await gateway.saveCompanion(companion)
        let loaded = try await gateway.loadCanonicalCompanion()
        XCTAssertEqual(loaded?.id, CanonicalCompanionIdentity.liraID)
        XCTAssertEqual(loaded?.bondLevel, 15)

        let sessionID = UUID()
        let mem = SessionMemory(sessionID: sessionID, text: "Actor path")
        let receipt = try await gateway.saveMemory(mem)
        XCTAssertEqual(receipt.recordID, mem.id)
        let count = try await gateway.memoryCount()
        XCTAssertEqual(count, 1)
        let bySession = try await gateway.memory(for: sessionID)
        XCTAssertEqual(bySession?.text, "Actor path")
        let recent = try await gateway.recentMemories(limit: 5)
        XCTAssertEqual(recent.count, 1)

        do {
            _ = try await gateway.saveMemory(SessionMemory(sessionID: sessionID, text: "dup"))
            XCTFail("expected duplicate error")
        } catch let error as PersistenceError {
            XCTAssertEqual(error, .duplicateSessionMemory(sessionID))
        }
    }

    func testInMemoryRepositoryIsInjectibleWithoutSwiftData() async throws {
        let repo = InMemoryPersistenceRepository()
        try await repo.saveCompanion(CanonicalCompanionIdentity.defaultCompanion(bondLevel: 9))
        let loaded = try await repo.loadCanonicalCompanion()
        XCTAssertEqual(loaded?.bondLevel, 9)

        let sessionID = UUID()
        _ = try await repo.saveMemory(SessionMemory(sessionID: sessionID, text: "m"))
        let count1 = try await repo.memoryCount()
        XCTAssertEqual(count1, 1)
        try await repo.resetDemoData()
        let count0 = try await repo.memoryCount()
        XCTAssertEqual(count0, 0)
        let after = try await repo.loadCanonicalCompanion()
        XCTAssertNil(after)
    }

    func testFailingRepositorySurfacesTypedError() async throws {
        let repo = FailingPersistenceRepository(error: .unavailable)
        do {
            _ = try await repo.saveMemory(SessionMemory(sessionID: UUID(), text: "x"))
            XCTFail("expected throw")
        } catch let error as PersistenceError {
            XCTAssertEqual(error, .unavailable)
        }
        let availability = await repo.availability
        XCTAssertEqual(availability, .failed)
    }

    func testFileBackedGatewaySharesStoreAcrossActors() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let url = tempDir.appendingPathComponent("Waykin.store")
        let opened = try WaykinPersistenceContainerFactory.makeFileBacked(url: url)
        let gateway = WaykinPersistenceGateway(
            modelContainer: opened.container,
            storeURL: opened.storeURL,
            availability: .availableFileBacked
        )
        try await gateway.saveCompanion(CanonicalCompanionIdentity.defaultCompanion(bondLevel: 4))
        let reopened = try WaykinPersistenceContainerFactory.makeFileBacked(url: url)
        let gateway2 = WaykinPersistenceGateway(
            modelContainer: reopened.container,
            storeURL: reopened.storeURL,
            availability: .availableFileBacked
        )
        let reloaded = try await gateway2.loadCanonicalCompanion()
        XCTAssertEqual(reloaded?.bondLevel, 4)
    }
}
