import XCTest
@testable import WaykinApp

final class WKIconsTests: XCTestCase {
    func testCoreIconInventoryIsPresent() {
        let required: Set<WKIcon> = [
            .home, .beginSession, .companion, .bond, .settings,
            .pause, .resume, .stop,
            .companionAhead, .companionBehind,
            .caution, .sanctuary, .trail, .audio
        ]
        XCTAssertEqual(Set(WKIcon.allCases), required)
    }

    func testAccessibilityLabelsAreHumanReadable() {
        for icon in WKIcon.allCases {
            XCTAssertFalse(icon.accessibilityLabel.isEmpty)
            XCTAssertFalse(icon.accessibilityLabel.contains("_"))
        }
    }

    func testBondFilamentMarkRendersWithoutCrash() {
        // Construction-only smoke: type is available for Home chrome.
        XCTAssertNotNil(WKBondFilamentMark(size: 44))
    }
}
