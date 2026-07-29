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
        let ok = UIFont(name: displayPostScriptName, size: 12) != nil
        if !ok {
            // D7: soft operator signal only — never crash or block launch.
            WaykinLog.ui.warning("display font not registered (\(displayPostScriptName, privacy: .public))")
        }
        return ok
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

    /// Display face for a specific string, falling back to the system face when the
    /// string contains characters the brand font cannot draw.
    ///
    /// `WaykinDisplay-Regular` is an uppercase-only subset — 42 glyphs covering `A–Z`,
    /// digits and a little punctuation, with **no lowercase**. Applied to sentence-case
    /// text, iOS draws the capital from the brand face and falls back to the system face
    /// for the rest, so "Choose a path" renders two typefaces mid-word.
    static func display(
        for text: String,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .title
    ) -> Font {
        // Fallback uses the semantic style rather than a fixed point size so it keeps
        // scaling with Dynamic Type at the largest accessibility sizes.
        canRender(text)
            ? display(size: size, relativeTo: textStyle)
            : .system(textStyle, design: .default, weight: .medium)
    }

    /// Whether every drawable character in `text` exists in the brand subset.
    /// Whitespace is ignored — it needs no glyph.
    static func canRender(_ text: String) -> Bool {
        text.unicodeScalars.allSatisfy { scalar in
            if CharacterSet.whitespacesAndNewlines.contains(scalar) { return true }
            return displayCoverage.contains(scalar)
        }
    }

    /// The subset actually present in the packaged font.
    private static let displayCoverage: CharacterSet = {
        var set = CharacterSet(charactersIn: "A"..."Z")
        set.insert(charactersIn: "0"..."9")
        set.insert(charactersIn: "&'-.:")
        return set
    }()

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
