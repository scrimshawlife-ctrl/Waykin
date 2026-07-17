import MapKit
import SwiftUI
import WaykinCore

struct CompanionPresencePresentation {
    let companionName: String
    let bondLevel: Int
    let behavior: CompanionBehaviorState
    let pursuitState: PursuitState
    let eventKind: WorldEventKind?
    let audioCueKind: AudioCueKind?
    let elapsedSeconds: TimeInterval
    let distanceMeters: Double
    let isPaused: Bool
    let isOpening: Bool
    let latitude: Double?
    let longitude: Double?

    var phrase: String {
        if isOpening { return "\(companionName) is listening." }

        switch eventKind {
        case .companionDrawsNear: return "\(companionName) draws near."
        case .companionMovesAhead: return "\(companionName) has moved ahead."
        case .companionObserves: return "\(companionName) is watching the path."
        case .distantPresence: return "Something is keeping pace."
        case .pursuitBegins: return "The path has changed."
        case .pursuitIntensifies: return "The pressure is close."
        case .pursuitFades: return "The pressure is fading."
        case .familiarPlaceStirs: return "The path feels familiar."
        case .quietInterval: return "The path has gone quiet."
        case .bondMoment: return "\(companionName) shares the moment."
        case nil: break
        }

        switch pursuitState {
        case .noticed: return "The path has changed."
        case .approaching: return "Something is keeping pace."
        case .close: return "The pressure is close."
        case .fading: return "The pressure is fading."
        case .inactive: break
        }

        switch behavior {
        case .idle, .follow: return "\(companionName) stays close."
        case .lead: return "\(companionName) has moved ahead."
        case .celebrate: return "\(companionName) shares the moment."
        case .observe: return "\(companionName) is watching the path."
        case .drawNear: return "\(companionName) draws near."
        case .rest: return "\(companionName) rests beside you."
        }
    }

    var closingPhrase: String {
        switch pursuitState {
        case .fading: return "The presence faded."
        case .noticed, .approaching, .close: return "\(companionName) stayed with you."
        case .inactive: return eventKind == nil ? "\(companionName) stayed with you." : "The path remembers."
        }
    }

    var pressureIntensity: Double {
        switch pursuitState {
        case .inactive: 0
        case .noticed: 0.2
        case .approaching: 0.45
        case .close: 0.75
        case .fading: 0.12
        }
    }

    var presenceScale: CGFloat {
        switch behavior {
        case .idle, .observe: 0.76
        case .follow: 0.9
        case .drawNear: 1.08
        case .lead: 0.84
        case .rest: 0.82
        case .celebrate: 1.12
        }
    }

    var presenceOpacity: Double {
        switch behavior {
        case .idle, .observe: 0.64
        case .rest: 0.72
        default: 1
        }
    }

    var verticalOffset: CGFloat { behavior == .lead ? -20 : 0 }
    var animationDuration: Double? { isPaused ? nil : (behavior == .rest ? 2.8 : 1.6) }
    func animationDuration(reduceMotion: Bool) -> Double? { reduceMotion ? nil : animationDuration }

