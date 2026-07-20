import UIKit
import XCTest
@testable import WaykinApp

final class WaykinTypographyTests: XCTestCase {
    func testBundledDisplayFontLoadsByPostScriptName() {
        XCTAssertTrue(
            WaykinTypography.ensureRegistered(),
            "WaykinDisplay-Regular.ttf must be in the app bundle and registerable."
        )
        XCTAssertNotNil(
            UIFont(name: WaykinTypography.displayPostScriptName, size: 32),
            "WaykinDisplay-Regular.ttf must resolve by PostScript name after registration."
        )
    }

    func testUIKitHelperReturnsUsableFont() {
        let font = WaykinTypography.uiDisplay(size: 30)
        XCTAssertGreaterThan(font.pointSize, 0)
        // Prefer custom face when packaging is correct.
        XCTAssertEqual(font.fontName, WaykinTypography.displayPostScriptName)
    }

    func testBundleContainsFontResource() {
        let url = Bundle.main.url(forResource: "WaykinDisplay-Regular", withExtension: "ttf")
        XCTAssertNotNil(url, "Font resource missing from host app bundle")
    }
}
