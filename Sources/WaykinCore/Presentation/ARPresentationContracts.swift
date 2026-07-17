import Foundation

public enum ARCapabilityState: String, Codable, CaseIterable, Sendable {
    case checking
    case available
    case unsupported
    case cameraDenied
    case trackingLimited
    case active
}

public struct CompanionPresentation: Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let behavior: String
    public let spatialIntent: SpatialIntent

    public init(id: UUID, name: String, behavior: String, spatialIntent: SpatialIntent) {
        self.id = id
        self.name = name
        self.behavior = behavior
        self.spatialIntent = spatialIntent
    }
}

public struct DiscoveryPresentation: Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: String
    public let spatialIntent: SpatialIntent

    public init(id: UUID, kind: String, spatialIntent: SpatialIntent) {
        self.id = id
        self.kind = kind
        self.spatialIntent = spatialIntent
    }
}

public struct ThreatPresentation: Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: String
    public let intensity: Double
    public let spatialIntent: SpatialIntent

    public init(id: UUID, kind: String, intensity: Double, spatialIntent: SpatialIntent) {
        self.id = id
        self.kind = kind
        self.intensity = min(max(intensity.isFinite ? intensity : 0, 0), 1)
        self.spatialIntent = spatialIntent
    }
}

public enum ARWorldCommand: Codable, Equatable, Sendable {
    case spawnCompanion(CompanionPresentation)
    case updateCompanion(CompanionPresentation)
    case spawnDiscovery(DiscoveryPresentation)
    case spawnThreat(ThreatPresentation)
    case updateThreat(ThreatPresentation)
    case removeEntity(UUID)
    case clearSession
}
