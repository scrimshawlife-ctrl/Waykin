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

    func testStillCatalogNamesForDawnMVP() {
        XCTAssertEqual(
            LiraStillCatalog.imageName(pose: .guide, skin: .dawn),
            "Lira_Session_Guide_Dawn"
        )
        XCTAssertEqual(
            LiraStillCatalog.imageName(pose: .hunter, skin: .dawn),
            "Lira_Session_Hunter_Dawn"
        )
        XCTAssertNil(LiraStillCatalog.imageName(pose: .bond, skin: .dawn))
    }
}
