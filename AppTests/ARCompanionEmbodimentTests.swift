import RealityKit
import XCTest
@testable import WaykinApp

@MainActor
final class ARCompanionEmbodimentTests: XCTestCase {
    func testStateReducerMapsCanonicalAndFallbackBehaviors() {
        XCTAssertEqual(CompanionStateReducer.state(for: "follow"), .follow)
        XCTAssertEqual(CompanionStateReducer.state(for: "observes"), .investigate)
        XCTAssertEqual(CompanionStateReducer.state(for: "warning"), .alert)
        XCTAssertEqual(CompanionStateReducer.state(for: "bondMoment"), .celebrate)
        XCTAssertEqual(CompanionStateReducer.state(for: "unknown"), .idle)
    }

    func testCelebrationReturnsToIdleAfterBoundedDuration() {
        XCTAssertEqual(
            CompanionStateReducer.resolvedState(current: .celebrate, requested: .celebrate, elapsedSeconds: 1.0),
            .celebrate
        )
        XCTAssertEqual(
            CompanionStateReducer.resolvedState(current: .celebrate, requested: .celebrate, elapsedSeconds: 1.4),
            .idle
        )
    }

    func testLiraFactoryBuildsStableSemanticHierarchy() {
        let lira = CompanionEntityFactory().makeLira()

        XCTAssertEqual(lira.name, CompanionEntityFactory.rootName)
        for name in CompanionEntityFactory.requiredChildNames {
            XCTAssertNotNil(lira.findEntity(named: name), "Missing procedural Lira child: \(name)")
        }
    }

    func testLiraFactoryProducesIndependentEntities() throws {
        let factory = CompanionEntityFactory()
        let first = factory.makeLira()
        let second = factory.makeLira()
        let firstBody = try XCTUnwrap(first.findEntity(named: "Body"))
        let secondBody = try XCTUnwrap(second.findEntity(named: "Body"))

        XCTAssertFalse(first === second)
        XCTAssertFalse(firstBody === secondBody)
    }

    func testVisualConfigurationClampsUnsafeValues() {
        let configuration = CompanionVisualConfiguration(
            companionHeightMeters: .infinity,
            groundOffsetMeters: -10
        )

        XCTAssertEqual(configuration.companionHeightMeters, 0.62)
        XCTAssertEqual(configuration.groundOffsetMeters, 0)
    }

    func testDiagnosticsProducePrivacyBoundedReceipt() throws {
        let recorder = ARDiagnosticRecorder()
        recorder.record(.sessionStarted)
        recorder.record(.placementSucceeded, detail: "companion")
        recorder.record(.entityReplaced, detail: "companion")
        recorder.record(.stateChanged, detail: "alert")
        recorder.record(.sessionCleared)

        let receipt = recorder.receipt(registryCount: 0)
        XCTAssertEqual(receipt.placementSuccessCount, 1)
        XCTAssertEqual(receipt.replacementCount, 1)
        XCTAssertEqual(receipt.stateTransitions, ["alert"])
        XCTAssertTrue(receipt.cleanupSucceeded)

        let encoded = try JSONEncoder().encode(receipt)
        let text = String(decoding: encoded, as: UTF8.self)
        XCTAssertFalse(text.localizedCaseInsensitiveContains("latitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("longitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("cameraFrame"))
    }
}
