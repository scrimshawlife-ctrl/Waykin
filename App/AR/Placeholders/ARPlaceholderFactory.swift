import RealityKit
import UIKit

@MainActor
enum ARPlaceholderFactory {
    static func makeDiscovery() -> Entity {
        let root = Entity()
        root.name = "DiscoveryRoot"
        let mesh = MeshResource.generateSphere(radius: 0.085)
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .systemPurple, isMetallic: true)])
        entity.name = "DiscoveryCore"
        entity.position.y = 0.11
        root.addChild(entity)
        return root
    }

    static func makeThreat(intensity: Double) -> Entity {
        let safeIntensity = Float(min(max(intensity.isFinite ? intensity : 0, 0), 1))
        let root = Entity()
        root.name = "ThreatRoot"
        let radius: Float = 0.12 + safeIntensity * 0.12
        let mesh = MeshResource.generateSphere(radius: radius)
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .systemRed, isMetallic: false)])
        entity.name = "ThreatCore"
        entity.position.y = radius
        root.addChild(entity)
        return root
    }
}
