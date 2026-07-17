import Foundation
import SwiftData
import WaykinCore

// SwiftData models mirror the pure WaykinCore value types. The core engines
// never see SwiftData — this file is the only translation point.

@Model
final class StoredCompanion {
    @Attribute(.unique) var id: UUID
    var name: String
    var speciesRaw: String
    var createdAt: Date
    var bondPoints: Int
    var totalSessions: Int
    var totalDistanceMeters: Double

    init(_ companion: Companion) {
        id = companion.id
        name = companion.name
        speciesRaw = companion.species.rawValue
        createdAt = companion.createdAt
        bondPoints = companion.relationship.bondPoints
        totalSessions = companion.totalSessions
        totalDistanceMeters = companion.totalDistanceMeters
    }

    var asCompanion: Companion {
        var companion = Companion(id: id, name: name,
                                  species: .init(rawValue: speciesRaw) ?? .emberfox,
                                  createdAt: createdAt)
        companion.relationship.bondPoints = bondPoints
        companion.totalSessions = totalSessions
        companion.totalDistanceMeters = totalDistanceMeters
        return companion
    }

    func apply(_ companion: Companion) {
        bondPoints = companion.relationship.bondPoints
        totalSessions = companion.totalSessions
        totalDistanceMeters = companion.totalDistanceMeters
    }
}

@Model
final class StoredMemory {
    @Attribute(.unique) var id: UUID
    var date: Date
    var locationName: String
    var durationSeconds: TimeInterval
    var distanceMeters: Double
    var experienceID: String
    var experienceName: String
    var bondGained: Int
    var text: String

    init(_ memory: Memory) {
        id = memory.id
        date = memory.date
        locationName = memory.locationName
        durationSeconds = memory.durationSeconds
        distanceMeters = memory.distanceMeters
        experienceID = memory.experienceID
        experienceName = memory.experienceName
        bondGained = memory.bondGained
        text = memory.text
    }

    var asMemory: Memory {
        Memory(id: id, date: date, locationName: locationName,
               durationSeconds: durationSeconds, distanceMeters: distanceMeters,
               experienceID: experienceID, experienceName: experienceName,
               bondGained: bondGained, text: text)
    }
}

@Model
final class StoredLocationMemory {
    @Attribute(.unique) var locationName: String
    var visitCount: Int
    var lastVisit: Date
    var totalDistanceMeters: Double

    init(_ location: LocationMemory) {
        locationName = location.locationName
        visitCount = location.visitCount
        lastVisit = location.lastVisit
        totalDistanceMeters = location.totalDistanceMeters
    }

    var asLocationMemory: LocationMemory {
        LocationMemory(locationName: locationName, visitCount: visitCount,
                       lastVisit: lastVisit, totalDistanceMeters: totalDistanceMeters)
    }
}

/// WaykinCore.MemoryStore backed by SwiftData.
final class SwiftDataMemoryStore: MemoryStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ memory: Memory) {
        context.insert(StoredMemory(memory))
        try? context.save()
    }

    func allMemories() -> [Memory] {
        let stored = (try? context.fetch(FetchDescriptor<StoredMemory>())) ?? []
        return stored.map(\.asMemory)
    }

    func save(_ location: LocationMemory) {
        let name = location.locationName
        let descriptor = FetchDescriptor<StoredLocationMemory>(
            predicate: #Predicate { $0.locationName == name })
        if let existing = try? context.fetch(descriptor).first {
            existing.visitCount = location.visitCount
            existing.lastVisit = location.lastVisit
            existing.totalDistanceMeters = location.totalDistanceMeters
        } else {
            context.insert(StoredLocationMemory(location))
        }
        try? context.save()
    }

    func allLocations() -> [LocationMemory] {
        let stored = (try? context.fetch(FetchDescriptor<StoredLocationMemory>())) ?? []
        return stored.map(\.asLocationMemory)
    }
}
