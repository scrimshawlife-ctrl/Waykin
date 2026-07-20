import UIKit
import XCTest
@testable import WaykinApp

final class WaykinTypographyTests: XCTestCase {
    func testBundledDisplayFontLoadsByPostScriptName() {
        XCTAssertNotNil(
            UIFont(name: WaykinTypography.displayPostScriptName, size: 32),
            "WaykinDisplay-Regular.ttf must be copied into the app bundle and declared through UIAppFonts."
        )
    }

    func testUIKitHelperReturnsUsableFont() {
        XCTAssertGreaterThan(WaykinTypography.uiDisplay(size: 30).pointSize, 0)
    }
}
