import SwiftUI

/// Session-mid production puppet for Lira.
/// Structured multi-pose figure with anchors A1 head, A2 chest bond, A3 filament.
/// Dawn materials via Echo tokens. Not a final painted hero still.
struct LiraSessionFigure: View {
    let presentation: CompanionPresencePresentation
    /// When nil, uses environment `liraSkin` (default Dawn).
    var skinOverride: LiraSkin? = nil
    @Environment(\.wkTheme) private var theme
    @Environment(\.liraSkin) private var environmentSkin
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var pose: LiraSessionPose { LiraSessionPose.resolve(from: presentation) }
    private var skin: LiraSkin { skinOverride ?? environmentSkin }

    var body: some View {
        ZStack {
            pressureRing
            bondOrbit
            figure
        }
        .frame(height: 190)
        .scaleEffect(presentation.presenceScale * (pulse && !reduceMotion ? 1.03 : 1))
        .opacity(presentation.presenceOpacity)
        .offset(y: presentation.verticalOffset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(presentation.companionName) presence")
        .accessibilityValue(pose.accessibilityDescription)
        .accessibilitySortPriority(5)
        .accessibilityIdentifier("waykin.session.presence")
        .onAppear(perform: runPulse)
        .onChange(of: presentation.animationKey) { _, _ in runPulse() }
        .onChange(of: reduceMotion) { _, _ in runPulse() }
    }

    private var pressureRing: some View {
        Circle()
            .stroke(
                theme.hunterFilament.opacity(0.20 + presentation.pressureIntensity * 0.5),
                lineWidth: presentation.pressureStrokeWidth
            )
            .frame(width: 176, height: 176)
    }

    private var bondOrbit: some View {
        Circle()
            .trim(from: pose == .bond ? 0.02 : 0.08, to: pose == .bond ? 0.92 : 0.82)
            .stroke(
                (pose == .bond ? theme.bond : theme.guide).opacity(0.55),
                style: StrokeStyle(lineWidth: pose == .bond ? 6 : 5, lineCap: .round)
            )
            .rotationEffect(.degrees(pose == .bond ? -10 : -40))
            .frame(width: 126, height: 126)
    }

    private var figure: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let unit = s / 100
            let crouch = pose.crouch
            let cx = size.width * 0.52
            let cy = size.height * 0.50 + crouch * 8 * unit
            let bodyColor = skin.bodyFill(pose: pose, theme: theme)
            let filamentColor = skin.filamentFill(pose: pose, theme: theme)
            let filLen = pose.filamentLength

            // A3 filament (behind body)
            drawFilament(
                context: context,
                cx: cx, cy: cy, unit: unit,
                length: filLen,
                color: filamentColor,
                manifesting: pose == .manifesting
            )

            // Hunter delayed echo (must: geometry, not color alone)
            if pose.showsEchoSilhouette {
                let echo = Path(ellipseIn: CGRect(
                    x: cx - 12 * unit + 12,
                    y: cy - 6 * unit + 6,
                    width: 34 * unit,
                    height: 20 * unit
                ))
                context.stroke(
                    echo,
                    with: .color(theme.hunterFilament.opacity(0.4)),
                    style: StrokeStyle(lineWidth: 2.2 * unit, lineCap: .round, dash: [4 * unit, 3 * unit])
                )
            }

            // Hind / haunch
            let haunch = Path(ellipseIn: CGRect(
                x: cx - 18 * unit,
                y: cy - 2 * unit,
                width: 20 * unit,
                height: 16 * unit
            ))
            context.fill(haunch, with: .color(bodyColor.opacity(0.92)))

            // Body (Living Familiar torso)
            let bodyW: CGFloat = pose == .rival ? 38 : 36
            let bodyH: CGFloat = pose == .dormant ? 18 : 22
            let body = Path(ellipseIn: CGRect(
                x: cx - 14 * unit,
                y: cy - 10 * unit,
                width: bodyW * unit,
                height: bodyH * unit
            ))
            context.fill(body, with: .color(bodyColor))

            // Legs suggestion (guide open vs hunter low)
            let legY = cy + (pose == .hunter ? 8 : 10) * unit
            var legs = Path()
            legs.move(to: CGPoint(x: cx - 6 * unit, y: cy + 4 * unit))
            legs.addLine(to: CGPoint(x: cx - 8 * unit, y: legY + 8 * unit))
            legs.move(to: CGPoint(x: cx + 4 * unit, y: cy + 4 * unit))
            legs.addLine(to: CGPoint(x: cx + 10 * unit, y: legY + (pose == .guide ? 6 : 4) * unit))
            context.stroke(
                legs,
                with: .color(bodyColor.opacity(0.85)),
                style: StrokeStyle(lineWidth: 2.5 * unit, lineCap: .round)
            )

            // A1 Head — tapered; guide looks ahead (right), hunter slightly back
            let headBias: CGFloat = pose == .hunter ? -2 : (pose == .guide ? 4 : 2)
            let headY = cy - (pose == .dormant ? 14 : 20) * unit
            let head = Path(ellipseIn: CGRect(
                x: cx + (8 + headBias) * unit,
                y: headY,
                width: 17 * unit,
                height: 14 * unit
            ))
            context.fill(head, with: .color(bodyColor.opacity(0.97)))

            // Soft offset ear pair (non-canid)
            let ear = Path(ellipseIn: CGRect(
                x: cx + (12 + headBias) * unit,
                y: headY - 6 * unit,
                width: 5.5 * unit,
                height: 9 * unit
            ))
            context.fill(ear, with: .color(bodyColor.opacity(0.88)))
            if pose != .dormant {
                let ear2 = Path(ellipseIn: CGRect(
                    x: cx + (16 + headBias) * unit,
                    y: headY - 4 * unit,
                    width: 4 * unit,
                    height: 7 * unit
                ))
                context.fill(ear2, with: .color(bodyColor.opacity(0.75)))
            }

            // A2 Chest bond core
            let coreSize: CGFloat = pose == .bond ? 11 : 8.5
            let core = Path(ellipseIn: CGRect(
                x: cx + 2 * unit,
                y: cy - 3 * unit,
                width: coreSize * unit,
                height: coreSize * unit
            ))
            context.fill(core, with: .color(skin.bondCore(theme: theme)))
            let coreInner = Path(ellipseIn: CGRect(
                x: cx + 4 * unit,
                y: cy - 1 * unit,
                width: 4 * unit,
                height: 4 * unit
            ))
            context.fill(coreInner, with: .color(Color.white.opacity(pose == .bond ? 0.45 : 0.3)))

            // Manifesting particle ticks
            if pose == .manifesting {
                for i in 0..<5 {
                    let a = CGFloat(i) * .pi / 2.5
                    let px = cx + cos(a) * 28 * unit
                    let py = cy + sin(a) * 18 * unit
                    let speck = Path(ellipseIn: CGRect(x: px, y: py, width: 2.5 * unit, height: 2.5 * unit))
                    context.fill(speck, with: .color(theme.guide.opacity(0.55)))
                }
            }
        }
        .frame(width: 130, height: 110)
    }

    private func drawFilament(
        context: GraphicsContext,
        cx: CGFloat, cy: CGFloat, unit: CGFloat,
        length: CGFloat,
        color: Color,
        manifesting: Bool
    ) {
        let reach = 36 * length
        var f1 = Path()
        f1.move(to: CGPoint(x: cx - 8 * unit, y: cy + 6 * unit))
        f1.addCurve(
            to: CGPoint(x: cx - reach * unit, y: cy + 20 * unit * length),
            control1: CGPoint(x: cx - 18 * unit, y: cy + 2 * unit),
            control2: CGPoint(x: cx - 28 * unit, y: cy + 12 * unit)
        )
        context.stroke(
            f1,
            with: .color(color),
            style: StrokeStyle(
                lineWidth: (manifesting ? 3.5 : 5) * unit,
                lineCap: .round,
                dash: manifesting ? [3 * unit, 4 * unit] : []
            )
        )
        var f2 = Path()
        f2.move(to: CGPoint(x: cx - 6 * unit, y: cy + 10 * unit))
        f2.addCurve(
            to: CGPoint(x: cx - (reach - 6) * unit, y: cy + 28 * unit * length),
            control1: CGPoint(x: cx - 16 * unit, y: cy + 14 * unit),
            control2: CGPoint(x: cx - 24 * unit, y: cy + 18 * unit)
        )
        context.stroke(
            f2,
            with: .color(color.opacity(0.55)),
            style: StrokeStyle(lineWidth: 3 * unit, lineCap: .round)
        )
    }

    private func runPulse() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { pulse = false }
        guard let duration = presentation.animationDuration(reduceMotion: reduceMotion) else { return }
        withAnimation(.easeInOut(duration: duration).repeatCount(2, autoreverses: true)) {
            pulse = true
        }
    }

}

// Back-compat alias used by presence view
typealias LiraPresenceSilhouette = LiraSessionFigure
