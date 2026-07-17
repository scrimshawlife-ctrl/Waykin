import ARKit
import RealityKit
import SwiftUI
import WaykinCore

@MainActor
struct WaykinARView: UIViewRepresentable {
    @Binding var capabilityState: ARCapabilityState
    @Binding var pendingCommand: ARWorldCommand?
    @Binding var registryCount: Int
    @Binding var lastCommandResult: String
    let sessionCoordinator: ARSessionCoordinator

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.session = sessionCoordinator.session
        context.coordinator.attach(to: arView)
        sessionCoordinator.onCapabilityStateChange = { capabilityState = $0 }
        context.coordinator.diagnostics.record(.sessionStarted)
        Task { await sessionCoordinator.start() }
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        guard let command = pendingCommand else { return }
        let result = context.coordinator.renderer.render(command, in: arView)
        registryCount = context.coordinator.registry.count
        lastCommandResult = result.rawValue
        DispatchQueue.main.async { pendingCommand = nil }
    }

    static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        _ = coordinator.renderer.render(.clearSession, in: arView)
        coordinator.diagnostics.record(.sessionStopped)
        arView.session.pause()
    }

    @MainActor
    final class Coordinator: NSObject {
        let registry = AREntityRegistry()
        let diagnostics = ARDiagnosticRecorder()
        lazy var renderer = ARWorldCommandRenderer(registry: registry, diagnostics: diagnostics)

        func attach(to arView: ARView) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tap)
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let intent = SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .ahead,
                scaleClass: .discovery,
                persistence: .transient
            )
            let success = ARPlacementResolver(registry: registry).placePlaceholder(
                id: "ar1.placeholder",
                intent: intent,
                in: arView
            )
            diagnostics.record(success ? .placementSucceeded : .placementFailed, detail: "tap-marker")
        }
    }
}

@MainActor
struct ARSessionShellView: View {
    @State private var capabilityState: ARCapabilityState = .checking
    @State private var sessionCoordinator = ARSessionCoordinator()
    @State private var pendingCommand: ARWorldCommand?
    @State private var registryCount = 0
    @State private var currentState = CompanionPresentationState.idle
    @State private var lastCommandResult = "none"

    private let companionID = UUID(uuidString: "E144A294-8E20-4CE2-AF28-220BB84C087B")!

    var body: some View {
        ZStack(alignment: .top) {
            WaykinARView(
                capabilityState: $capabilityState,
                pendingCommand: $pendingCommand,
                registryCount: $registryCount,
                lastCommandResult: $lastCommandResult,
                sessionCoordinator: sessionCoordinator
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Text(statusText)
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityIdentifier("waykin.ar.capabilityState")

                Spacer()

                VStack(spacing: 8) {
                    HStack {
                        Button("Place Lira") { spawnLira() }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("waykin.ar.placeCompanion")
                        Button("Clear") { pendingCommand = .clearSession }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("waykin.ar.clear")
                    }

                    HStack {
                        stateButton("Idle", .idle)
                        stateButton("Follow", .follow)
                        stateButton("Investigate", .investigate)
                    }
                    HStack {
                        stateButton("Alert", .alert)
                        stateButton("Celebrate", .celebrate)
                    }

                    Text("Entities: \(registryCount) • State: \(currentState.rawValue) • Last: \(lastCommandResult)")
                        .font(.caption2.monospaced())
                        .accessibilityIdentifier("waykin.ar.registryCount")
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
    }

    private func stateButton(_ title: String, _ state: CompanionPresentationState) -> some View {
        Button(title) {
            currentState = state
            pendingCommand = .updateCompanion(companionPresentation(behavior: state.rawValue))
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("waykin.ar.state.\(state.rawValue)")
    }

    private func spawnLira() {
        currentState = .idle
        pendingCommand = .spawnCompanion(companionPresentation(behavior: "idle"))
    }

    private func companionPresentation(behavior: String) -> CompanionPresentation {
        CompanionPresentation(
            id: companionID,
            name: "Lira",
            behavior: behavior,
            spatialIntent: SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .ahead,
                scaleClass: .companion,
                persistence: .session
            )
        )
    }

    private var statusText: String {
        switch capabilityState {
        case .checking: "Checking AR capability…"
        case .available: "AR ready"
        case .unsupported: "AR is not supported on this device"
        case .cameraDenied: "Camera access is required for AR"
        case .trackingLimited: "Move slowly while tracking recovers"
        case .active: "Place Lira or tap a surface for a marker"
        }
    }
}
