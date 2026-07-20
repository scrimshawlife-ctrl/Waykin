import SwiftUI

/// Shared status chip chrome for path / audio / GPS (#149).
struct SessionStatusChip: View {
    enum Tone: Equatable {
        case calm
        case caution
        case emphasis
    }

    let title: String
    var systemImage: String? = nil
    var wkIcon: WKIcon? = nil
    var tone: Tone = .calm
    var accessibilityLabelText: String
    var accessibilityValueText: String
    var accessibilityIdentifier: String

    @Environment(\.wkTheme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            if let wkIcon {
                WKIconView(icon: wkIcon, size: 16)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(background.opacity(0.92))
        .clipShape(Capsule(style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(accessibilityValueText)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var foreground: Color {
        switch tone {
        case .calm: theme.textSecondary
        case .caution: theme.caution
        case .emphasis: theme.hunter
        }
    }

    private var background: Color {
        theme.surface
    }
}
