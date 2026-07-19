import SwiftUI

/// Core Echo icon set for App presentation (Phase 4 step 2 / Issue #52).
/// Template-style shapes: tint with `.foregroundStyle` / theme colors.
/// Source language: Waykin-Design 07_Icons v0.2 (24×24, stroke 1.75, round caps).
enum WKIcon: String, CaseIterable, Identifiable {
    case home
    case beginSession
    case companion
    case bond
    case settings
    case pause
    case resume
    case stop
    case companionAhead
    case companionBehind
    case caution
    case sanctuary
    case trail
    case audio

    var id: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .home: "Home"
        case .beginSession: "Begin session"
        case .companion: "Companion"
        case .bond: "Bond"
        case .settings: "Settings"
        case .pause: "Pause"
        case .resume: "Resume"
        case .stop: "End"
        case .companionAhead: "Companion ahead"
        case .companionBehind: "Companion behind"
        case .caution: "Caution"
        case .sanctuary: "Sanctuary"
        case .trail: "Trail"
        case .audio: "Audio"
        }
    }
}

struct WKIconView: View {
    let icon: WKIcon
    var size: CGFloat = 22
    var weight: Font.Weight = .regular

    var body: some View {
        icon.shape
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Shapes (24pt grid language)

private extension WKIcon {
    @ViewBuilder
    var shape: some View {
        switch self {
        case .home:
            WKIconCanvas { path in
                path.move(to: CGPoint(x: 4, y: 10.5))
                path.addLine(to: CGPoint(x: 12, y: 4))
                path.addLine(to: CGPoint(x: 20, y: 10.5))
                path.addLine(to: CGPoint(x: 20, y: 20))
                path.addLine(to: CGPoint(x: 14, y: 20))
                path.addLine(to: CGPoint(x: 14, y: 14))
                path.addLine(to: CGPoint(x: 10, y: 14))
                path.addLine(to: CGPoint(x: 10, y: 20))
                path.addLine(to: CGPoint(x: 4, y: 20))
                path.closeSubpath()
            }
        case .beginSession:
            ZStack {
                Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.75))
                WKIconCanvas(filled: true) { path in
                    path.move(to: CGPoint(x: 10, y: 9))
                    path.addLine(to: CGPoint(x: 16, y: 12))
                    path.addLine(to: CGPoint(x: 10, y: 15))
                    path.closeSubpath()
                }
                .scaleEffect(0.92)
            }
        case .companion:
            WKIconCanvas { path in
                path.addEllipse(in: CGRect(x: 8.8, y: 5.8, width: 6.4, height: 6.4))
                path.move(to: CGPoint(x: 7, y: 19))
                path.addCurve(to: CGPoint(x: 17, y: 19), control1: CGPoint(x: 7, y: 15.5), control2: CGPoint(x: 17, y: 15.5))
                path.move(to: CGPoint(x: 15, y: 10))
                path.addCurve(to: CGPoint(x: 19, y: 12), control1: CGPoint(x: 17, y: 9), control2: CGPoint(x: 18.5, y: 10))
            }
        case .bond:
            WKIconCanvas { path in
                // Incomplete orbital ring
                path.addArc(center: CGPoint(x: 12, y: 12), radius: 7, startAngle: .degrees(-40), endAngle: .degrees(220), clockwise: false)
                path.addEllipse(in: CGRect(x: 7.8, y: 10.8, width: 4.4, height: 4.4))
                path.addEllipse(in: CGRect(x: 12.5, y: 8.5, width: 4, height: 4))
            }
        case .settings:
            WKIconCanvas { path in
                path.addEllipse(in: CGRect(x: 9.5, y: 9.5, width: 5, height: 5))
                for angle in stride(from: 0.0, to: 360.0, by: 45.0) {
                    let rad = angle * .pi / 180
                    let inner = CGPoint(x: 12 + cos(rad) * 5.2, y: 12 + sin(rad) * 5.2)
                    let outer = CGPoint(x: 12 + cos(rad) * 8.2, y: 12 + sin(rad) * 8.2)
                    path.move(to: inner)
                    path.addLine(to: outer)
                }
            }
        case .pause:
            WKIconCanvas { path in
                path.move(to: CGPoint(x: 9, y: 7))
                path.addLine(to: CGPoint(x: 9, y: 17))
                path.move(to: CGPoint(x: 15, y: 7))
                path.addLine(to: CGPoint(x: 15, y: 17))
            }
        case .resume:
            WKIconCanvas(filled: true) { path in
                path.move(to: CGPoint(x: 9, y: 7))
                path.addLine(to: CGPoint(x: 17, y: 12))
                path.addLine(to: CGPoint(x: 9, y: 17))
                path.closeSubpath()
            }
        case .stop:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))
                .padding(6)
        case .companionAhead:
            WKIconCanvas { path in
                path.addEllipse(in: CGRect(x: 9.5, y: 4.5, width: 5, height: 5))
                path.move(to: CGPoint(x: 8, y: 14))
                path.addCurve(to: CGPoint(x: 16, y: 14), control1: CGPoint(x: 8, y: 11.5), control2: CGPoint(x: 16, y: 11.5))
                path.move(to: CGPoint(x: 12, y: 16))
                path.addLine(to: CGPoint(x: 12, y: 20))
                path.move(to: CGPoint(x: 9.5, y: 18))
                path.addLine(to: CGPoint(x: 12, y: 16))
                path.addLine(to: CGPoint(x: 14.5, y: 18))
            }
        case .companionBehind:
            WKIconCanvas { path in
                path.addEllipse(in: CGRect(x: 9.5, y: 13.5, width: 5, height: 5))
                path.move(to: CGPoint(x: 8, y: 10))
                path.addCurve(to: CGPoint(x: 16, y: 10), control1: CGPoint(x: 8, y: 12.5), control2: CGPoint(x: 16, y: 12.5))
                path.move(to: CGPoint(x: 12, y: 8))
                path.addLine(to: CGPoint(x: 12, y: 4))
                path.move(to: CGPoint(x: 9.5, y: 6))
                path.addLine(to: CGPoint(x: 12, y: 8))
                path.addLine(to: CGPoint(x: 14.5, y: 6))
                // echo tick
                path.move(to: CGPoint(x: 6, y: 14))
                path.addCurve(to: CGPoint(x: 6.5, y: 10), control1: CGPoint(x: 5, y: 13), control2: CGPoint(x: 5, y: 11))
            }
        case .caution:
            WKIconCanvas { path in
                path.move(to: CGPoint(x: 12, y: 4))
                path.addLine(to: CGPoint(x: 20, y: 18))
                path.addLine(to: CGPoint(x: 4, y: 18))
                path.closeSubpath()
                path.move(to: CGPoint(x: 12, y: 9))
                path.addLine(to: CGPoint(x: 12, y: 13))
                path.addEllipse(in: CGRect(x: 11.4, y: 14.9, width: 1.2, height: 1.2))
            }
        case .sanctuary:
            WKIconCanvas { path in
                path.move(to: CGPoint(x: 12, y: 4))
                path.addLine(to: CGPoint(x: 19, y: 9))
                path.addLine(to: CGPoint(x: 19, y: 14))
                path.addCurve(to: CGPoint(x: 12, y: 20.5), control1: CGPoint(x: 19, y: 17), control2: CGPoint(x: 16, y: 19.5))
                path.addCurve(to: CGPoint(x: 5, y: 14), control1: CGPoint(x: 8, y: 19.5), control2: CGPoint(x: 5, y: 17))
                path.addLine(to: CGPoint(x: 5, y: 9))
                path.closeSubpath()
                path.move(to: CGPoint(x: 9, y: 13))
                path.addLine(to: CGPoint(x: 11, y: 15))
                path.addLine(to: CGPoint(x: 15, y: 11))
            }
        case .trail:
            WKIconCanvas { path in
                path.move(to: CGPoint(x: 5, y: 17))
                path.addCurve(to: CGPoint(x: 19, y: 17), control1: CGPoint(x: 9, y: 14), control2: CGPoint(x: 15, y: 14))
                path.move(to: CGPoint(x: 12, y: 14))
                path.addLine(to: CGPoint(x: 12, y: 7))
                path.move(to: CGPoint(x: 10, y: 9))
                path.addLine(to: CGPoint(x: 12, y: 7))
                path.addLine(to: CGPoint(x: 14, y: 9))
            }
        case .audio:
            WKIconCanvas { path in
                path.move(to: CGPoint(x: 5, y: 10))
                path.addLine(to: CGPoint(x: 8, y: 10))
                path.addLine(to: CGPoint(x: 12, y: 7))
                path.addLine(to: CGPoint(x: 12, y: 17))
                path.addLine(to: CGPoint(x: 8, y: 14))
                path.addLine(to: CGPoint(x: 5, y: 14))
                path.closeSubpath()
                path.move(to: CGPoint(x: 15, y: 9))
                path.addCurve(to: CGPoint(x: 15, y: 15), control1: CGPoint(x: 16.5, y: 10), control2: CGPoint(x: 16.5, y: 14))
                path.move(to: CGPoint(x: 17, y: 7))
                path.addCurve(to: CGPoint(x: 17, y: 17), control1: CGPoint(x: 19.5, y: 9), control2: CGPoint(x: 19.5, y: 15))
            }
        }
    }
}

