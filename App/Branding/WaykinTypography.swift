import CoreText
import SwiftUI
import UIKit

enum WaykinTypography {
    static let displayPostScriptName = "WaykinDisplay-Regular"
    static let resourceName = "WaykinDisplay-Regular"

    /// Registers the bundled TTF for this process if UIAppFonts has not already.
    @discardableResult
    static func ensureRegistered() -> Bool {
        _ = registrationToken
        return UIFont(name: displayPostScriptName, size: 12) != nil
    }

    private static let registrationToken: Bool = {
        if UIFont(name: displayPostScriptName, size: 12) != nil {
            return true
        }
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "ttf") else {
            return false
        }
        var error: Unmanaged<CFError>?
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        return ok && UIFont(name: displayPostScriptName, size: 12) != nil
    }()

    static func display(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title) -> Font {
        _ = ensureRegistered()
        return .custom(displayPostScriptName, size: size, relativeTo: textStyle)
    }

    static func uiDisplay(size: CGFloat) -> UIFont {
        _ = ensureRegistered()
        return UIFont(name: displayPostScriptName, size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }
}

extension View {
    func waykinDisplayTitle(size: CGFloat = 34, tracking: CGFloat = 5) -> some View {
        font(WaykinTypography.display(size: size))
            .tracking(tracking)
            .textCase(.uppercase)
    }
}
