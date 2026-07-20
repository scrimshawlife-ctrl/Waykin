import SwiftData
import XCTest
import WaykinCore
@testable import WaykinApp

@MainActor
final class OperatorDebugInstrumentationTests: XCTestCase {

    func testIngestARPresentationMergesIntoSessionSummary() throws {
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
    }

    func testFinishReceiptIncludesARPresentationAndStillLabel() throws {
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

        let receipt = try XCTUnwrap(store.receipts.last)
        XCTAssertEqual(receipt.schemaVersion, 4)
        XCTAssertTrue(receipt.summary.arPresentation.arSessionOpened)
        XCTAssertEqual(receipt.summary.arPresentation.finalLODDescription, "artist_usdz:Lira_AR_Base")
        XCTAssertNotNil(receipt.summary.arPresentation.sessionStillDiagnosticLabel)
        XCTAssertTrue(
            receipt.summary.arPresentation.sessionStillDiagnosticLabel?.hasPrefix("still:") == true
        )
        XCTAssertNotNil(model.latestFieldTestReceiptURL)
        XCTAssertEqual(model.latestFieldTestReceipt?.receiptID, receipt.receiptID)
    }

    func testRefreshLatestReceiptFromStore() throws {
        let store = ReceiptMemoryStore()
        let model = try makeModel(receiptStore: store)
        model.startDemo(.calmDayWalk)
        model.endDemo()
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
            persistenceStore: PersistenceStore(modelContainer: container),
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
