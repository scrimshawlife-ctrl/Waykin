import Foundation

/// The persistent AI companion. Pure value type — persistence adapters live
/// in the app layer (SwiftData) and in `InMemoryStore` for tests/sim.
public struct Companion: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var species: Species
    public var createdAt: Date
    public var relationship: Relationship
    public var totalSessions: Int
    public var totalDistanceMeters: Double

    public enum Species: String, Codable, CaseIterable {
        case emberfox, mosswing, tidewolf
        public var displayName: String {
            switch self {
            case .emberfox: return "Emberfox"
            case .mosswing: return "Mosswing"
            case .tidewolf: return "Tidewolf"
            }
        }
    }

    public init(id: UUID = UUID(), name: String, species: Species = .emberfox, createdAt: Date) {
        self.id = id
        self.name = name
        self.species = species
        self.createdAt = createdAt
        self.relationship = Relationship()
        self.totalSessions = 0
        self.totalDistanceMeters = 0
    }
}

/// Bond between user and companion. Bond points accumulate from sessions;
/// levels gate greeting tone and dialogue warmth.
public struct Relationship: Codable, Equatable {
    public var bondPoints: Int

    public init(bondPoints: Int = 0) {
        self.bondPoints = bondPoints
    }

    public var level: Level {
        switch bondPoints {
        case ..<10: return .stranger
        case ..<30: return .acquaintance
        case ..<70: return .friend
        case ..<150: return .companion
        default: return .soulbound
        }
    }

    public enum Level: Int, Codable, Comparable, CaseIterable {
        case stranger, acquaintance, friend, companion, soulbound
        public static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
        public var displayName: String {
            switch self {
            case .stranger: return "Stranger"
            case .acquaintance: return "Acquaintance"
            case .friend: return "Friend"
            case .companion: return "Companion"
            case .soulbound: return "Soulbound"
            }
        }
    }
}
