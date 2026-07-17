import Foundation

/// Persistence seam. The iOS app implements this over SwiftData;
/// tests and the simulator use `InMemoryStore`.
public protocol MemoryStore: AnyObject {
    func save(_ memory: Memory)
    func allMemories() -> [Memory]
    func save(_ location: LocationMemory)
    func allLocations() -> [LocationMemory]
}

public final class InMemoryStore: MemoryStore {
    private var memories: [Memory] = []
    private var locations: [String: LocationMemory] = [:]

    public init() {}

    public func save(_ memory: Memory) { memories.append(memory) }
    public func allMemories() -> [Memory] { memories }
    public func save(_ location: LocationMemory) { locations[location.locationName] = location }
    public func allLocations() -> [LocationMemory] { Array(locations.values) }
}

/// Turns finished sessions into memories and place familiarity.
public final class MemoryEngine {
    private let store: MemoryStore

    public init(store: MemoryStore) {
        self.store = store
    }

    @discardableResult
    public func recordSession(_ session: MovementSession,
                              outcome: ExperienceOutcome,
                              experienceID: String,
                              experienceName: String,
                              locationName: String,
                              companionName: String) -> Memory {
        let memory = Memory(
            date: session.endedAt,
            locationName: locationName,
            durationSeconds: session.durationSeconds,
            distanceMeters: session.distanceMeters,
            experienceID: experienceID,
            experienceName: experienceName,
            bondGained: outcome.bondDelta,
            text: generateText(session: session, outcome: outcome, locationName: locationName)
        )
        store.save(memory)

        var location = store.allLocations().first { $0.locationName == locationName }
            ?? LocationMemory(locationName: locationName, visitCount: 0,
                              lastVisit: session.endedAt, totalDistanceMeters: 0)
        location.visitCount += 1
        location.lastVisit = session.endedAt
        location.totalDistanceMeters += session.distanceMeters
        store.save(location)

        return memory
    }

    public func mostRecentMemory() -> Memory? {
        store.allMemories().max { $0.date < $1.date }
    }

    public func recentMemories(limit: Int) -> [Memory] {
        Array(store.allMemories().sorted { $0.date > $1.date }.prefix(limit))
    }

    public func locationMemory(named name: String) -> LocationMemory? {
        store.allLocations().first { $0.locationName == name }
    }

    public func favoritePlaces() -> [LocationMemory] {
        store.allLocations().filter(\.isFavorite).sorted { $0.visitCount > $1.visitCount }
    }

    /// Template-based memory text — deliberately deterministic so the MPOC
    /// works fully offline. The AI layer can rewrite these when connected.
    private func generateText(session: MovementSession,
                              outcome: ExperienceOutcome,
                              locationName: String) -> String {
        let timeOfDay = TimeOfDay.from(hour: Calendar.current.component(.hour, from: session.endedAt))
        let scene: String
        switch timeOfDay {
        case .morning: scene = "in the morning light"
        case .afternoon: scene = "under the afternoon sun"
        case .evening: scene = "as the sun went down"
        case .night: scene = "under the night sky"
        }
        let km = String(format: "%.1f", session.distanceMeters / 1000)
        return "We \(outcome.memorySeed) at \(locationName) \(scene) — \(km) km side by side."
    }
}
