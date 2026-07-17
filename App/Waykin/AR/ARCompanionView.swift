import SwiftUI
import Combine
import RealityKit
import ARKit
import WaykinCore

/// The AR companion: a stylized creature entity anchored ~1.5 m ahead of the
/// camera that re-follows as you move, with idle/walk/run/celebrate motion.
/// Falls back to the 2D avatar wherever ARKit isn't supported (Simulator).
struct ARCompanionView: View {
    let species: Companion.Species
    @Binding var behavior: CompanionBehavior

    var body: some View {
        if ARWorldTrackingConfiguration.isSupported {
            CompanionARViewContainer(species: species, behavior: $behavior)
        } else {
            ZStack {
                LinearGradient(colors: [.indigo.opacity(0.6), .black],
                               startPoint: .top, endPoint: .bottom)
                VStack(spacing: 12) {
                    CompanionAvatar(species: species, behavior: behavior)
                    Text("AR unavailable here — companion in spirit")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
}

struct CompanionARViewContainer: UIViewRepresentable {
    let species: Companion.Species
    @Binding var behavior: CompanionBehavior

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
        context.coordinator.attach(to: arView, species: species)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.behavior = behavior
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        coordinator.detach()
    }

    /// Owns the companion entity and a per-frame update loop:
    /// keeps the creature ~1.5 m ahead of the camera (follow), bobs it
    /// (idle/walk/run), and spins it (celebrate).
    final class Coordinator {
        var behavior: CompanionBehavior = .idle

        private weak var arView: ARView?
        private var companion: ModelEntity?
        private var anchor: AnchorEntity?
        private var subscription: (any Cancellable)?
        private var time: Float = 0

        func attach(to arView: ARView, species: Companion.Species) {
            self.arView = arView

            let body = ModelEntity(
                mesh: .generateSphere(radius: 0.12),
                materials: [SimpleMaterial(color: color(for: species), isMetallic: false)])
            let head = ModelEntity(
                mesh: .generateSphere(radius: 0.07),
                materials: [SimpleMaterial(color: color(for: species), isMetallic: false)])
            head.position = [0, 0.14, 0.04]
            body.addChild(head)

            let anchor = AnchorEntity(world: [0, -0.3, -1.5])
            anchor.addChild(body)
            arView.scene.addAnchor(anchor)
            self.companion = body
            self.anchor = anchor

            subscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                self?.tick(deltaTime: Float(event.deltaTime))
            }
        }

        func detach() {
            subscription?.cancel()
            subscription = nil
        }

        private func tick(deltaTime: Float) {
            guard let arView, let companion, let anchor else { return }
            time += deltaTime

            // Follow: ease the anchor toward a point 1.5 m ahead of the camera.
            let camera = arView.cameraTransform
            let forward = -normalize(SIMD3<Float>(camera.matrix.columns.2.x,
                                                  0,
                                                  camera.matrix.columns.2.z))
            let target = camera.translation + forward * 1.5 + SIMD3<Float>(0, -0.3, 0)
            let speed: Float = behavior == .run ? 4 : 2
            let current = anchor.position(relativeTo: nil)
            anchor.setPosition(current + (target - current) * min(1, deltaTime * speed), relativeTo: nil)

            // Face the camera.
            companion.look(at: camera.translation, from: companion.position(relativeTo: nil),
                           relativeTo: nil)

            // Behavior motion: bob rate by state, spin on celebrate.
            let bobRate: Float
            switch behavior {
            case .idle, .alert: bobRate = 1.5
            case .walk, .follow: bobRate = 4
            case .run: bobRate = 8
            case .celebrate: bobRate = 6
            }
            companion.position.y = 0.05 * sin(time * bobRate)
            if behavior == .celebrate {
                companion.orientation = simd_quatf(angle: time * 4, axis: [0, 1, 0])
            }
        }

        private func color(for species: Companion.Species) -> UIColor {
            switch species {
            case .emberfox: return .systemOrange
            case .mosswing: return .systemGreen
            case .tidewolf: return .systemTeal
            }
        }
    }
}