/// 24×24 canvas for stroke icons.
private struct WKIconCanvas: View {
    var filled: Bool = false
    var builder: (inout Path) -> Void

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 24
            var path = Path()
            builder(&path)
            let transformed = path.applying(CGAffineTransform(scaleX: scale, y: scale))
            if filled {
                context.fill(transformed, with: .foreground)
            } else {
                context.stroke(
                    transformed,
                    with: .foreground,
                    style: StrokeStyle(lineWidth: 1.75 * scale, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Bond Filament brand mark

/// Construction mark matching design Bond Filament (Echo B).
struct WKBondFilamentMark: View {
    var size: CGFloat = 44
    @Environment(\.wkTheme) private var theme

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height) / 120
            func t(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * s, y: p.y * s) }

            var ring = Path()
            ring.addArc(
                center: t(CGPoint(x: 60, y: 62)),
                radius: 40 * s,
                startAngle: .degrees(-50),
                endAngle: .degrees(200),
                clockwise: false
            )
            context.stroke(
                ring,
                with: .color(theme.textPrimary),
                style: StrokeStyle(lineWidth: 4 * s, lineCap: .round)
            )

            let left = Path(ellipseIn: CGRect(
                x: 34 * s, y: 49 * s, width: 24 * s, height: 30 * s
            ))
            context.fill(left, with: .color(theme.textPrimary))

            let right = Path(ellipseIn: CGRect(
                x: 61 * s, y: 40 * s, width: 22 * s, height: 28 * s
            ))
            context.fill(right, with: .color(theme.guide))

            var filament = Path()
            filament.move(to: t(CGPoint(x: 54, y: 58)))
            filament.addCurve(
                to: t(CGPoint(x: 69, y: 51)),
                control1: t(CGPoint(x: 61, y: 51)),
                control2: t(CGPoint(x: 64, y: 55))
            )
            context.stroke(
                filament,
                with: .color(theme.bond),
                style: StrokeStyle(lineWidth: 2.5 * s, lineCap: .round)
            )

            let core = Path(ellipseIn: CGRect(
                x: 68.5 * s, y: 50.5 * s, width: 7 * s, height: 7 * s
            ))
            context.fill(core, with: .color(theme.bond))

            var echo = Path()
            echo.move(to: t(CGPoint(x: 86, y: 72)))
            echo.addCurve(
                to: t(CGPoint(x: 92, y: 86)),
                control1: t(CGPoint(x: 90, y: 76)),
                control2: t(CGPoint(x: 92, y: 80))
            )
            context.stroke(
                echo,
                with: .color(theme.hunterFilament.opacity(0.9)),
                style: StrokeStyle(lineWidth: 2.25 * s, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Waykin mark")
    }
}

// MARK: - Label helpers

struct WKIconLabel: View {
    let title: String
    let icon: WKIcon
    var iconSize: CGFloat = 18

    var body: some View {
        Label {
            Text(title)
        } icon: {
            WKIconView(icon: icon, size: iconSize)
        }
    }
}
