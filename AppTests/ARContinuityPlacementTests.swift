import XCTest
@testable import WaykinApp

@MainActor
final class ARContinuityPlacementTests: XCTestCase {
    func testReplantDistanceGate() {
        XCTAssertFalse(ARPlacementResolver.shouldReplant(distanceMeters: 0))
        XCTAssertFalse(ARPlacementResolver.shouldReplant(distanceMeters: 5.9))
        XCTAssertTrue(ARPlacementResolver.shouldReplant(distanceMeters: 6.01))
        XCTAssertTrue(ARPlacementResolver.shouldReplant(distanceMeters: 15))
        XCTAssertTrue(ARPlacementResolver.shouldReplant(distanceMeters: .infinity))
        XCTAssertTrue(ARPlacementResolver.shouldReplant(distanceMeters: .nan))
        XCTAssertEqual(ARPlacementResolver.companionReplantDistanceMeters, 6.0, accuracy: 0.001)
    }

    func testCameraOffsetIsAheadOfCamera() {
        // Negative Z is ahead in camera space for AnchorEntity(.camera).
        XCTAssertLessThan(ARPlacementResolver.companionCameraOffset.z, 0)
        XCTAssertEqual(ARPlacementResolver.companionCameraOffset.y, -0.15, accuracy: 0.001)
    }

    func testContinuityDiagnosticKindExists() {
        XCTAssertEqual(ARDiagnosticKind.continuityReplant.rawValue, "continuityReplant")
    }

    func testRendererExposesContinuityNoteProperty() {
        let registry = AREntityRegistry()
        let renderer = ARWorldCommandRenderer(
            registry: registry,
            diagnostics: ARDiagnosticRecorder()
        )
        XCTAssertEqual(renderer.companionContinuityNote, "none")
    }

    func testDiagnosticRecorderTracksContinuityReplant() {
        let diagnostics = ARDiagnosticRecorder()
        diagnostics.record(.continuityReplant, detail: "planted_camera:replant_missing+camera_fallback")
        XCTAssertEqual(diagnostics.events.last?.kind, .continuityReplant)
        XCTAssertTrue(diagnostics.events.last?.detail.contains("replant") == true)
        XCTAssertEqual(diagnostics.summary.replacementCount, 0)
        // entityReplaced still drives replacementCount when recorded alongside.
        diagnostics.record(.entityReplaced, detail: "planted_camera:replant_missing+camera_fallback")
        XCTAssertEqual(diagnostics.summary.replacementCount, 1)
    }
}