    var elapsedText: String {
        let total = max(0, Int(elapsedSeconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    var distanceText: String { "\(max(0, Int(distanceMeters))) m" }
    var pressureLabel: String { pursuitState == .inactive ? "Path quiet" : "Pressure \(pursuitState.rawValue)" }
    var audioLabel: String { audioCueKind == nil ? "Sound quiet" : "Sound active" }
    var animationKey: String { "\(behavior.rawValue)-\(pursuitState.rawValue)-\(eventKind?.rawValue ?? "none")" }

    // MARK: Accessibility presentation (VoiceOver-only; never alters the
    // visible phrases or any runtime state mapping)

    /// Human wording for the current companion behavior. Raw enum names must
    /// never reach VoiceOver.
    var behaviorAccessibilityDescription: String {
        switch behavior {
        case .idle: "waiting quietly"
        case .follow: "staying close"
        case .lead: "moving ahead"
        case .celebrate: "celebrating with you"
        case .observe: "watching the path"
        case .drawNear: "drawing near"
        case .rest: "resting beside you"
        }
    }

    /// Pressure category as a short sentence. No numeric values, no enum names.
    var pressureAccessibilityDescription: String {
        switch pursuitState {
        case .inactive: "The path is calm."
        case .noticed: "Something has changed on the path."
        case .approaching: "The pressure is building."
        case .close: "The pressure is very close."
        case .fading: "The pressure is fading."
        }
    }

    /// Combined description for the presence visualization, e.g.
    /// "Lira, staying close. The path is calm."
    var presenceAccessibilityValue: String {
        if isOpening { return "\(companionName) is listening." }
        return "\(companionName), \(behaviorAccessibilityDescription). \(pressureAccessibilityDescription)"
    }

    var audioAccessibilityLabel: String {
        audioCueKind == nil ? "Sound, quiet" : "Sound, active"
    }

    /// "Elapsed time, 4 minutes 12 seconds" — avoids VoiceOver reading "4:12"
    /// as bare digits and punctuation.
    var elapsedAccessibilityValue: String {
        let total = max(0, Int(elapsedSeconds))
        let minutes = total / 60
        let seconds = total % 60
        let secondsPart = "\(seconds) second\(seconds == 1 ? "" : "s")"
        if minutes == 0 { return "Elapsed time, \(secondsPart)" }
        return "Elapsed time, \(minutes) minute\(minutes == 1 ? "" : "s") \(secondsPart)"
    }

    var distanceAccessibilityValue: String {
        let meters = max(0, Int(distanceMeters))
        return "Distance, \(meters) meter\(meters == 1 ? "" : "s")"
    }

    /// Geometry channel for pressure so the state never depends on color
    /// alone: the outer ring thickens as pressure rises.
    var pressureStrokeWidth: CGFloat {
        2 + pressureIntensity * 4
    }
}

enum CompanionPresenceStyle {
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 18

    static func background(for pressure: Double) -> Color {
        Color(
            red: 0.04 + pressure * 0.12,
            green: 0.10 - pressure * 0.035,
            blue: 0.11 - pressure * 0.025
        )
    }
}

struct CompanionPresenceView: View {
    let presentation: CompanionPresencePresentation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.companionName)
                        .font(.title2.bold())
                        .accessibilityIdentifier("waykin.session.companionName")
                        .accessibilitySortPriority(100)
                    Text("Companion Walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("waykin.session.screen")
                        .accessibilitySortPriority(99)
                }
                Spacer()
                Text("Bond \(presentation.bondLevel)")
                    .font(.headline)
                    .accessibilityIdentifier("waykin.session.bond")
                    .accessibilitySortPriority(98)
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.16 + presentation.pressureIntensity * 0.28),
                            lineWidth: presentation.pressureStrokeWidth)
                    .frame(width: 176, height: 176)
                Circle()
                    .stroke(Color(red: 0.42, green: 0.82, blue: 0.78).opacity(0.48), lineWidth: 5)
                    .frame(width: 126, height: 126)
                Circle()
                    .fill(presenceColor)
                    .frame(width: 76, height: 76)
                    .overlay(Circle().fill(Color.white.opacity(0.25)).frame(width: 24, height: 24))
            }
            .scaleEffect(presentation.presenceScale * (expanded ? 1.035 : 1))
            .opacity(presentation.presenceOpacity)
            .offset(y: presentation.verticalOffset)
            .frame(height: 190)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(presentation.companionName) presence")
            .accessibilityValue(presentation.presenceAccessibilityValue)
            .accessibilityIdentifier("waykin.session.presence")
            .accessibilitySortPriority(90)

            Text(presentation.phrase)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("waykin.session.phrase")
                .accessibilitySortPriority(80)

            // Metrics before status for VoiceOver (identity → phrase →
            // metrics → status); visual order is unchanged below.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { statusLabels }
                VStack(alignment: .leading, spacing: 8) { statusLabels }
            }
            .font(.callout)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 48) { metrics }
                VStack(spacing: 12) { metrics }
            }
        }
        .foregroundStyle(.white)
        .onAppear(perform: animatePresence)
        .onChange(of: presentation.animationKey) { _, _ in animatePresence() }
    }

    private var presenceColor: Color {
        switch presentation.behavior {
        case .drawNear, .celebrate: Color(red: 0.95, green: 0.69, blue: 0.31)
        case .rest: Color(red: 0.48, green: 0.65, blue: 0.72)
        default: Color(red: 0.34, green: 0.82, blue: 0.76)
        }
    }

    @ViewBuilder private var statusLabels: some View {
        Label(presentation.pressureLabel, systemImage: "circle.dotted")
            .accessibilityLabel(presentation.pressureAccessibilityDescription)
            .accessibilityIdentifier("waykin.session.pressure")
            .accessibilitySortPriority(60)
        Label(presentation.audioLabel, systemImage: presentation.audioCueKind == nil ? "speaker.slash" : "speaker.wave.2")
            .accessibilityLabel(presentation.audioAccessibilityLabel)
            .accessibilityIdentifier("waykin.session.audioCue")
            .accessibilitySortPriority(59)
    }

    @ViewBuilder private var metrics: some View {
        metric(value: presentation.elapsedText, label: "Time",
               identifier: "waykin.session.elapsed",
               accessibilityLabel: presentation.elapsedAccessibilityValue,
               sortPriority: 70)
        metric(value: presentation.distanceText, label: "Distance",
               identifier: "waykin.session.distance",
               accessibilityLabel: presentation.distanceAccessibilityValue,
               sortPriority: 69)
    }

    private func metric(value: String, label: String, identifier: String,
                        accessibilityLabel: String, sortPriority: Double) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.monospacedDigit().bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
        .accessibilitySortPriority(sortPriority)
    }

    private func animatePresence() {
        expanded = false
        guard let duration = presentation.animationDuration(reduceMotion: reduceMotion) else { return }
        withAnimation(.easeInOut(duration: duration).repeatCount(2, autoreverses: true)) {
            expanded = true
        }
    }
}

struct CompactSessionMap: View {
    let latitude: Double?
    let longitude: Double?

    var body: some View {
        let center = CLLocationCoordinate2D(
            latitude: latitude ?? 37.7749,
            longitude: longitude ?? -122.4194
        )
        VStack(alignment: .leading, spacing: 6) {
            Label("Location context", systemImage: "map")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
            Map(
                initialPosition: .region(MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )),
                interactionModes: []
            ) {
                if latitude != nil, longitude != nil {
                    Marker("Current location", coordinate: center)
                }
            }
            .id("\(latitude ?? 0)-\(longitude ?? 0)")
            .frame(height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            // One inert element: VoiceOver gets the role description only —
            // no marker child, no coordinates, no focus trap inside MapKit.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(latitude == nil
                ? "Map, waiting for location. Decorative context only."
                : "Map, general area context. Decorative context only.")
            .accessibilityIdentifier("waykin.session.map")
        }
    }
}
