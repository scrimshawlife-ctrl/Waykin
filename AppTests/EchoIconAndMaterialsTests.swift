import RealityKit
import UIKit
import XCTest
@testable import WaykinApp

/// Issue #55 (Phase 4 step 3): app icon wiring, Echo materials, and the
/// Living Familiar anchor structure on the procedural Lira placeholder.
@MainActor
final class EchoIconAndMaterialsTests: XCTestCase {

    func testAppIconIsWiredIntoTheAppBundle() throws {
        // GENERATE_INFOPLIST_FILE + ASSETCATALOG_COMPILER_APPICON_NAME wire
        // the compiled catalog icon into the Info.plist icon dictionary.
        let bundle = Bundle(for: WaykinAppModel.self)
        let icons = try XCTUnwrap(
            bundle.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            "app bundle must declare CFBundleIcons")
        let primary = try XCTUnwrap(icons["CFBundlePrimaryIcon"] as? [String: Any])
        let name = (primary["CFBundleIconName"] as? String)
            ?? ((primary["CFBundleIconFiles"] as? [String])?.first)
        XCTAssertEqual(name, "AppIcon")
    }

    func testLiraKeepsLegacyHierarchyAndGainsLivingFamiliarAnchors() {
        let lira = CompanionEntityFactory().makeLira()

        // Legacy contract (renderer + embodiment tests depend on these).
        for name in ["Body", "Head", "LeftEar", "RightEar", "Tail",
                     "CoreGlow", "GroundShadow", "StatusIndicator"] {
            XCTAssertNotNil(lira.findEntity(named: name), "missing legacy child \(name)")
        }
        // Living Familiar anchors (A1 head, A2 chest bond, A3 filament).
        XCTAssertNotNil(lira.findEntity(named: "A1_HeadAnchor"))
        XCTAssertNotNil(lira.findEntity(named: "Snout"), "A1 needs a readable facing")
        XCTAssertNotNil(lira.findEntity(named: "CoreGlow"), "A2 chest bond core")
        let filament = lira.findEntity(named: "A3_Filament")
        XCTAssertNotNil(filament)
        XCTAssertEqual(filament?.children.count, 3, "A3 is a three-bead arc")
        XCTAssertNotNil(lira.findEntity(named: "FilamentBead1"))
    }

    func testEchoPaletteMatchesLockedTokenHexes() {
        func hex(_ color: UIColor) -> String {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return String(format: "%02X%02X%02X",
                          Int(round(red * 255)), Int(round(green * 255)), Int(round(blue * 255)))
        }
        // AR palette mirrors WK_TOKENS_v0.2 day values (documented mirror —
        // the ARLab target cannot import the App theme file).
        XCTAssertEqual(hex(CompanionEntityFactory.EchoPalette.head), WKTokens.Hex.dayGuide)
        XCTAssertEqual(hex(CompanionEntityFactory.EchoPalette.bondCore), WKTokens.Hex.dayBond)
        XCTAssertEqual(hex(CompanionEntityFactory.EchoPalette.filament), "7B8C9E")
        XCTAssertEqual(hex(CompanionEntityFactory.EchoPalette.body), "4A535E")
    }

    func testRendererStateContractSurvivesFactoryRestructure() {
        // The renderer toggles CoreGlow/StatusIndicator by name; the Echo
        // restructure must not break per-state application.
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        let renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
        let anchor = Entity()
        let lira = CompanionEntityFactory().makeLira()
        anchor.addChild(lira)
        registry.register(anchor, for: ARWorldCommandRenderer.companionID)

        for state in CompanionPresentationState.allCases {
            XCTAssertEqual(renderer.setCompanionState(state),
                           .accepted("companion:\(state.rawValue)"))
        }
        XCTAssertNotNil(lira.findEntity(named: "StatusIndicator"))
        XCTAssertNotNil(lira.findEntity(named: "A3_Filament"),
                        "anchors survive state application")
    }
}
