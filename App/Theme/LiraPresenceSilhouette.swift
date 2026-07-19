import SwiftUI

/// Session-mid LOD silhouette for Lira under Echo materials.
/// Procedural stand-in for production rig; encodes anchors A1 head, A2 chest, A3 filament.
struct LiraPresenceSilhouette: View {
    let presentation: CompanionPresencePresentation
    @Environment(\.wkTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var body: some View {
        ZStack {
            // Outer pressure / echo ring
            Circle()
                .stroke(
                    theme.hunterFilament.opacity(0.22 + presentation.pressureIntensity * 0.45),
                    lineWidth: presentation.pressureStrokeWidth
                )
                .frame(width: 176, height: 176)

            // Incomplete bond orbital
            Circle()
                .trim(from: 0.08, to: 0.82)
                .stroke(theme.guide.opacity(0.55), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-40))
                .frame(width: 126, height: 126)

            // Living Familiar construction
            Canvas { context, size in
                let s = min(size.width, size.height)
                let cx = size.width * 0.5
                let cy = size.height * 0.52
                let unit = s / 100

                // A3 filament plume (behind)
                var filament = Path()
                filament.move(to: CGPoint(x: cx - 8 * unit, y: cy + 6 * unit))
                filament.addCurve(
                    to: CGPoint(x: cx - 38 * unit, y: cy + 22 * unit),
                    control1: CGPoint(x: cx - 18 * unit, y: cy + 4 * unit),
                    control2: CGPoint(x: cx - 30 * unit, y: cy + 10 * unit)
                )
                context.stroke(
                    filament,
                    with: .color(filamentColor),
                    style: StrokeStyle(lineWidth: 5 * unit, lineCap: .round)
                )
                var filament2 = Path()
                filament2.move(to: CGPoint(x: cx - 6 * unit, y: cy + 10 * unit))
                filament2.addCurve(
                    to: CGPoint(x: cx - 32 * unit, y: cy + 30 * unit),
                    control1: CGPoint(x: cx - 16 * unit, y: cy + 14 * unit),
                    control2: CGPoint(x: cx - 24 * unit, y: cy + 20 * unit)
                )
                context.stroke(
                    filament2,
                    with: .color(filamentColor.opacity(0.55)),
                    style: StrokeStyle(lineWidth: 3 * unit, lineCap: .round)
                )

                // Delayed echo silhouette under pressure
                if presentation.pressureIntensity >= 0.45 {
                    let echoBody = Path(ellipseIn: CGRect(
                        x: cx - 10 * unit + 10,
                        y: cy - 8 * unit + 4,
                        width: 36 * unit,
                        height: 22 * unit
                    ))
                    context.stroke(
                        echoBody,
                        with: .color(theme.hunterFilament.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 2 * unit, lineCap: .round)
                    )
                }

                // Body
                let body = Path(ellipseIn: CGRect(
                    x: cx - 16 * unit,
                    y: cy - 10 * unit,
                    width: 36 * unit,
                    height: 24 * unit
                ))
                context.fill(body, with: .color(bodyColor))

                // A1 Head (tapered)
                let head = Path(ellipseIn: CGRect(
                    x: cx + 10 * unit,
                    y: cy - 22 * unit,
                    width: 18 * unit,
                    height: 15 * unit
                ))
                context.fill(head, with: .color(bodyColor.opacity(0.95)))

                // Soft ear pair
                let ear = Path(ellipseIn: CGRect(
                    x: cx + 14 * unit,
                    y: cy - 28 * unit,
                    width: 6 * unit,
                    height: 9 * unit
                ))
                context.fill(ear, with: .color(bodyColor.opacity(0.85)))

                // A2 Chest bond core
                let core = Path(ellipseIn: CGRect(
                    x: cx + 2 * unit,
                    y: cy - 4 * unit,
                    width: 9 * unit,
                    height: 9 * unit
                ))
                context.fill(core, with: .color(theme.bond))
                let coreInner = Path(ellipseIn: CGRect(
                    x: cx + 4.5 * unit,
                    y: cy - 1.5 * unit,
                    width: 4 * unit,
                    height: 4 * unit
                ))
                context.fill(coreInner, with: .color(Color.white.opacity(0.35)))
            }
            .frame(width: 120, height: 100)
            .scaleEffect(presentation.presenceScale * (expanded ? 1.035 : 1))
            .opacity(presentation.presenceOpacity)
            .offset(y: presentation.verticalOffset)
        }
        .frame(height: 190)
        .onAppear(perform: animatePresence)
        .onChange(of: presentation.animationKey) { _, _ in animatePresence() }
        .onChange(of: reduceMotion) { _, _ in animatePresence() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(presentation.companionName) presence")
        .accessibilitySortPriority(5)
        .accessibilityIdentifier("waykin.session.presence")
    }

    private var bodyColor: Color {
        if presentation.pressureIntensity >= 0.45 { return theme.hunter }
        switch presentation.behavior {
        case .drawNear, .celebrate: return theme.bond.opacity(0.85)
        case .rest: return theme.sanctuary
        default: return Color(red: 0.91, green: 0.85, blue: 0.77)
        }
    }

    private var filamentColor: Color {
        presentation.pressureIntensity >= 0.45 ? theme.hunterFilament : theme.guide
    }

    private func animatePresence() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { expanded = false }
        guard let duration = presentation.animationDuration(reduceMotion: reduceMotion) else { return }
        withAnimation(.easeInOut(duration: duration).repeatCount(2, autoreverses: true)) {
            expanded = true
        }
    }
}
