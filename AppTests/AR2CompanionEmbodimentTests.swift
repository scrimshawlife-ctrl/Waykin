import RealityKit
import XCTest
@testable import WaykinApp

@MainActor
final class AR2CompanionEmbodimentTests: XCTestCase {
    func testBehaviorMappingIsDeterministicAndUnknownFallsBackToIdle() {
        XCTAssertEqual(CompanionStateReducer.state(for: "follow"), .follow)
        XCTAssertEqual(CompanionStateReducer.state(for: "observe"), .investigate)
        XCTAssertEqual(CompanionStateReducer.state(for: "alert"), .alert)
        XCTAssertEqual(CompanionStateReducer.state(for: "bondMoment"), .celebrate)
        XCTAssertEqual(CompanionStateReducer.state(for: "unknown"), .idle)
    }

    func testCelebrateReturnsToIdleAfterBoundedDuration() {
        let current = CompanionPresentationTransition(state: .celebrate, elapsedInState: 1.2)
        let next = CompanionStateReducer.reduce(
            current: current,
            behavior: "celebrate",
            deltaTime: 0.3,
            celebrationDuration: 1.4
        )
        XCTAssertEqual(next.state, .idle)
    }

    func testProceduralLiraHasStableSemanticHierarchy() {
        let lira = CompanionEntityFactory.makeLira()
        XCTAssertEqual(lira.name, "LiraRoot")
        for name in ["Body", "Head", "LeftEar", "RightEar", "Tail", "CoreGlow", "GroundShadow", "StatusIndicator"] {
            XCTAssertNotNil(lira.findEntity(named: name), "Missing \(name)")
        }
    }

    func testVisualConfigurationClampsUnsafeValues() {
        let config = CompanionVisualConfiguration(
            companionHeightMeters: .infinity,
            groundOffsetMeters: -10,
            glowScale: 99
        ).normalized
        XCTAssertEqual(config.companionHeightMeters, 0.62)
        XCTAssertEqual(config.groundOffsetMeters, -0.05)
        XCTAssertEqual(config.glowScale, 2)
    }

    func testLocomotionPolicyHonorsDeadZoneAndMaximumSpeed() {
        let policy = CompanionTransformPolicy(followThreshold: 0.45, resetThreshold: 8, maximumSpeed: 1.5)
        XCTAssertEqual(
            policy.step(current: [0, 0, 0], target: [0.2, 0, 0], deltaTime: 1),
            [0, 0, 0]
        )
        let moved = policy.step(current: [0, 0, 0], target: [4, 0, 0], deltaTime: 0.5)
        XCTAssertEqual(moved.x, 0.75, accuracy: 0.001)
    }

    func testDiagnosticsProducePrivacyFilteredSummary() throws {
        let recorder = ARDiagnosticRecorder()
        recorder.record(.sessionStarted)
        recorder.record(.trackingChanged, detail: "normal")
        recorder.record(.entityCreated, detail: "companion")
        recorder.record(.companionStateChanged, detail: "alert")
        recorder.record(.sessionCleared)

        let receipt = recorder.receipt()
        XCTAssertTrue(receipt.sessionStarted)
        XCTAssertTrue(receipt.trackingNormalReached)
        XCTAssertTrue(receipt.companionPlaced)
        XCTAssertEqual(receipt.companionStateTransitions, ["alert"])
        XCTAssertTrue(receipt.cleanupSucceeded)

        let encoded = try JSONEncoder().encode(receipt)
        let text = String(decoding: encoded, as: UTF8.self)
        XCTAssertFalse(text.localizedCaseInsensitiveContains("latitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("longitude"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("cameraFrame"))
    }
}
