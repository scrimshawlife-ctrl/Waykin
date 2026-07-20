import XCTest
@testable import WaykinApp

final class ARContinuityHintTests: XCTestCase {
    func testOkPresentIsSilent() {
        XCTAssertNil(ARContinuityHint.message(from: "ok_present"))
        XCTAssertNil(ARContinuityHint.message(from: "none"))
        XCTAssertNil(ARContinuityHint.message(from: "cleared"))
        XCTAssertNil(ARContinuityHint.message(from: "planted_ground:spawn+ground"))
    }

    func testReplantAndCameraHints() {
        XCTAssertEqual(
            ARContinuityHint.message(from: "planted_camera:replant_missing+camera_fallback"),
            "Holding Lira near you (no ground yet)"
        )
        XCTAssertEqual(
            ARContinuityHint.message(from: "planted_ground:replant_far_or_detached+ground"),
            "Lira was far — re-planting ahead"
        )
        XCTAssertEqual(
            ARContinuityHint.message(from: "planted_ground:replant_missing+ground"),
            "Looking for Lira again"
        )
        XCTAssertEqual(
            ARContinuityHint.message(from: "ground_raycast_failed:spawn"),
            "Looking for the ground"
        )
    }
}
