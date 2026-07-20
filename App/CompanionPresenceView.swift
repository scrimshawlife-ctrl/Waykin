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
    /// Semantic path relation from `PathProgressEngine` (no coordinates).
    var pathRelation: PathRelation = .establishing
    /// 0…1 integrity pressure from path progress.
    var pathIntegrityPressure: Double = 0
    /// Coarse activity energy (0…~0.2) — presentation only; never blocks walk.
    var energyHint: Double = 0

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

        // Path relation phrases when pursuit is quiet and no stronger world event.
        switch pathRelation {
        case .strained: return "The path feels strained."
        case .offPath: return "The path has slipped."
        case .recovered: return "The path is finding you again."
        case .onPath:
            if energyHint >= 0.15 { return "\(companionName) matches your pace." }
            return "\(companionName) walks with you."
        case .establishing:
            break
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
        let pursuit: Double = switch pursuitState {
        case .inactive: 0
        case .noticed: 0.2
        case .approaching: 0.45
        case .close: 0.75
        case .fading: 0.12
        }
        // When pursuit is quiet, path integrity still colors the field lightly.
        if pursuitState == .inactive {
            return min(1, max(pursuit, pathIntegrityPressure * 0.85))
        }
        return min(1, max(pursuit, pathIntegrityPressure * 0.35))
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
        let base: Double = switch behavior {
        case .idle, .observe: 0.64
        case .rest: 0.72
        default: 1
        }
        // Subtle energy lift from optional Health enrichment (capped).
        return min(1, base + max(0, min(0.25, energyHint)) * 0.4)
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
    var pressureLabel: String {
        if pursuitState != .inactive {
            return "Pressure \(pursuitState.rawValue)"
        }
        switch pathRelation {
        case .strained: return "Path strained"
        case .offPath: return "Path slipped"
        case .recovered: return "Path recovering"
        case .onPath: return "Path steady"
        case .establishing: return "Path quiet"
        }
    }
    var pressureAccessibilityValue: String {
        switch pursuitState {
        case .noticed: return "A change has been noticed on the path."
        case .approaching: return "Something is drawing closer on the path."
        case .close: return "The pressure is close."
        case .fading: return "The pressure is fading."
        case .inactive:
            switch pathRelation {
            case .strained: return "The path feels strained."
            case .offPath: return "The path has slipped."
            case .recovered: return "The path is finding you again."
            case .onPath: return "The path holds steady."
            case .establishing: return "The path is quiet."
            }
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
    static let horizontalPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 18

    /// Echo session field: pressure wash on day mist / night indigo (theme-aware).
    static func background(for pressure: Double, theme: WKTheme) -> Color {
        theme.sessionBackground(pressure: pressure)
    }

    /// Legacy fallback when theme is unavailable (tests / previews).
    static func background(for pressure: Double) -> Color {
        WKTheme(colorScheme: .dark).sessionBackground(pressure: pressure)
    }
}

struct CompanionPresenceView: View {
    let presentation: CompanionPresencePresentation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.wkTheme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            AnyLayout(dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.companionName)
                        .font(.title2.bold())
                        .foregroundStyle(theme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilitySortPriority(6)
                        .accessibilityIdentifier("waykin.session.companionName")
                    Text("Companion Walk")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .accessibilitySortPriority(5.9)
                        .accessibilityIdentifier("waykin.session.screen")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Bond \(presentation.bondLevel)")
                    .font(.headline)
                    .foregroundStyle(theme.bondText)
                    .accessibilityLabel("Bond level")
                    .accessibilityValue("\(presentation.bondLevel)")
                    .accessibilitySortPriority(5.8)
                    .accessibilityIdentifier("waykin.session.bond")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Lira session-mid production puppet (poses + A1–A3 anchors)
            LiraSessionFigure(presentation: presentation)

            Text(presentation.phrase)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilitySortPriority(4.8)
                .accessibilityIdentifier("waykin.session.phrase")
                .accessibilityHidden(presentation.phraseIsRedundantForAccessibility)

            AnyLayout(dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 24))) {
                Label {
                    Text(presentation.pressureLabel)
                } icon: {
                    WKIconView(
                        icon: presentation.pressureIntensity >= 0.45 ? .companionBehind : .companionAhead,
                        size: 18
                    )
                }
                    .foregroundStyle(pressureTint)
                    .accessibilityLabel("Path status")
                    .accessibilityValue(presentation.pressureAccessibilityValue)
                    .accessibilitySortPriority(4.6)
                    .accessibilityIdentifier("waykin.session.pressure")
                Label {
                    Text(presentation.audioLabel)
                } icon: {
                    WKIconView(icon: .audio, size: 18)
                        .opacity(presentation.audioCueKind == nil ? 0.45 : 1)
                }
                    .foregroundStyle(theme.textSecondary)
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
    }

    private var pressureTint: Color {
        presentation.pressureIntensity >= 0.45 ? theme.hunter : theme.textSecondary
    }

    private func metric(value: String, accessibilityValue: String, label: String, identifier: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue)
        .accessibilitySortPriority(4)
        .accessibilityIdentifier(identifier)
    }
}

struct CompactSessionMap: View {
    let latitude: Double?
    let longitude: Double?
    var trace: WalkPathTrace = WalkPathTrace()
    @Environment(\.wkTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var camera: MapCameraPosition = .automatic

    var locationAccessibilityValue: String {
        guard latitude != nil, longitude != nil else {
            return "Waiting for a location update."
        }
        return trace.count >= 2
            ? "Current location and the walked path so far are shown."
            : "Current location is available for this walk."
    }

    private var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude ?? 37.7749,
            longitude: longitude ?? -122.4194
        )
    }

    private func region(around coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Location context", systemImage: "map")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
                .accessibilityHidden(true)
            ZStack {
                Map(position: $camera, interactionModes: []) {
                    if trace.count >= 2 {
                        MapPolyline(coordinates: trace.points.map(\.coordinate))
                            .stroke(theme.guide.opacity(0.85),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    if latitude != nil, longitude != nil {
                        Marker("Current location", coordinate: center)
                    }
                }
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
            .onAppear { camera = region(around: center) }
            .onChange(of: latitude) { _, _ in follow() }
            .onChange(of: longitude) { _, _ in follow() }
        }
    }

    /// Smoothly follows the walker; jumps directly under Reduce Motion.
    private func follow() {
        guard latitude != nil, longitude != nil else { return }
        let target = region(around: center)
        if reduceMotion {
            camera = target
        } else {
            withAnimation(.easeInOut(duration: 0.6)) { camera = target }
        }
    }
}
