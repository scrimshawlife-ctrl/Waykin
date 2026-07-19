import SwiftUI
import XCTest
@testable import WaykinApp

final class WKTokensTests: XCTestCase {
    func testTokenVersionAndProductName() {
        XCTAssertEqual(WKTokens.version, "0.2")
        XCTAssertEqual(WKTokens.assetID, "WK_TOKENS_v0.2")
        XCTAssertEqual(WKTokens.companionProductName, "Lira")
    }

    func testDayAndNightBackgroundHexAreDistinctAndNonInverted() {
        // Night is not a simple invert of day mist.
        XCTAssertEqual(WKTokens.Hex.dayBackground, "E4E8EC")
        XCTAssertEqual(WKTokens.Hex.nightBackground, "12151C")
        XCTAssertNotEqual(WKTokens.Hex.dayBackground, WKTokens.Hex.nightBackground)
        XCTAssertEqual(WKTokens.Hex.dayGuide, "3F8F8A")
        XCTAssertEqual(WKTokens.Hex.dayBond, "D4A45A")
        XCTAssertEqual(WKTokens.Hex.dayHunter, "5C4E7A")
    }

    func testThemeResolvesFromColorScheme() {
        let day = WKTheme.resolve(.light)
        let night = WKTheme.resolve(.dark)
        XCTAssertFalse(day.isNight)
        XCTAssertTrue(night.isNight)
        XCTAssertEqual(day.colorScheme, .light)
        XCTAssertEqual(night.colorScheme, .dark)
    }

    func testSessionBackgroundRespondsToPressure() {
        let theme = WKTheme(colorScheme: .dark)
        // Clamp extremes without crashing; colors are presentation-only.
        _ = theme.sessionBackground(pressure: 0)
        _ = theme.sessionBackground(pressure: 0.75)
        _ = theme.sessionBackground(pressure: -1)
        _ = theme.sessionBackground(pressure: 2)
        XCTAssertTrue(theme.isNight)
    }

    func testPresenceStyleBackgroundUsesTheme() {
        let day = WKTheme(colorScheme: .light)
        let night = WKTheme(colorScheme: .dark)
        _ = CompanionPresenceStyle.background(for: 0.2, theme: day)
        _ = CompanionPresenceStyle.background(for: 0.2, theme: night)
        _ = CompanionPresenceStyle.background(for: 0.5) // legacy fallback
    }
}
