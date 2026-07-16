import Foundation

// Note: Full SwiftData implementation is used in the generated Xcode iOS target.
// For CLI package build / demo / tests we use a pure in-memory store.
public final class PersistenceStore {
    private var companions: [Companion] = []
    private var memories: [SessionMemory] = []
    
    public init() {}
    
    public func saveCompanion(_ companion: Companion) {
        if let idx = companions.firstIndex(where: { $0.id == companion.id }) {
            companions[idx] = companion
        } else {
            companions.append(companion)
        }
    }
    
    public func loadCompanion() -> Companion? {
        return companions.last
    }
    
    public func saveMemory(_ memory: SessionMemory) {
        memories.append(memory)
    }
    
    public func loadMemories() -> [SessionMemory] {
        return memories.sorted { $0.timestamp > $1.timestamp }
    }
    
    public func resetDemoData() {
        companions.removeAll()
        memories.removeAll()
    }
}
