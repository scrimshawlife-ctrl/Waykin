import RealityKit
import SwiftUI
import WaykinCore

@MainActor
struct WaykinARView: UIViewRepresentable {
    let controller: ARLabController

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        controller.attach(to: arView)
        Task { await controller.start() }
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {}

    static func dismantleUIView(_ arView: ARView, coordinator: Void) {
        arView.session.pause()
    }
}

@MainActor
struct ARSessionShellView: View {
    @StateObject private var controller = ARLabController()
    @State private var controlsExpanded = true

    var body: some View {
        ZStack(alignment: .top) {
            WaykinARView(controller: controller)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                statusHeader
                if controlsExpanded {
                    controlPanel
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .onDisappear { controller.stop() }
    }

    private var statusHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.callout.weight(.semibold))
                Text("Lira: \(controller.companionState.rawValue) • Entities: \(controller.registryCount) • \(controller.lastCommandResult)")
                    .font(.caption2)
            }
            Spacer()
            Button(controlsExpanded ? "Hide" : "Controls") {
                controlsExpanded.toggle()
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityIdentifier("waykin.ar.currentState")
    }

    private var controlPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Place Lira") { controller.placeCompanion() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("waykin.ar.placeCompanion")
                Button("Remove") { controller.removeCompanion() }
                    .buttonStyle(.bordered)
                Button("Reset") { Task { await controller.resetTracking() } }
                    .buttonStyle(.bordered)
            }

            HStack {
                stateButton("Idle", .idle, "waykin.ar.state.idle")
                stateButton("Follow", .follow, "waykin.ar.state.follow")
                stateButton("Investigate", .investigate, "waykin.ar.state.investigate")
            }

            HStack {
                stateButton("Alert", .alert, "waykin.ar.state.alert")
                stateButton("Celebrate", .celebrate, "waykin.ar.state.celebrate")
                Button("Clear") { controller.clear() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("waykin.ar.clear")
            }

            HStack {
                Button("Discovery") { controller.spawnDiscovery() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("waykin.ar.spawnDiscovery")
                Button("Threat") { controller.spawnThreat() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("waykin.ar.spawnThreat")
            }
        }
        .font(.caption)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func stateButton(
        _ title: String,
        _ state: CompanionPresentationState,
        _ identifier: String
    ) -> some View {
        Button(title) { controller.setCompanionState(state) }
            .buttonStyle(controller.companionState == state ? .borderedProminent : .bordered)
            .accessibilityIdentifier(identifier)
    }

    private var statusText: String {
        switch controller.capabilityState {
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
            return "Place Lira on a detected surface"
        }
    }
}
