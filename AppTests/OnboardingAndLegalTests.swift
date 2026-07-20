import SwiftData
import WaykinCore
import XCTest
@testable import WaykinApp

@MainActor
final class OnboardingAndLegalTests: XCTestCase {
    func testOnboardingCompletesAndPersistsFlag() throws {
        let model = try makeModel()
        model.resetOnboardingForTesting()
        XCTAssertFalse(model.hasCompletedOnboarding)
        model.completeOnboarding()
        XCTAssertTrue(model.hasCompletedOnboarding)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: WaykinAppModel.onboardingStorageKey))
    }

    func testLegalDocumentsHaveTitlesAndBodies() {
        for doc in LegalDocument.allCases {
            XCTAssertFalse(doc.title.isEmpty)
            XCTAssertFalse(doc.bodyText.isEmpty)
            XCTAssertTrue(doc.bodyText.count > 40, doc.rawValue)
        }
        XCTAssertEqual(LegalDocument.allCases.count, 4)
        XCTAssertFalse(LegalContent.safetyBullets.isEmpty)
    }

    func testSafetyBulletsMentionStopAnytime() {
        let joined = LegalContent.safetyBullets.joined(separator: " ").lowercased()
        XCTAssertTrue(
            joined.contains("pause") || joined.contains("end") || joined.contains("stop")
        )
    }

    private func makeModel() throws -> WaykinAppModel {
        let schema = Schema([CompanionRecord.self, SessionMemoryRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return WaykinAppModel(
            persistenceStore: PersistenceStore(modelContainer: container),
            fieldTestReceiptStore: nil
        )
    }
}
