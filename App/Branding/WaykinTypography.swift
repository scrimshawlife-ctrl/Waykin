import SwiftUI
import UIKit

enum WaykinTypography {
    static let displayPostScriptName = "WaykinDisplay-Regular"

    static func display(size: CGFloat, relativeTo textStyle: Font.TextStyle = .title) -> Font {
        .custom(displayPostScriptName, size: size, relativeTo: textStyle)
    }

    static func uiDisplay(size: CGFloat) -> UIFont {
        UIFont(name: displayPostScriptName, size: size)
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
