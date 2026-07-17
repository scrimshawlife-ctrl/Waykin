import RealityKit
import XCTest
@testable import WaykinApp

@MainActor
final class ARCompanionEmbodimentTests: XCTestCase {
    func testProceduralLiraContainsStableSemanticChildren() {
        let lira = CompanionEntityFactory.makeLira()

        XCTAssertEqual(lira.name, CompanionEntityFactory.rootName)
        for name in CompanionEntityFactory.requiredChildNames {
            XCTAssertNotNil(lira.findEntity(named: name), "Missing semantic child \(name)")
        }
    }

    func testVisualConfigurationClampsInvalidValues() {
        let config = CompanionVisualConfiguration(heightMeters: .infinity, scale: -4).normalized
        XCTAssertEqual(config.heightMeters, 0.62)
        XCTAssertEqual(config.scale, 0.5)
    }

    func testBehaviorMappingIsDeterministic() {
        XCTAssertEqual(CompanionStateReducer.state(for: "follow"), .follow)
        XCTAssertEqual(CompanionStateReducer.state(for: "observe"), .investigate)
        XCTAssertEqual(CompanionStateReducer.state(for: "warn"), .alert)
        XCTAssertEqual(CompanionStateReducer.state(for: "bond"), .celebrate)
        XCTAssertEqual(CompanionStateReducer.state(for: "unknown"), .idle)
    }

    func testCelebrateReturnsToIdleAfterBoundedDuration() {
        XCTAssertEqual(
            CompanionStateReducer.resolvedState(current: .idle, requested: .celebrate, elapsedSeconds: 0.8),
            .celebrate
        )
        XCTAssertEqual(
            CompanionStateReducer.resolvedState(current: .celebrate, requested: .celebrate, elapsedSeconds: 1.6),
            .idle
        )
    }

    func testDiagnosticsProducePrivacyBoundedSummary() throws {
        let recorder = ARDiagnosticRecorder()
        recorder.record(.sessionStarted)
        recorder.record(.placementSucceeded, detail: "companion")
        recorder.record(.stateChanged, detail: "idle")
        recorder.record(.sessionCleared)

        let receipt = recorder.makeReceipt()
        XCTAssertTrue(receipt.sessionStarted)
        XCTAssertEqual(receipt.placementSuccessCount, 1)
        XCTAssertEqual(receipt.companionStateTransitions, ["idle"])
        XCTAssertTrue(receipt.cleanupSucceeded)

        let json = String(data: try JSONEncoder().encode(receipt), encoding: .utf8) ?? ""
        XCTAssertFalse(json.localizedCaseInsensitiveContains("latitude"))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("longitude"))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("cameraFrame"))
    }
}
