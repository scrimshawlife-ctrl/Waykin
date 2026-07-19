import UIKit
import XCTest
@testable import WaykinApp

@MainActor
final class AppearanceAndARSkinTests: XCTestCase {
    func testAppearancePreferenceMapsColorScheme() {
        XCTAssertNil(AppearancePreference.system.preferredColorScheme)
        XCTAssertEqual(AppearancePreference.day.preferredColorScheme, .light)
        XCTAssertEqual(AppearancePreference.night.preferredColorScheme, .dark)
    }

    func testFactoryAcceptsEachSkin() {
        for skin in LiraSkin.allCases {
            let entity = CompanionEntityFactory(skin: skin).makeLira()
            XCTAssertEqual(entity.name, CompanionEntityFactory.rootName)
            XCTAssertNotNil(entity.findEntity(named: "Body"))
            XCTAssertNotNil(entity.findEntity(named: "CoreGlow"))
            XCTAssertNotNil(entity.findEntity(named: "Filament"))
        }
    }

    func testStillCatalogCoversFullPoseSkinMatrix() {
        for skin in LiraSkin.allCases {
            for pose in LiraSessionPose.allCases {
                let name = LiraStillCatalog.imageName(pose: pose, skin: skin)
                XCTAssertNotNil(name, "Missing still name for \(pose)/\(skin)")
                XCTAssertTrue(name?.hasPrefix("Lira_Session_") == true)
                XCTAssertTrue(
                    LiraStillCatalog.hasStill(pose: pose, skin: skin),
                    "Still asset not loadable for \(pose)/\(skin) (\(name ?? "nil"))"
                )
            }
            let glyph = LiraStillCatalog.glyphName(for: skin)
            XCTAssertTrue(glyph.hasPrefix("Lira_Glyph_"))
            XCTAssertNotNil(UIImage(named: glyph), "Glyph asset not loadable: \(glyph)")
        }
        XCTAssertEqual(
            LiraStillCatalog.imageName(pose: .hunter, skin: .veil),
            "Lira_Session_Hunter_Veil"
        )
        XCTAssertEqual(
            LiraStillCatalog.imageName(pose: .bond, skin: .rupture),
            "Lira_Session_Bond_Rupture"
        )
        XCTAssertEqual(LiraStillCatalog.glyphName(for: .veil), "Lira_Glyph_Veil")
        // Full 7×3 matrix is installed (not Canvas-only fallback for any combo).
        XCTAssertEqual(LiraSessionPose.allCases.count * LiraSkin.allCases.count, 21)
    }

    func testEchoDayNightTokensAreNotSimpleInvert() {
        let day = WKTheme.resolve(.light)
        let night = WKTheme.resolve(.dark)
        XCTAssertFalse(day.isNight)
        XCTAssertTrue(night.isNight)
        // Night indigo-earth is not inverted day mist (hex contract).
        XCTAssertEqual(WKTokens.Hex.dayBackground, "E4E8EC")
        XCTAssertEqual(WKTokens.Hex.nightBackground, "12151C")
        XCTAssertNotEqual(WKTokens.Hex.dayBackground, WKTokens.Hex.nightBackground)
        XCTAssertNotEqual(WKTokens.Hex.dayTextPrimary, WKTokens.Hex.nightTextPrimary)
    }
}
