import XCTest
@testable import WaykinCore
import SwiftData

/// WP-DB5: migration, reopen, isolation, reset, corruption / recovery.
final class PersistenceLifecycleTests: XCTestCase {

    // MARK: - Seeded “previous open path” → current factory

    func testLegacyPlainSchemaStoreReopensWithVersionedFactory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let storeURL = tempDir.appendingPathComponent("Waykin.store")

        // Seed without VersionedSchema / migration plan (simulates older open path).
        let legacySchema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let legacyConfig = ModelConfiguration(schema: legacySchema, url: storeURL)
        var legacyContainer: ModelContainer? = try ModelContainer(
            for: legacySchema,
            configurations: [legacyConfig]
        )
        let legacyStore = PersistenceStore(
            modelContainer: legacyContainer!,
            storeURL: storeURL,
            availability: .availableFileBacked
        )
        try legacyStore.saveCompanion(
            CanonicalCompanionIdentity.defaultCompanion(bondLevel: 19)
        )
        let sessionID = UUID()
        _ = try legacyStore.saveMemory(
            SessionMemory(sessionID: sessionID, text: "seeded legacy memory")
        )
        legacyContainer = nil

        // Reopen with current factory + migration plan.
        let opened = try WaykinPersistenceContainerFactory.makeFileBacked(url: storeURL)
        let store = PersistenceStore(
            modelContainer: opened.container,
            storeURL: opened.storeURL,
            availability: .availableFileBacked
        )
        let companion = try store.loadCompanion()
        XCTAssertEqual(companion?.id, CanonicalCompanionIdentity.liraID)
        XCTAssertEqual(companion?.bondLevel, 19)
        let memories = try store.loadMemories()
        XCTAssertEqual(memories.first?.sessionID, sessionID)
        XCTAssertEqual(memories.first?.text, "seeded legacy memory")
    }

    // MARK: - Reopen / relaunch

    func testCompletedSessionSurvivesContainerRelaunch() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let storeURL = tempDir.appendingPathComponent("Waykin.store")

        let sessionID = UUID()
        do {
            let opened = try WaykinPersistenceContainerFactory.makeFileBacked(url: storeURL)
            let gateway = WaykinPersistenceGateway(
                modelContainer: opened.container,
                storeURL: opened.storeURL,
                availability: .availableFileBacked
            )
            let started = Date(timeIntervalSince1970: 1_800_000_000)
            _ = try await gateway.saveCompletedSession(
                CompletedSession(
                    sessionID: sessionID,
                    walkMode: "trail",
                    activityType: "walk",
                    experienceID: "companion_walk",
                    startedAt: started,
                    completedAt: started.addingTimeInterval(300),
                    activeDurationSeconds: 280,
                    distanceMeters: 750,
                    completionReason: "completed",
                    bondBefore: 10,
                    bondAfter: 11,
                    memoryText: "relaunched",
                    pathRelation: "onPath"
                ),
                companion: CanonicalCompanionIdentity.defaultCompanion(bondLevel: 11)
            )
        }

        let reopened = try WaykinPersistenceContainerFactory.makeFileBacked(url: storeURL)
        let gateway2 = WaykinPersistenceGateway(
            modelContainer: reopened.container,
            storeURL: reopened.storeURL,
            availability: .availableFileBacked
        )
        let facts = try await gateway2.completedSession(for: sessionID)
        XCTAssertEqual(facts?.distanceMeters, 750)
        XCTAssertEqual(facts?.bondAfter, 11)
        let companion = try await gateway2.loadCanonicalCompanion()
        XCTAssertEqual(companion?.bondLevel, 11)
    }

    // MARK: - Interrupted / repeated completion

    func testInterruptedThenCompletedSessionIsSingleCanonicalRecord() async throws {
        let (gateway, _) = try WaykinPersistenceGateway.inMemory()
        let sessionID = UUID()
        // “Interrupted”: companion advanced without aggregate (crash between steps).
        var companion = CanonicalCompanionIdentity.defaultCompanion(bondLevel: 14)
        companion.lastSessionID = sessionID
        try await gateway.saveCompanion(companion)
        let beforeComplete = try await gateway.completedSession(for: sessionID)
        XCTAssertNil(beforeComplete)

        // Resume: complete atomically.
        _ = try await gateway.saveCompletedSession(
            CompletedSession(
                sessionID: sessionID,
                startedAt: Date(),
                completedAt: Date(),
                activeDurationSeconds: 40,
                distanceMeters: 200,
                completionReason: "userEnded",
                bondBefore: 13,
                bondAfter: 14,
                memoryText: "resumed completion"
            ),
            companion: companion
        )
        let facts = try await gateway.completedSession(for: sessionID)
        let countAfter = try await gateway.memoryCount()
        XCTAssertEqual(facts?.memoryText, "resumed completion")
        XCTAssertEqual(countAfter, 1)

        // Repeated completion is rejected; bond stays.
        do {
            _ = try await gateway.saveCompletedSession(
                CompletedSession(
                    sessionID: sessionID,
                    startedAt: Date(),
                    completedAt: Date(),
                    activeDurationSeconds: 1,
                    distanceMeters: 1,
                    completionReason: "userEnded",
                    bondBefore: 14,
                    bondAfter: 15,
                    memoryText: "dup"
                ),
                companion: CanonicalCompanionIdentity.defaultCompanion(bondLevel: 15)
            )
            XCTFail("expected duplicate")
        } catch let error as PersistenceError {
            XCTAssertEqual(error, .duplicateSessionMemory(sessionID))
        }
        let bond = try await gateway.loadCanonicalCompanion()?.bondLevel
        let count = try await gateway.memoryCount()
        XCTAssertEqual(bond, 14)
        XCTAssertEqual(count, 1)
    }

    // MARK: - Production / test isolation

    func testDistinctFileBackedStoresAreIsolated() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let prodURL = root.appendingPathComponent("prod").appendingPathComponent("Waykin.store")
        let testURL = root.appendingPathComponent("test").appendingPathComponent("Waykin.store")
        try FileManager.default.createDirectory(
            at: prodURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: testURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let prod = try WaykinPersistenceContainerFactory.makeFileBacked(url: prodURL)
        let test = try WaykinPersistenceContainerFactory.makeFileBacked(url: testURL)
        try PersistenceStore(
            modelContainer: prod.container,
            storeURL: prod.storeURL,
            availability: .availableFileBacked
        ).saveCompanion(CanonicalCompanionIdentity.defaultCompanion(bondLevel: 30))
        try PersistenceStore(
            modelContainer: test.container,
            storeURL: test.storeURL,
            availability: .availableFileBacked
        ).saveCompanion(CanonicalCompanionIdentity.defaultCompanion(bondLevel: 1))

        let prodReload = try PersistenceStore(
            modelContainer: try WaykinPersistenceContainerFactory.makeFileBacked(url: prodURL).container,
            storeURL: prodURL,
            availability: .availableFileBacked
        ).loadCompanion()
        let testReload = try PersistenceStore(
            modelContainer: try WaykinPersistenceContainerFactory.makeFileBacked(url: testURL).container,
            storeURL: testURL,
            availability: .availableFileBacked
        ).loadCompanion()
        XCTAssertEqual(prodReload?.bondLevel, 30)
        XCTAssertEqual(testReload?.bondLevel, 1)
    }

    func testInMemoryContainersDoNotShareState() throws {
        let a = try PersistenceStore.makeEphemeral()
        let b = try PersistenceStore.makeEphemeral()
        try a.saveCompanion(CanonicalCompanionIdentity.defaultCompanion(bondLevel: 7))
        XCTAssertNil(try b.loadCompanion())
        XCTAssertEqual(try a.loadCompanion()?.bondLevel, 7)
    }

    // MARK: - Explicit reset

    func testResetDemoDataClearsCompanionAndSessions() async throws {
        let (gateway, _) = try WaykinPersistenceGateway.inMemory()
        let sessionID = UUID()
        _ = try await gateway.saveCompletedSession(
            CompletedSession(
                sessionID: sessionID,
                startedAt: Date(),
                completedAt: Date(),
                activeDurationSeconds: 10,
                distanceMeters: 20,
                completionReason: "completed",
                bondBefore: 2,
                bondAfter: 3,
                memoryText: "clear me"
            ),
            companion: CanonicalCompanionIdentity.defaultCompanion(bondLevel: 3)
        )
        let before = try await gateway.memoryCount()
        XCTAssertEqual(before, 1)
        try await gateway.resetDemoData()
        let companion = try await gateway.loadCanonicalCompanion()
        let after = try await gateway.memoryCount()
        let session = try await gateway.completedSession(for: sessionID)
        XCTAssertNil(companion)
        XCTAssertEqual(after, 0)
        XCTAssertNil(session)
    }

    // MARK: - Corruption / migration failure

    func testCorruptStoreIsDiagnosedAndNotDeletedOnFailedOpen() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let storeURL = tempDir.appendingPathComponent("Waykin.store")
        try Data("not-a-valid-swiftdata-store".utf8).write(to: storeURL)

        XCTAssertEqual(PersistenceRecovery.diagnose(storeURL: storeURL), .presentUnopenable)
        XCTAssertThrowsError(try WaykinPersistenceContainerFactory.makeFileBacked(url: storeURL))
        // Original bytes remain for diagnosis.
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
        let raw = try Data(contentsOf: storeURL)
        XCTAssertEqual(String(data: raw, encoding: .utf8), "not-a-valid-swiftdata-store")
    }

    func testQuarantinePreservesBytesAndAllowsFreshOpen() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let storeURL = tempDir.appendingPathComponent("Waykin.store")
        let payload = Data("corrupt-payload-for-quarantine".utf8)
        try payload.write(to: storeURL)

        let quarantineURL = try PersistenceRecovery.quarantineStore(
            at: storeURL,
            now: Date(timeIntervalSince1970: 1_900_000_000)
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeURL.path))
        let quarantinedFile = quarantineURL.appendingPathComponent("Waykin.store")
        XCTAssertTrue(FileManager.default.fileExists(atPath: quarantinedFile.path))
        XCTAssertEqual(try Data(contentsOf: quarantinedFile), payload)

        // Fresh empty durable store can open at original path.
        let opened = try WaykinPersistenceContainerFactory.makeFileBacked(url: storeURL)
        let store = PersistenceStore(
            modelContainer: opened.container,
            storeURL: opened.storeURL,
            availability: .availableFileBacked
        )
        XCTAssertNil(try store.loadCompanion())
        XCTAssertEqual(PersistenceRecovery.diagnose(storeURL: storeURL), .presentReadable)
    }

    func testOpenFreshAfterQuarantineReturnsEmptyReadableStore() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let storeURL = tempDir.appendingPathComponent("Waykin.store")
        try Data("broken".utf8).write(to: storeURL)

        let result = try PersistenceRecovery.openFreshAfterQuarantine(
            storeURL: storeURL,
            now: Date(timeIntervalSince1970: 1_900_000_100)
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.quarantineURL.path))
        let store = PersistenceStore(
            modelContainer: result.container,
            storeURL: result.storeURL,
            availability: .availableFileBacked
        )
        try store.saveCompanion(CanonicalCompanionIdentity.defaultCompanion(bondLevel: 5))
        XCTAssertEqual(try store.loadCompanion()?.bondLevel, 5)
    }

    // MARK: - Receipt separation

    func testFieldTestReceiptPathIsSeparateFromSwiftDataStore() throws {
        let storeURL = try PersistenceConfiguration.persistentStoreURL()
        let receiptDir = FileFieldTestReceiptStore.applicationSupport().directoryURL
        XCTAssertNotEqual(storeURL.deletingLastPathComponent().path, receiptDir.path)
        XCTAssertTrue(storeURL.path.contains("Waykin.store") || storeURL.lastPathComponent == "Waykin.store")
        XCTAssertTrue(receiptDir.path.contains("FieldTestReceipts"))
        // Recovery must not target receipt directory.
        XCTAssertFalse(receiptDir.path.contains("Waykin.store"))
    }

    func testDiagnoseMissingStore() throws {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("Waykin.store")
        XCTAssertEqual(PersistenceRecovery.diagnose(storeURL: missing), .missing)
    }
}
