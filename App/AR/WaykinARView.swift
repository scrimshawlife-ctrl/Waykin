import ARKit
import RealityKit
import SwiftUI
import WaykinCore

@MainActor
struct WaykinARView: UIViewRepresentable {
    @Binding var capabilityState: ARCapabilityState
    let sessionCoordinator: ARSessionCoordinator

    func makeCoordinator() -> Coordinator {
        Coordinator()
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
        private let registry = AREntityRegistry()
        private lazy var placementResolver = ARPlacementResolver(registry: registry)
        private weak var arView: ARView?

        func attach(to arView: ARView) {
            self.arView = arView
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            arView.addGestureRecognizer(tap)
        }

        @objc private func handleTap() {
            guard let arView else { return }
            let intent = SpatialIntent(
                placement: .groundPlane,
                distanceBand: .near,
                bearing: .ahead,
                scaleClass: .discovery,
                persistence: .transient
            )
            _ = placementResolver.placePlaceholder(id: "ar1.placeholder", intent: intent, in: arView)
        }

        func clear() {
            placementResolver.clear()
        }
    }
}

@MainActor
struct ARSessionShellView: View {
    @State private var capabilityState: ARCapabilityState = .checking
    @State private var sessionCoordinator = ARSessionCoordinator()

    var body: some View {
        ZStack(alignment: .top) {
            WaykinARView(
                capabilityState: $capabilityState,
                sessionCoordinator: sessionCoordinator
            )
            .ignoresSafeArea()

            Text(statusText)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 12)
                .accessibilityIdentifier("waykin.ar.capabilityState")
        }
    }

    private var statusText: String {
        switch capabilityState {
        case .checking:
            return "Checking AR capability…"
        case .available:
            return "AR ready"
        case .unsupported:
            return "AR is not supported on this device"
        case .cameraDenied:
            return "Camera access is required for AR"
        case .trackingLimited:
            return "Move slowly while tracking recovers"
        case .active:
            return "Tap a detected surface to place a marker"
        }
    }
}
