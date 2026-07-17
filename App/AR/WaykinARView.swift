import ARKit
import RealityKit
import SwiftUI
import WaykinCore

@MainActor
struct WaykinARView: UIViewRepresentable {
    @Binding var capabilityState: ARCapabilityState
    let sessionCoordinator: ARSessionCoordinator
    let presentationController: ARPresentationController

    func makeCoordinator() -> Coordinator {
        Coordinator(presentationController: presentationController)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.session = sessionCoordinator.session

        context.coordinator.attach(to: arView)
        sessionCoordinator.onCapabilityStateChange = { state in
            capabilityState = state
        }

        Task {
            await sessionCoordinator.start()
        }
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {}

    static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        coordinator.clear()
        arView.session.pause()
    }

    @MainActor
    final class Coordinator: NSObject {
        private let presentationController: ARPresentationController

        init(presentationController: ARPresentationController) {
            self.presentationController = presentationController
        }

        func attach(to arView: ARView) {
            presentationController.attach(to: arView)
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            arView.addGestureRecognizer(tap)
        }

        @objc private func handleTap() {
            presentationController.placeCompanion()
        }

        func clear() {
            presentationController.clear()
        }
    }
}

@MainActor
struct ARSessionShellView: View {
    @State private var capabilityState: ARCapabilityState = .checking
    @State private var sessionCoordinator = ARSessionCoordinator()
    @State private var presentationController = ARPresentationController()
    @State private var controlsExpanded = true

    var body: some View {
        ZStack(alignment: .top) {
            WaykinARView(
                capabilityState: $capabilityState,
                sessionCoordinator: sessionCoordinator,
                presentationController: presentationController
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Text(statusText)
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityIdentifier("waykin.ar.capabilityState")

                if controlsExpanded {
                    controlPanel
                } else {
                    Button("Show Controls") { controlsExpanded = true }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 10)
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Place Lira") { presentationController.placeCompanion() }
                    .accessibilityIdentifier("waykin.ar.placeCompanion")
                Button("Clear") { presentationController.clear() }
                    .accessibilityIdentifier("waykin.ar.clear")
                Button("Hide") { controlsExpanded = false }
            }
            .buttonStyle(.borderedProminent)

            HStack {
                stateButton(.idle)
                stateButton(.follow)
                stateButton(.investigate)
            }
            HStack {
                stateButton(.alert)
                stateButton(.celebrate)
                Button("Discovery") { presentationController.spawnDiscovery() }
                    .accessibilityIdentifier("waykin.ar.spawnDiscovery")
                Button("Threat") { presentationController.spawnThreat() }
                    .accessibilityIdentifier("waykin.ar.spawnThreat")
            }
            .buttonStyle(.bordered)

            Text("Entities: \(presentationController.registryCount) • State: \(presentationController.currentCompanionState.rawValue) • Result: \(presentationController.lastCommandResult?.rawValue ?? "none")")
                .font(.caption2.monospaced())
                .lineLimit(2)
                .accessibilityIdentifier("waykin.ar.diagnostics")
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func stateButton(_ state: CompanionPresentationState) -> some View {
        Button(state.rawValue.capitalized) {
            presentationController.setCompanionState(state)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("waykin.ar.state.\(state.rawValue)")
    }

    private var statusText: String {
        switch capabilityState {
        case .checking:
            "Checking AR capability…"
        case .available:
            "AR ready"
        case .unsupported:
            "AR is not supported on this device"
        case .cameraDenied:
            "Camera access is required for AR"
        case .trackingLimited:
            "Move slowly while tracking recovers"
        case .active:
            "Tap a surface or use Place Lira"
        }
    }
}
