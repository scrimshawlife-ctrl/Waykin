import WaykinCore
import XCTest
@testable import WaykinApp

final class WKSessionChromeTests: XCTestCase {
    func testChipLabelsAreShortAndUppercase() {
        for state in WKSessionChromeState.allCases {
            XCTAssertLessThanOrEqual(state.chipLabel.count, 12, state.rawValue)
            XCTAssertEqual(state.chipLabel, state.chipLabel.uppercased())
        }
    }

    func testPausedMapsToPauseChrome() {
        let state = WKSessionChromeState.resolve(
            behavior: .follow,
            pursuit: .inactive,
            isPaused: true,
            isOpening: false,
            pathRelation: .onPath,
            gpsProblem: false
        )
        XCTAssertEqual(state, .pause)
        XCTAssertEqual(state.icon, .pause)
    }

    func testGPSProblemMapsToTrackingLoss() {
        let state = WKSessionChromeState.resolve(
            behavior: .follow,
            pursuit: .inactive,
            isPaused: false,
            isOpening: false,
            pathRelation: .onPath,
            gpsProblem: true
        )
        XCTAssertEqual(state, .trackingLoss)
        XCTAssertEqual(state.icon, .trackingLoss)
    }

    func testClosePursuitMapsToHunter() {
        let state = WKSessionChromeState.resolve(
            behavior: .follow,
            pursuit: .close,
            isPaused: false,
            isOpening: false,
            pathRelation: .onPath,
            gpsProblem: false
        )
        XCTAssertEqual(state, .hunter)
    }

    func testTokenSpacingAndSafetyPausePresent() {
        XCTAssertEqual(WKTokens.Space.minTouch, 48)
        XCTAssertEqual(WKTokens.Radius.medium, 14)
        XCTAssertEqual(WKTokens.Motion.standard, 0.22, accuracy: 0.001)
        XCTAssertEqual(WKTokens.Hex.daySafetyPause, "5F7F72")
        let day = WKTheme.resolve(.light)
        let night = WKTheme.resolve(.dark)
        _ = day.safetyPause
        _ = night.safetyPause
        XCTAssertEqual(day.disabledOpacity, 0.35, accuracy: 0.001)
    }
}
