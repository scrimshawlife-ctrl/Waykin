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
            }
            let glyph = LiraStillCatalog.glyphName(for: skin)
            XCTAssertTrue(glyph.hasPrefix("Lira_Glyph_"))
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
    }
}
