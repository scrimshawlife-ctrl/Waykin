import Observation
import RealityKit
import SwiftUI
import WaykinCore

@MainActor
@Observable
final class ARCompanionLabRuntime {
    private let registry = AREntityRegistry()
    private let diagnostics = ARDiagnosticRecorder()
    private let sessionCoordinator = ARSessionCoordinator()
    private let demoBridge = ARDemoRuntimeBridge()
    private lazy var renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)

    private(set) var capabilityState: ARCapabilityState = .checking
    private(set) var lastResult = "Waiting for AR session"
    private(set) var currentState: CompanionPresentationState = .idle
    private(set) var trackingText = "Checking"
    private(set) var demoTickText = "Demo not started"
    private(set) var demoEventText = "No event"
    private weak var arView: ARView?

    var registryCount: Int { registry.count }
    var receipt: ARValidationReceipt { diagnostics.summary }
    var isDemoRunning: Bool { demoBridge.isRunning }

    func attach(_ arView: ARView) {
        self.arView = arView
        arView.session = sessionCoordinator.session
        sessionCoordinator.onCapabilityStateChange = { [weak self] state in
            self?.capabilityState = state
            self?.trackingText = state.rawValue
            if state == .active {
                self?.diagnostics.record(.trackingNormal)
            }
        }
        diagnostics.record(.sessionStarted)
        Task { await sessionCoordinator.start() }
    }

    func placeLira() {
        guard let arView else { return }
        let presentation = CompanionPresentation(
            id: ARCompanionRuntimeAdapter.companionID,
            name: "Lira",
            behavior: currentState.rawValue,
            spatialIntent: companionIntent
        )
        report(renderer.render(.spawnCompanion(presentation), in: arView))
    }

    func setState(_ state: CompanionPresentationState) {
        currentState = state
        report(renderer.setCompanionState(state))
    }

    func startDemoArc() {
        guard let arView else { return }
        do {
            clearRenderedContent(resetDemo: false)
            let frame = try demoBridge.start()
            render(frame, in: arView)
            lastResult = "Demo arc started"
        } catch {
            lastResult = "Demo start failed"
        }
    }

    func advanceDemoArc() {
        guard let arView else { return }
        guard let frame = demoBridge.advance() else {
            lastResult = "Start the demo arc first"
            return
        }
        render(frame, in: arView)
    }

    func runDemoArcToEnd() {
        guard let arView else { return }
        if !demoBridge.isRunning {
            startDemoArc()
        }
        for frame in demoBridge.runRemaining() {
            render(frame, in: arView)
        }
        lastResult = "Demo arc complete"
    }

    func spawnDiscovery() {
        guard let arView else { return }
        let presentation = DiscoveryPresentation(
            id: UUID(),
            kind: "engineeringDiscovery",
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .contextual,
                scaleClass: .discovery,
                persistence: .transient
            )
        )
        report(renderer.render(.spawnDiscovery(presentation), in: arView))
    }

    func spawnThreat() {
        guard let arView else { return }
        let presentation = ThreatPresentation(
            id: UUID(),
            kind: "engineeringThreat",
            intensity: 0.65,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .medium,
                bearing: .ahead,
                scaleClass: .threat,
                persistence: .transient
            )
        )
        report(renderer.render(.spawnThreat(presentation), in: arView))
    }

    func clear() {
        clearRenderedContent(resetDemo: true)
    }

    func pause() {
        clearRenderedContent(resetDemo: true)
        sessionCoordinator.pause()
    }

    private func clearRenderedContent(resetDemo: Bool) {
        guard let arView else { return }
        report(renderer.render(.clearSession, in: arView))
        currentState = .idle
        demoTickText = "Demo not started"
        demoEventText = "No event"
        if resetDemo {
            demoBridge.reset()
        }
    }

    private func render(_ frame: ARDemoFrame, in arView: ARView) {
        for command in frame.commands {
            report(renderer.render(command, in: arView))
        }
        currentState = frame.companionState
        demoTickText = "Tick \(frame.tickIndex)/\(demoBridge.totalTicks) • distance \(String(format: "%.1f", frame.relativeDistance))m"
        demoEventText = frame.eventKind?.rawValue ?? "Opening"
        if frame.isComplete {
            lastResult = "Demo arc complete"
        }
    }

    private var companionIntent: SpatialIntent {
        SpatialIntent(
            placement: .groundPlane,
            distanceBand: .near,
            bearing: .ahead,
            scaleClass: .companion,
            persistence: .session
        )
    }

    private func report(_ result: ARCommandResult) {
        switch result {
        case .accepted(let detail): lastResult = "Accepted: \(detail)"
        case .deferred(let detail): lastResult = "Deferred: \(detail)"
        case .removed(let detail): lastResult = "Removed: \(detail)"
        case .cleared: lastResult = "Session cleared"
        }
    }
}

@MainActor
struct ARCompanionLabView: View {
    @State private var runtime = ARCompanionLabRuntime()
    @State private var controlsExpanded = true

    var body: some View {
        ZStack(alignment: .bottom) {
            ARCompanionCameraView(runtime: runtime)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 8) {
                    HStack {
                        Text("AR: \(runtime.trackingText)")
                        Spacer()
                        Text("Entities: \(runtime.registryCount)")
                            .accessibilityIdentifier("waykin.ar.registryCount")
                    }
                    .font(.caption.weight(.semibold))

                    Text(runtime.lastResult)
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("waykin.ar.lastCommand")

                    Text(runtime.demoTickText)
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("waykin.ar.demo.tick")
                    Text("Event: \(runtime.demoEventText)")
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("waykin.ar.demo.event")

                    if controlsExpanded {
                        HStack {
                            Button("Start Arc") { runtime.startDemoArc() }
                                .accessibilityIdentifier("waykin.ar.demo.start")
                            Button("Next Event") { runtime.advanceDemoArc() }
                                .accessibilityIdentifier("waykin.ar.demo.next")
                            Button("Run Arc") { runtime.runDemoArcToEnd() }
                                .accessibilityIdentifier("waykin.ar.demo.run")
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Place Lira") { runtime.placeLira() }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("waykin.ar.placeCompanion")

                        HStack {
                            stateButton(.idle)
                            stateButton(.follow)
                            stateButton(.investigate)
                        }
                        HStack {
                            stateButton(.alert)
                            stateButton(.celebrate)
                        }
                        HStack {
                            Button("Discovery") { runtime.spawnDiscovery() }
                                .accessibilityIdentifier("waykin.ar.spawnDiscovery")
                            Button("Threat") { runtime.spawnThreat() }
                                .accessibilityIdentifier("waykin.ar.spawnThreat")
                            Button("Clear", role: .destructive) { runtime.clear() }
                                .accessibilityIdentifier("waykin.ar.clear")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(controlsExpanded ? "Hide Controls" : "Show Controls") {
                        controlsExpanded.toggle()
                    }
                    .font(.caption)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .padding()
            }
            .frame(maxHeight: 330)
        }
        .navigationTitle("Waykin AR Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { runtime.pause() }
    }

    private func stateButton(_ state: CompanionPresentationState) -> some View {
        Button(state.rawValue.capitalized) { runtime.setState(state) }
            .buttonStyle(.bordered)
            .tint(runtime.currentState == state ? .accentColor : .secondary)
            .accessibilityIdentifier("waykin.ar.state.\(state.rawValue)")
    }
}

@MainActor
private struct ARCompanionCameraView: UIViewRepresentable {
    let runtime: ARCompanionLabRuntime

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        runtime.attach(view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
