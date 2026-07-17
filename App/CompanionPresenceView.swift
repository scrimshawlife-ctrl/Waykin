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
    var elapsedAccessibilityValue: String {
        let total = max(0, Int(elapsedSeconds))
        let minutes = total / 60
        let seconds = total % 60
        let minuteText = "\(minutes) minute\(minutes == 1 ? "" : "s")"
        let secondText = "\(seconds) second\(seconds == 1 ? "" : "s")"

        if minutes == 0 { return secondText }
        if seconds == 0 { return minuteText }
        return "\(minuteText), \(secondText)"
    }
    var distanceAccessibilityValue: String {
        let meters = max(0, Int(distanceMeters))
        return "\(meters) meter\(meters == 1 ? "" : "s")"
    }
    var pressureLabel: String { pursuitState == .inactive ? "Path quiet" : "Pressure \(pursuitState.rawValue)" }
    var pressureAccessibilityValue: String {
        switch pursuitState {
        case .inactive: "The path is quiet."
        case .noticed: "A change has been noticed on the path."
        case .approaching: "Something is drawing closer on the path."
        case .close: "The pressure is close."
        case .fading: "The pressure is fading."
        }
    }
    var pressureStrokeWidth: CGFloat { CGFloat(2 + pressureIntensity * 6) }
    var audioLabel: String { audioCueKind == nil ? "Sound quiet" : "Sound active" }
    var phraseIsRedundantForAccessibility: Bool {
        guard !isOpening else { return false }

        return switch eventKind {
        case .pursuitIntensifies:
            pursuitState == .close
        case .pursuitFades:
            pursuitState == .fading
        case .quietInterval:
            pursuitState == .inactive
        case nil:
            pursuitState == .close || pursuitState == .fading
        default:
            false
        }
    }
    var animationKey: String { "\(behavior.rawValue)-\(pursuitState.rawValue)-\(eventKind?.rawValue ?? "none")" }
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 16) {
            AnyLayout(dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.companionName)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilitySortPriority(6)
                        .accessibilityIdentifier("waykin.session.companionName")
                    Text("Companion Walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilitySortPriority(5.9)
                        .accessibilityIdentifier("waykin.session.screen")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Bond \(presentation.bondLevel)")
                    .font(.headline)
                    .accessibilityLabel("Bond level")
                    .accessibilityValue("\(presentation.bondLevel)")
                    .accessibilitySortPriority(5.8)
                    .accessibilityIdentifier("waykin.session.bond")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .stroke(
                        Color.white.opacity(0.16 + presentation.pressureIntensity * 0.28),
                        lineWidth: presentation.pressureStrokeWidth
                    )
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
            .accessibilitySortPriority(5)
            .accessibilityIdentifier("waykin.session.presence")

            Text(presentation.phrase)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilitySortPriority(4.8)
                .accessibilityIdentifier("waykin.session.phrase")
                .accessibilityHidden(presentation.phraseIsRedundantForAccessibility)

            AnyLayout(dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 24))) {
                Label(presentation.pressureLabel, systemImage: "circle.dotted")
                    .accessibilityLabel("Path status")
                    .accessibilityValue(presentation.pressureAccessibilityValue)
                    .accessibilitySortPriority(4.6)
                    .accessibilityIdentifier("waykin.session.pressure")
                Label(presentation.audioLabel, systemImage: presentation.audioCueKind == nil ? "speaker.slash" : "speaker.wave.2")
                    .accessibilityLabel("Sound status")
                    .accessibilityValue(presentation.audioLabel)
                    .accessibilitySortPriority(4.5)
                    .accessibilityIdentifier("waykin.session.audioCue")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)

            AnyLayout(dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 48))) {
                metric(
                    value: presentation.elapsedText,
                    accessibilityValue: presentation.elapsedAccessibilityValue,
                    label: "Time",
                    identifier: "waykin.session.elapsed"
                )
                metric(
                    value: presentation.distanceText,
                    accessibilityValue: presentation.distanceAccessibilityValue,
                    label: "Distance",
                    identifier: "waykin.session.distance"
                )
            }
            .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        }
        .foregroundStyle(.white)
        .onAppear(perform: animatePresence)
        .onChange(of: presentation.animationKey) { _, _ in animatePresence() }
        .onChange(of: reduceMotion) { _, _ in animatePresence() }
    }

    private var presenceColor: Color {
        switch presentation.behavior {
        case .drawNear, .celebrate: Color(red: 0.95, green: 0.69, blue: 0.31)
        case .rest: Color(red: 0.48, green: 0.65, blue: 0.72)
        default: Color(red: 0.34, green: 0.82, blue: 0.76)
        }
    }

    private func metric(value: String, accessibilityValue: String, label: String, identifier: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.monospacedDigit().bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue)
        .accessibilitySortPriority(4)
        .accessibilityIdentifier(identifier)
    }

    private func animatePresence() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            expanded = false
        }
        guard let duration = presentation.animationDuration(reduceMotion: reduceMotion) else { return }
        withAnimation(.easeInOut(duration: duration).repeatCount(2, autoreverses: true)) {
            expanded = true
        }
    }
}

struct CompactSessionMap: View {
    let latitude: Double?
    let longitude: Double?

    var locationAccessibilityValue: String {
        latitude == nil || longitude == nil
            ? "Waiting for a location update."
            : "Current location is available for this walk."
    }

    var body: some View {
        let center = CLLocationCoordinate2D(
            latitude: latitude ?? 37.7749,
            longitude: longitude ?? -122.4194
        )
        VStack(alignment: .leading, spacing: 6) {
            Label("Location context", systemImage: "map")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
                .accessibilityHidden(true)
            ZStack {
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
                .accessibilityHidden(true)

                Color.clear
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Location context")
                    .accessibilityValue(locationAccessibilityValue)
                    .accessibilityAddTraits(.isImage)
                    .accessibilitySortPriority(-1)
                    .accessibilityIdentifier("waykin.session.map")
            }
            .frame(height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
