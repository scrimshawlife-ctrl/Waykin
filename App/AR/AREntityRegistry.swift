import RealityKit

@MainActor
final class AREntityRegistry {
    private var entities: [String: Entity] = [:]

    var count: Int { entities.count }

    func entity(for id: String) -> Entity? {
        entities[id]
    }

    func register(_ entity: Entity, for id: String) {
        remove(id)
        entities[id] = entity
    }

    @discardableResult
    func remove(_ id: String) -> Entity? {
        guard let entity = entities.removeValue(forKey: id) else { return nil }
        Self.detach(entity)
        return entity
    }

    func clear() {
        for entity in entities.values {
            Self.detach(entity)
        }
        entities.removeAll(keepingCapacity: true)
    }

    /// Detach an entity, including anchors.
    ///
    /// Companions are placed on `AnchorEntity`s added with `scene.addAnchor`, and those
    /// are owned by the scene's anchor collection rather than by a parent entity —
    /// `removeFromParent()` alone does not take them out of the scene. Every replaced
    /// companion therefore stayed rendered: the procedural placeholder that spawns before
    /// the packaged asset finishes loading was still standing in front of the real mesh,
    /// which on device looked like the authored companion had never been swapped in.
    private static func detach(_ entity: Entity) {
        if let anchor = entity as? AnchorEntity, let scene = anchor.scene {
            scene.removeAnchor(anchor)
            return
        }
        entity.removeFromParent()
    }
}
