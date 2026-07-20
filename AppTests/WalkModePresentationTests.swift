import XCTest
@testable import WaykinApp

final class WalkModePresentationTests: XCTestCase {
    func testThreeModesWithIconsAndCopy() {
        XCTAssertEqual(WalkMode.allCases.map(\.rawValue), ["trail", "race", "hunt"])
        for mode in WalkMode.allCases {
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.emotionalLine.isEmpty)
            XCTAssertFalse(mode.prepHeadline.isEmpty)
            _ = mode.icon
        }
    }

    func testHuntHasProtectiveFootnoteOthersDoNot() {
        XCTAssertNotNil(WalkMode.hunt.protectiveFootnote)
        XCTAssertNil(WalkMode.trail.protectiveFootnote)
        XCTAssertNil(WalkMode.race.protectiveFootnote)
    }

    func testDemoScenarioRemainsCalmDayWalk() {
        for mode in WalkMode.allCases {
            XCTAssertEqual(mode.demoScenario, .calmDayWalk)
        }
    }
}
