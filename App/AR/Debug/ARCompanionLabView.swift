import Combine
import Observation
import RealityKit
import SwiftUI
import WaykinCore

@MainActor
@Observable
final class ARCompanionLabRuntime {
    private let registry: AREntityRegistry
    private let diagnostics: ARDiagnosticRecorder
    private let sessionCoordinator: ARSessionCoordinator
    private let renderer: ARWorldCommandRenderer
    @ObservationIgnored private var sceneUpdateSubscription: Cancellable?

    private(set) var capabilityState: ARCapabilityState = .checking
    private(set) var lastResult = "Waiting for AR session"
    private(set) var transitionResult = "No companion transition"
    private(set) var currentState: CompanionPresentationState = .idle
    private(set) var trackingText = "Checking"
    private weak var arView: ARView?

    var registryCount: Int { registry.count }
    var receipt: ARValidationReceipt { diagnostics.summary }

    init() {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        self.registry = registry
        self.diagnostics = diagnostics
        self.sessionCoordinator = ARSessionCoordinator()
        self.renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)
    }

    func attach(_ arView: ARView) {
        sceneUpdateSubscription?.cancel()
        self.arView = arView
        arView.session = sessionCoordinator.session
        sceneUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.advanceCompanionPresentation(by: event.deltaTime)
        }
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

    func detach(_ arView: ARView) {
        guard self.arView === arView else { return }
        if registry.count > 0 || currentState != .idle {
            clear()
        }
        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = nil
        self.arView = nil
    }

    func placeLira() {
        guard let arView else { return }
        let presentation = CompanionPresentation(
            id: UUID(),
            name: "Lira",
            behavior: currentState.rawValue,
            spatialIntent: companionIntent
        )
        let result = renderer.render(.spawnCompanion(presentation), in: arView)
        report(result)
        synchronizeCompanionState(after: result)
    }

    func setState(_ state: CompanionPresentationState) {
        let result = renderer.setCompanionState(state)
        report(result)
        synchronizeCompanionState(after: result)
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
        report(renderer.clearSession())
        currentState = .idle
        transitionResult = "Cleared to idle"
    }

    func pause() {
        clear()
        sceneUpdateSubscription?.cancel()
        sceneUpdateSubscription = nil
        sessionCoordinator.pause()
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

    private func synchronizeCompanionState(after result: ARCommandResult) {
        guard case .accepted = result else {
            transitionResult = "Deferred: companion missing"
            return
        }
        currentState = renderer.companionState
        report(renderer.lastCompanionTransition)
    }

    private func advanceCompanionPresentation(by delta: TimeInterval) {
        guard let transition = renderer.advanceCompanionPresentation(by: delta) else { return }
        currentState = transition.resolvedState
        report(transition)
    }

    private func report(_ transition: CompanionStateTransition?) {
        guard let transition else {
            transitionResult = "Companion state unchanged"
            return
        }
        transitionResult = "\(transition.outcome.rawValue): \(transition.resolvedState.rawValue)"
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

                HStack {
                    Text("State: \(runtime.currentState.rawValue.capitalized)")
                        .accessibilityIdentifier("waykin.ar.currentState")
                    Spacer()
                    Text(runtime.transitionResult)
                        .accessibilityIdentifier("waykin.ar.transitionResult")
                }
                .font(.caption2)

                if controlsExpanded {
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

    final class Coordinator {
        let runtime: ARCompanionLabRuntime

        init(runtime: ARCompanionLabRuntime) {
            self.runtime = runtime
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(runtime: runtime)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        runtime.attach(view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        // SwiftUI may retain the runtime after removing the RealityKit view.
        // Detaching prevents scene updates from advancing a paused presentation.
        coordinator.runtime.detach(uiView)
    }
}
