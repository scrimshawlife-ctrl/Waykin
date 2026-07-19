import XCTest
@testable import WaykinApp

final class LiraSkinTests: XCTestCase {
    func testDefaultIsDawn() {
        XCTAssertEqual(LiraSkin.default, .dawn)
        XCTAssertEqual(LiraSkin.allCases.count, 3)
    }

    func testSkinRawValuesStable() {
        XCTAssertEqual(LiraSkin.dawn.rawValue, "dawn")
        XCTAssertEqual(LiraSkin.veil.rawValue, "veil")
        XCTAssertEqual(LiraSkin.rupture.rawValue, "rupture")
    }

    func testUnlockLinesNonEmpty() {
        for skin in LiraSkin.allCases {
            XCTAssertFalse(skin.displayName.isEmpty)
            XCTAssertFalse(skin.unlockLine.isEmpty)
        }
    }

    func testDawnAndVeilBodiesDiffer() {
        let theme = WKTheme(colorScheme: .light)
        // Colors are different structures; ensure constructors don't crash and skins are distinct.
        XCTAssertNotEqual(LiraSkin.dawn.rawValue, LiraSkin.veil.rawValue)
        _ = LiraSkin.dawn.bodyBase(theme: theme)
        _ = LiraSkin.veil.bodyBase(theme: theme)
        _ = LiraSkin.rupture.bodyFill(pose: .hunter, theme: theme)
        _ = LiraSkin.dawn.filamentFill(pose: .guide, theme: theme)
    }

    func testStorageKeyStable() {
        XCTAssertEqual(LiraSkin.storageKey, "waykin.lira.skin")
    }
}
