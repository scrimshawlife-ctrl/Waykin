import Foundation

public enum SpatialPlacementMode: String, Codable, CaseIterable, Sendable {
    case groundPlane
    case worldRelative
    case cameraRelative
}

public enum SpatialDistanceBand: String, Codable, CaseIterable, Sendable {
    case immediate
    case near
    case medium
    case far
}

public enum SpatialBearingIntent: String, Codable, CaseIterable, Sendable {
    case ahead
    case beside
    case behind
    case contextual
}

public enum SpatialScaleClass: String, Codable, CaseIterable, Sendable {
    case companion
    case discovery
    case threat
    case environmental
}

public enum SpatialPersistence: String, Codable, CaseIterable, Sendable {
    case transient
    case encounter
    case session
}

public struct SpatialIntent: Codable, Equatable, Sendable {
    public let placement: SpatialPlacementMode
    public let distanceBand: SpatialDistanceBand
    public let bearing: SpatialBearingIntent
    public let scaleClass: SpatialScaleClass
    public let persistence: SpatialPersistence

    public init(
        placement: SpatialPlacementMode,
        distanceBand: SpatialDistanceBand,
        bearing: SpatialBearingIntent,
        scaleClass: SpatialScaleClass,
        persistence: SpatialPersistence
    ) {
        self.placement = placement
        self.distanceBand = distanceBand
        self.bearing = bearing
        self.scaleClass = scaleClass
        self.persistence = persistence
    }
}
