import Foundation

public enum AudioPlaybackDiagnosticKind: String, Codable, Equatable, Sendable {
    case cueReceived
    case plannerAccepted
    case plannerSuppressed
    case assetLookupStarted
    case assetResolved
    case assetMissing
    case audioSessionConfigurationStarted
    case audioSessionConfigured
    case audioSessionConfigurationFailed
    case playerInitialized
    case playerInitializationFailed
    case playbackRequested
    case playRequestAccepted
    case playbackDidNotStart
    case playerObservedActive
    case playbackFinished
    case playbackDecodeError
    case playbackInterrupted
    case playbackInterruptionEnded
    case routeChanged
    case playbackSuspended
    case playbackResumed
    case playbackStopRequested
    case playbackFadeRequested
    case playbackStopped
}

public enum AudioPlaybackReasonCode: String, Codable, Equatable, Sendable {
    case duplicateCue
    case lowerPriority
    case sessionPaused
    case sessionEnded
    case unsupportedCue
    case failedAssetCached
    case missingAsset
    case invalidAsset
    case audioSessionConfigurationFailed
    case playerInitializationFailed
    case playReturnedFalse
    case decodeError
    case interruption
}

public enum AudioDiagnosticChannel: String, Codable, Equatable, Sendable {
    case foreground
    case ambient
}

public enum AudioOutputRouteCategory: String, Codable, Equatable, Sendable {
    case builtInSpeaker
    case receiver
    case wiredHeadphones
    case bluetooth
    case airPlay
    case hdmi
    case usb
    case other
    case none
    case unknown
}

public enum AudioRouteChangeReasonCode: String, Codable, Equatable, Sendable {
    case newDeviceAvailable
    case oldDeviceUnavailable
    case categoryChange
    case override
    case wakeFromSleep
    case noSuitableRoute
    case routeConfigurationChange
    case unknown
}

public enum AudioInterruptionResumeDisposition: String, Codable, Equatable, Sendable {
    case shouldResume
    case shouldNotResume
    case unknown
}

public enum AudioSessionPolicyIdentifier: String, Codable, Equatable, Sendable {
    case ambientMixWithOthers
}

public struct AudioPlaybackDiagnostic: Codable, Equatable, Sendable {
    public var timestamp: Date
    public var kind: AudioPlaybackDiagnosticKind
    public var cueKind: AudioCueKind?
    public var channel: AudioDiagnosticChannel?
    public var priority: Int?
    public var reasonCode: AudioPlaybackReasonCode?
    public var routeCategory: AudioOutputRouteCategory?
    public var routeChangeReason: AudioRouteChangeReasonCode?
    public var interruptionResumeDisposition: AudioInterruptionResumeDisposition?
    public var sessionPolicy: AudioSessionPolicyIdentifier?

    public init(
        timestamp: Date,
        kind: AudioPlaybackDiagnosticKind,
        cueKind: AudioCueKind? = nil,
        channel: AudioDiagnosticChannel? = nil,
        priority: Int? = nil,
        reasonCode: AudioPlaybackReasonCode? = nil,
        routeCategory: AudioOutputRouteCategory? = nil,
        routeChangeReason: AudioRouteChangeReasonCode? = nil,
        interruptionResumeDisposition: AudioInterruptionResumeDisposition? = nil,
        sessionPolicy: AudioSessionPolicyIdentifier? = nil
    ) {
        self.timestamp = timestamp
        self.kind = kind
        self.cueKind = cueKind
        self.channel = channel
        self.priority = priority
        self.reasonCode = reasonCode
        self.routeCategory = routeCategory
        self.routeChangeReason = routeChangeReason
        self.interruptionResumeDisposition = interruptionResumeDisposition
        self.sessionPolicy = sessionPolicy
    }
}
