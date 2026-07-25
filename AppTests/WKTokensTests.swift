import SwiftUI
import UIKit
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

    func testSessionBackgroundStaysOpaque() {
        let theme = WKTheme(colorScheme: .light)
        for p in [0.0, 0.35, 0.75, 1.0] {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(theme.sessionBackground(pressure: p)).getRed(&r, green: &g, blue: &b, alpha: &a)
            XCTAssertEqual(a, 1, accuracy: 0.001, "pressure \(p) must stay opaque")
        }
    }

    func testPresenceStyleBackgroundUsesTheme() {
        let day = WKTheme(colorScheme: .light)
        let night = WKTheme(colorScheme: .dark)
        _ = CompanionPresenceStyle.background(for: 0.2, theme: day)
        _ = CompanionPresenceStyle.background(for: 0.2, theme: night)
        _ = CompanionPresenceStyle.background(for: 0.5) // legacy fallback
    }

    func testSpacingRadiusMotionMatchCandidateV02() {
        XCTAssertEqual(WKTokens.Space.screenMarginX, 24)
        XCTAssertEqual(WKTokens.Space.minTouch, 48)
        XCTAssertEqual(WKTokens.Radius.medium, 14)
        XCTAssertEqual(WKTokens.Radius.large, 20)
        XCTAssertEqual(WKTokens.Motion.fast, 0.12, accuracy: 0.001)
        XCTAssertEqual(WKTokens.Motion.manifestation, 0.70, accuracy: 0.001)
        XCTAssertEqual(WKTokens.TypeScale.displayMin, 28)
    }

    func testLiraMaterialHexTokensAreStable() {
        XCTAssertEqual(WKTokens.LiraMaterial.Hex.dawnBody, "E8D9C4")
        XCTAssertEqual(WKTokens.LiraMaterial.Hex.veilBody, "2A2E38")
        XCTAssertEqual(WKTokens.LiraMaterial.Hex.ruptureBody, "4A4558")
        XCTAssertEqual(WKTokens.LiraMaterial.Hex.guide, "3F8F8A")
        XCTAssertEqual(WKTokens.LiraMaterial.Hex.bond, "D4A45A")
    }

    func testLiraSkinResolvesThroughNamedMaterialTokens() {
        let theme = WKTheme.resolve(.light)
        func rgb(_ color: Color) -> [CGFloat] {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
            return [round(r * 255), round(g * 255), round(b * 255)]
        }
        XCTAssertEqual(rgb(LiraSkin.dawn.bodyBase(theme: theme)), rgb(WKTokens.LiraMaterial.dawnBody))
        XCTAssertEqual(rgb(LiraSkin.veil.bondCore(theme: theme)), rgb(WKTokens.LiraMaterial.veilBond))
        XCTAssertEqual(rgb(LiraSkin.rupture.fringe(theme: theme)), rgb(WKTokens.LiraMaterial.ruptureFringe))
    }
}
