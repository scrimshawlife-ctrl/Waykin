import XCTest
@testable import WaykinApp

final class WKIconsTests: XCTestCase {
    func testCoreIconInventoryMatchesCandidateManifestNames() {
        // Critical set from WK_ICON_MANIFEST_v0.2 (unique names).
        let required: Set<WKIcon> = [
            .home, .beginSession, .companion, .bond, .history, .settings,
            .pause, .resume, .stop,
            .companionAhead, .companionBehind,
            .caution, .sanctuary, .audio, .haptics, .safetyPause, .trackingLoss, .routeCertainty,
            .trail, .race, .hunt,
            .guide, .rival, .hunter, .dormant, .recovering, .bonded,
            .location, .battery, .motion, .permissionRequired
        ]
        XCTAssertEqual(Set(WKIcon.allCases), required)
        XCTAssertEqual(WKIcon.allCases.count, 31)
    }

    func testAccessibilityLabelsAreHumanReadable() {
        for icon in WKIcon.allCases {
            XCTAssertFalse(icon.accessibilityLabel.isEmpty)
            XCTAssertFalse(icon.accessibilityLabel.contains("_"))
        }
    }

    func testBondFilamentMarkRendersWithoutCrash() {
        XCTAssertNotNil(WKBondFilamentMark(size: 44))
        XCTAssertNotNil(WKBondOrbitalRing(bondLevel: 3, size: 56))
    }
}
