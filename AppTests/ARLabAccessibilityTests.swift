import XCTest
@testable import WaykinApp

/// Follow-up to Issue #35: VoiceOver labels for the AR Lab state controls.
@MainActor
final class ARLabAccessibilityTests: XCTestCase {
    func testEveryStateHasAHumanControlLabel() {
        var seen: Set<String> = []
        for state in CompanionPresentationState.allCases {
            let label = state.labControlAccessibilityLabel
            XCTAssertEqual(label, "Set Lira to \(state.rawValue)")
            XCTAssertFalse(label.contains("_"))
            XCTAssertFalse(label.lowercased().contains("debug"))
            seen.insert(label)
        }
        XCTAssertEqual(seen.count, CompanionPresentationState.allCases.count,
                       "control labels must be distinct per state")
    }
}
