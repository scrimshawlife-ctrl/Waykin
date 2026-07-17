import RealityKit
import UIKit

@MainActor
struct DiscoveryPlaceholderFactory {
    func makeEntity() -> Entity {
        let root = Entity()
        root.name = "DiscoveryRoot"
        let material = SimpleMaterial(color: UIColor(red: 0.95, green: 0.78, blue: 0.22, alpha: 1), isMetallic: true)
        let marker = ModelEntity(mesh: .generateSphere(radius: 0.09), materials: [material])
        marker.name = "DiscoveryCore"
        marker.position.y = 0.11
        root.addChild(marker)
        return root
    }
}

@MainActor
struct ThreatPlaceholderFactory {
    func makeEntity(intensity: Double) -> Entity {
        let root = Entity()
        root.name = "ThreatRoot"
        let normalized = Float(min(max(intensity.isFinite ? intensity : 0, 0), 1))
        let radius = 0.12 + (0.16 * normalized)
        let material = SimpleMaterial(color: UIColor(red: 0.72, green: 0.10, blue: 0.22, alpha: 1), isMetallic: false)
        let marker = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material])
        marker.name = "ThreatCore"
        marker.position.y = radius
        root.addChild(marker)
        return root
    }
}
