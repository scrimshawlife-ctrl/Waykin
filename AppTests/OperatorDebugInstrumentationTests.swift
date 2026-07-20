import SwiftData
import XCTest
import WaykinCore
@testable import WaykinApp

@MainActor
final class OperatorDebugInstrumentationTests: XCTestCase {

    func testIngestARPresentationMergesIntoSessionSummary() async throws {
        let model = try makeModel(receiptStore: ReceiptMemoryStore())
        model.startDemo(.calmDayWalk)
        XCTAssertFalse(model.sessionARPresentationSummary.arSessionOpened)

        model.ingestARPresentationDiagnostics(
            FieldTestARPresentationSummary(
                arSessionOpened: true,
                finalLODDescription: "procedural_living_familiar_mid",
                meshEvidenceClass: "ARTIST_BLEND_HERO_DCC_MID_LOD",
                finalContinuityNote: "ok_present",
                finalCapabilityState: "tracking",
                placementDeferredCount: 1,
                continuityReplantCount: 2,
                companionPlaced: true
            )
        )
        XCTAssertTrue(model.sessionARPresentationSummary.arSessionOpened)
        XCTAssertEqual(model.sessionARPresentationSummary.continuityReplantCount, 2)

        model.ingestARPresentationDiagnostics(
            FieldTestARPresentationSummary(
                arSessionOpened: true,
                finalLODDescription: "artist_usdz:Lira_AR_Base",
                finalContinuityNote: "planted_camera:replant_missing",
                continuityReplantCount: 4
            )
        )
        XCTAssertEqual(model.sessionARPresentationSummary.finalLODDescription, "artist_usdz:Lira_AR_Base")
        XCTAssertEqual(model.sessionARPresentationSummary.continuityReplantCount, 4)
        model.endDemo()
        await model.waitForPendingPersistence()
    }

    func testFinishReceiptIncludesARPresentationAndStillLabel() async throws {
        let store = ReceiptMemoryStore()
        let model = try makeModel(receiptStore: store)
        model.startDemo(.calmDayWalk)
        model.advanceDemo()
        model.ingestARPresentationDiagnostics(
            FieldTestARPresentationSummary(
                arSessionOpened: true,
                finalLODDescription: "artist_usdz:Lira_AR_Base",
                meshEvidenceClass: "ARTIST_BLEND_HERO_DCC_MID_LOD",
                finalContinuityNote: "ok_present",
                companionPlaced: true
            )
        )
        model.endDemo()
        await model.waitForPendingPersistence()

        let receipt = try XCTUnwrap(store.receipts.last)
        XCTAssertEqual(receipt.schemaVersion, 5)
        XCTAssertTrue(receipt.summary.arPresentation.arSessionOpened)
        XCTAssertEqual(receipt.summary.arPresentation.finalLODDescription, "artist_usdz:Lira_AR_Base")
        XCTAssertNotNil(receipt.summary.arPresentation.sessionStillDiagnosticLabel)
        XCTAssertTrue(
            receipt.summary.arPresentation.sessionStillDiagnosticLabel?.hasPrefix("still:") == true
        )
        XCTAssertEqual(receipt.summary.persistenceOperator.availability, "availableInMemory")
        XCTAssertEqual(receipt.summary.persistenceOperator.recoveryAction, "none")
        XCTAssertNotNil(model.latestFieldTestReceiptURL)
        XCTAssertEqual(model.latestFieldTestReceipt?.receiptID, receipt.receiptID)
    }

    func testFinishReceiptCapturesMapPresentationBeforeClear() async throws {
        let store = ReceiptMemoryStore()
        let model = try makeModel(receiptStore: store)
        model.startDemo(.calmDayWalk)
        // Synthetic spaced points so WalkPathTrace keeps more than one sample.
        model.appendWalkPathTraceForTesting(latitude: 37.0, longitude: -122.0)
        model.appendWalkPathTraceForTesting(latitude: 37.001, longitude: -122.0)
        model.appendWalkPathTraceForTesting(latitude: 37.002, longitude: -122.0)
        XCTAssertGreaterThan(model.walkPathTrace.count, 0)
        model.endDemo()
        await model.waitForPendingPersistence()

        let receipt = try XCTUnwrap(store.receipts.last)
        XCTAssertEqual(receipt.schemaVersion, 5)
        XCTAssertGreaterThan(receipt.summary.mapPresentation.tracePointCount, 0)
        XCTAssertEqual(receipt.summary.mapPresentation.plannedRouteStatus, "none")
        // Cleared after snapshot — live trace empty, receipt still has counts.
        XCTAssertEqual(model.walkPathTrace.count, 0)
        let data = try JSONEncoder().encode(receipt)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8)).lowercased()
        XCTAssertTrue(json.contains("mappresentation"))
        XCTAssertFalse(json.contains("latitude"))
        XCTAssertFalse(json.contains("longitude"))
    }

    func testPersistenceRecoveryActionSurfacesOnReceipt() async throws {
        let store = ReceiptMemoryStore()
        let model = try makeModel(receiptStore: store)
        model.notePersistenceRecoveryAction("degraded_fallback")
        model.startDemo(.calmDayWalk)
        model.endDemo()
        await model.waitForPendingPersistence()
        let receipt = try XCTUnwrap(store.receipts.last)
        XCTAssertEqual(receipt.summary.persistenceOperator.recoveryAction, "degraded_fallback")
        XCTAssertEqual(model.persistenceRecoveryAction, "degraded_fallback")
    }

    func testRefreshLatestReceiptFromStore() async throws {
        let store = ReceiptMemoryStore()
        let model = try makeModel(receiptStore: store)
        model.startDemo(.calmDayWalk)
        model.endDemo()
        await model.waitForPendingPersistence()
        XCTAssertNotNil(model.latestFieldTestReceipt)
        model.refreshLatestFieldTestReceiptFromStore()
        XCTAssertNotNil(model.latestFieldTestReceipt)
        XCTAssertEqual(model.latestFieldTestReceipt?.mode, .demo)
    }

    func testOperatorDebugFeatureFlagAPI() {
        // Compile-time DEBUG is true in test host; process arg path exists for Release.
        XCTAssertFalse(OperatorDebugFeature.processArgument.isEmpty)
        _ = OperatorDebugFeature.isEnabled
    }

    private func makeModel(receiptStore: ReceiptMemoryStore) throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(
                modelContainer: container,
                storeURL: nil,
                availability: .availableInMemory
            ),
            healthMetricsProvider: NullHealthMetricsProvider(),
            fieldTestReceiptStore: receiptStore
        )
    }
}

private final class ReceiptMemoryStore: FieldTestReceiptStoring {
    private(set) var receipts: [FieldTestReceipt] = []
    private(set) var urls: [URL] = []

    func save(_ receipt: FieldTestReceipt) throws -> URL {
        receipts.append(receipt)
        let url = URL(fileURLWithPath: "/tmp/waykin-test-\(receipt.receiptID.uuidString).json")
        urls.append(url)
        return url
    }

    func loadLatest() throws -> FieldTestReceipt? { receipts.last }

    func loadLatestStored() throws -> (url: URL, receipt: FieldTestReceipt)? {
        guard let receipt = receipts.last, let url = urls.last else { return nil }
        return (url, receipt)
    }
}
