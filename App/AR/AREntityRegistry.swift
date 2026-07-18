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
        entity.removeFromParent()
        return entity
    }

    func clear() {
        for entity in entities.values {
            entity.removeFromParent()
        }
        entities.removeAll(keepingCapacity: true)
    }
}
