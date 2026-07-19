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

    func testStillCatalogCoversAllDawnPoses() {
        for pose in LiraSessionPose.allCases {
            let name = LiraStillCatalog.imageName(pose: pose, skin: .dawn)
            XCTAssertNotNil(name, "Missing Dawn still for \(pose)")
            XCTAssertTrue(name?.contains("Dawn") == true)
        }
        XCTAssertEqual(LiraStillCatalog.imageName(pose: .guide, skin: .veil), "Lira_Session_Guide_Veil")
        XCTAssertEqual(LiraStillCatalog.glyphDawn, "Lira_Glyph_Dawn")
    }
}
