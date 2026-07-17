import Foundation

/// One generated memory of a shared session — the thing that makes the
/// companion feel alive across days.
public struct Memory: Codable, Identifiable, Equatable {
    public var id: UUID
    public var date: Date
    public var locationName: String
    public var durationSeconds: TimeInterval
    public var distanceMeters: Double
    public var experienceID: String
    public var experienceName: String
    public var bondGained: Int
    public var text: String

    public init(id: UUID = UUID(), date: Date, locationName: String,
                durationSeconds: TimeInterval, distanceMeters: Double,
                experienceID: String, experienceName: String,
                bondGained: Int, text: String) {
        self.id = id
        self.date = date
        self.locationName = locationName
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.experienceID = experienceID
        self.experienceName = experienceName
        self.bondGained = bondGained
        self.text = text
    }
}

/// Aggregated familiarity with a place, built up across visits.
public struct LocationMemory: Codable, Equatable {
    public var locationName: String
    public var visitCount: Int
    public var lastVisit: Date
    public var totalDistanceMeters: Double

    public init(locationName: String, visitCount: Int, lastVisit: Date, totalDistanceMeters: Double) {
        self.locationName = locationName
        self.visitCount = visitCount
        self.lastVisit = lastVisit
        self.totalDistanceMeters = totalDistanceMeters
    }

    public var isFavorite: Bool { visitCount >= 3 }
}
