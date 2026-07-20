import AVFoundation
import Foundation
import WaykinCore

@MainActor
protocol AudioCuePlaying: AnyObject {
    func handle(_ cues: [AudioCue])
    func pauseAll()
    func resumeAll()
    func stopAll(fadeOut: Bool)
}

enum AudioPlaybackChannel: String, Equatable {
    case foreground
    case ambient
}

struct AudioAssetDescriptor: Equatable {
    let kind: AudioCueKind
    let assetName: String
    let fileExtension: String
    let priority: Int
    let channel: AudioPlaybackChannel
    let volume: Float
}

enum AudioCueAssetCatalog {
    /// Outdoor-aware gain (#130): raised from ~0.14–0.24 so produced cues remain legible on walks.
    /// Not a loudness PASS claim — physical audibility remains device-evidence only.
    private static let descriptors: [AudioCueKind: AudioAssetDescriptor] = [
        .companionNear: .init(kind: .companionNear, assetName: "companion_near", fileExtension: "wav", priority: 2, channel: .foreground, volume: 0.40),
        .companionAhead: .init(kind: .companionAhead, assetName: "companion_ahead", fileExtension: "wav", priority: 2, channel: .foreground, volume: 0.40),
        .distantFootsteps: .init(kind: .distantFootsteps, assetName: "distant_presence", fileExtension: "wav", priority: 3, channel: .foreground, volume: 0.36),
        .pursuitPressure: .init(kind: .pursuitPressure, assetName: "pursuit_pressure", fileExtension: "wav", priority: 4, channel: .foreground, volume: 0.45),
        .pursuitRelease: .init(kind: .pursuitRelease, assetName: "pursuit_release", fileExtension: "wav", priority: 3, channel: .foreground, volume: 0.36),
        .bondMotif: .init(kind: .bondMotif, assetName: "bond_motif", fileExtension: "wav", priority: 5, channel: .foreground, volume: 0.42),
        .quietShift: .init(kind: .quietShift, assetName: "quiet_shift", fileExtension: "wav", priority: 1, channel: .ambient, volume: 0.30)
    ]

    static func descriptor(for kind: AudioCueKind) -> AudioAssetDescriptor? {
        descriptors[kind]
    }

    static func descriptor(forRawValue rawValue: String) -> AudioAssetDescriptor? {
        AudioCueKind(rawValue: rawValue).flatMap(descriptor(for:))
    }
}

struct AudioCuePlaybackPlanner {
    enum Decision: Equatable {
        case play(AudioAssetDescriptor, replacingActiveCue: Bool)
        case ignoreDuplicate
        case ignoreLowerPriority
        case ignoreWhilePaused
        case ignoreUnsupported
    }

    private struct ActiveCue {
        let kind: AudioCueKind
        let priority: Int
    }

    private var activeCues: [AudioPlaybackChannel: ActiveCue] = [:]
    private(set) var isPaused = false

    mutating func decision(for cue: AudioCue) -> Decision {
        guard !isPaused else { return .ignoreWhilePaused }
        guard let descriptor = AudioCueAssetCatalog.descriptor(for: cue.kind) else {
            return .ignoreUnsupported
        }

        let effectivePriority = max(cue.priority, descriptor.priority)
        if let active = activeCues[descriptor.channel] {
            if active.kind == cue.kind {
                return .ignoreDuplicate
            }
            if active.priority > effectivePriority {
                return .ignoreLowerPriority
            }
            activeCues[descriptor.channel] = ActiveCue(kind: cue.kind, priority: effectivePriority)
            return .play(descriptor, replacingActiveCue: true)
        }

        activeCues[descriptor.channel] = ActiveCue(kind: cue.kind, priority: effectivePriority)
        return .play(descriptor, replacingActiveCue: false)
    }

    mutating func removeActiveCue(kind: AudioCueKind, channel: AudioPlaybackChannel) {
        guard activeCues[channel]?.kind == kind else { return }
        activeCues[channel] = nil
    }

    mutating func removeActiveCue(channel: AudioPlaybackChannel) {
        activeCues[channel] = nil
    }

    mutating func pause() { isPaused = true }
    mutating func resume() { isPaused = false }

    mutating func stop() {
        activeCues.removeAll()
        isPaused = false
    }
}

protocol AudioAssetLocating {
    func url(for descriptor: AudioAssetDescriptor) -> URL?
}

struct BundleAudioAssetLocator: AudioAssetLocating {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func url(for descriptor: AudioAssetDescriptor) -> URL? {
        bundle.url(forResource: descriptor.assetName, withExtension: descriptor.fileExtension, subdirectory: "Audio")
            ?? bundle.url(forResource: descriptor.assetName, withExtension: descriptor.fileExtension)
    }
}

@MainActor
protocol AudioSessionControlling: AnyObject {
    var currentRouteCategory: AudioOutputRouteCategory { get }
    func configureAmbientMixing() throws
    func activate() throws
    func deactivate() throws
}

extension AVAudioSession: AudioSessionControlling {
    var currentRouteCategory: AudioOutputRouteCategory {
        guard let port = currentRoute.outputs.first?.portType else {
            return AudioOutputRouteCategory.none
        }
        return audioOutputRouteCategory(for: port)
    }

    func configureAmbientMixing() throws {
        try setCategory(.ambient, mode: .default, options: [.mixWithOthers])
    }

    func activate() throws {
        try setActive(true)
    }

    func deactivate() throws {
        try setActive(false, options: .notifyOthersOnDeactivation)
    }
}

func audioOutputRouteCategory(for port: AVAudioSession.Port) -> AudioOutputRouteCategory {
    switch port {
    case .builtInSpeaker: return AudioOutputRouteCategory.builtInSpeaker
    case .builtInReceiver: return AudioOutputRouteCategory.receiver
    case .headphones, .headsetMic: return AudioOutputRouteCategory.wiredHeadphones
    case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE: return AudioOutputRouteCategory.bluetooth
    case .airPlay: return AudioOutputRouteCategory.airPlay
    case .HDMI: return AudioOutputRouteCategory.hdmi
    case .usbAudio: return AudioOutputRouteCategory.usb
    default: return AudioOutputRouteCategory.other
    }
}

@MainActor
protocol AudioPlayerControlling: AnyObject {
    var isPlaying: Bool { get }
    var numberOfLoops: Int { get set }
    var volume: Float { get set }
    var pan: Float { get set }

    func prepareToPlay()
    func play() -> Bool
    func pause()
    func stop()
    func setVolume(_ volume: Float, fadeDuration: TimeInterval)
    func setPlaybackCallbacks(
        onFinished: @escaping @MainActor (Bool) -> Void,
        onDecodeError: @escaping @MainActor () -> Void
    )
}

@MainActor
private final class SystemAudioPlayer: NSObject, AudioPlayerControlling, AVAudioPlayerDelegate {
    private let player: AVAudioPlayer
    private var onPlaybackFinished: (@MainActor (Bool) -> Void)?
    private var onPlaybackDecodeError: (@MainActor () -> Void)?

    init(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        super.init()
        player.delegate = self
    }

    var isPlaying: Bool { player.isPlaying }
    var numberOfLoops: Int {
        get { player.numberOfLoops }
        set { player.numberOfLoops = newValue }
    }
    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }
    var pan: Float {
        get { player.pan }
        set { player.pan = newValue }
    }

    func prepareToPlay() { player.prepareToPlay() }
    func play() -> Bool { player.play() }
    func pause() { player.pause() }
    func stop() { player.stop() }
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {
        player.setVolume(volume, fadeDuration: fadeDuration)
    }

    func setPlaybackCallbacks(
        onFinished: @escaping @MainActor (Bool) -> Void,
        onDecodeError: @escaping @MainActor () -> Void
    ) {
        onPlaybackFinished = onFinished
        onPlaybackDecodeError = onDecodeError
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.onPlaybackFinished?(flag)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.onPlaybackDecodeError?()
        }
    }
}

@MainActor
protocol AudioPlayerMaking {
    func makePlayer(contentsOf url: URL) throws -> any AudioPlayerControlling
}

@MainActor
private struct SystemAudioPlayerFactory: AudioPlayerMaking {
    func makePlayer(contentsOf url: URL) throws -> any AudioPlayerControlling {
        try SystemAudioPlayer(url: url)
    }
}

@MainActor
final class AppAudioCuePlayer: AudioCuePlaying {
    private let audioSession: any AudioSessionControlling
    private let assetLocator: any AudioAssetLocating
    private let playerFactory: any AudioPlayerMaking
    private let notificationCenter: NotificationCenter
    private var diagnostic: @MainActor (AudioPlaybackDiagnostic) -> Void
    private var notificationTokens: [NSObjectProtocol] = []
    private var planner = AudioCuePlaybackPlanner()
    private var players: [AudioPlaybackChannel: any AudioPlayerControlling] = [:]
    private var failedAssetNames: Set<String> = []
    private var playbackGeneration = 0

    init(
        audioSession: AVAudioSession = .sharedInstance(),
        assetLocator: any AudioAssetLocating = BundleAudioAssetLocator(),
        diagnostic: @escaping @MainActor (AudioPlaybackDiagnostic) -> Void = AppAudioCuePlayer.defaultDiagnostic,
        notificationCenter: NotificationCenter = .default
    ) {
        self.audioSession = audioSession
        self.assetLocator = assetLocator
        playerFactory = SystemAudioPlayerFactory()
        self.diagnostic = diagnostic
        self.notificationCenter = notificationCenter
        installNotificationObservers()
    }

    init(
        audioSession: any AudioSessionControlling,
        assetLocator: any AudioAssetLocating,
        playerFactory: any AudioPlayerMaking,
        diagnostic: @escaping @MainActor (AudioPlaybackDiagnostic) -> Void,
        notificationCenter: NotificationCenter = .default
    ) {
        self.audioSession = audioSession
        self.assetLocator = assetLocator
        self.playerFactory = playerFactory
        self.diagnostic = diagnostic
        self.notificationCenter = notificationCenter
        installNotificationObservers()
    }

    deinit {
        notificationTokens.forEach(notificationCenter.removeObserver)
    }

    func setDiagnosticHandler(_ handler: @escaping @MainActor (AudioPlaybackDiagnostic) -> Void) {
        diagnostic = handler
    }

    func handle(_ cues: [AudioCue]) {
        clearFinishedPlayers()
        for cue in cues.sorted(by: { $0.priority > $1.priority }) {
            emit(.cueReceived, cue: cue)
            let decision = planner.decision(for: cue)
            guard case let .play(descriptor, replacingActiveCue) = decision else {
                emitPlannerSuppression(for: cue, decision: decision)
                continue
            }
            emit(.plannerAccepted, cue: cue, descriptor: descriptor)

            guard !failedAssetNames.contains(descriptor.assetName) else {
                emit(.plannerSuppressed, cue: cue, descriptor: descriptor, reason: .failedAssetCached)
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
                continue
            }
            emit(.assetLookupStarted, cue: cue, descriptor: descriptor)
            guard let url = assetLocator.url(for: descriptor) else {
                emit(.assetMissing, cue: cue, descriptor: descriptor, reason: .missingAsset)
                recordAssetFailure(descriptor)
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
                continue
            }
            emit(.assetResolved, cue: cue, descriptor: descriptor)

            do {
                try configureAudioSessionIfNeeded()
            } catch {
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
                continue
            }

            do {
                let player = try playerFactory.makePlayer(contentsOf: url)
                emit(.playerInitialized, cue: cue, descriptor: descriptor)
                player.numberOfLoops = 0
                player.volume = descriptor.volume * Float(max(0.25, cue.intensity))
                player.pan = pan(for: cue.spatialBias)
                player.prepareToPlay()
                player.setPlaybackCallbacks(
                    onFinished: { [weak self] successfully in
                        guard let self else { return }
                        self.emit(successfully ? .playbackFinished : .playbackDecodeError, cue: cue, descriptor: descriptor, reason: successfully ? nil : .decodeError)
                    },
                    onDecodeError: { [weak self] in
                        self?.emit(.playbackDecodeError, cue: cue, descriptor: descriptor, reason: .decodeError)
                    }
                )

                if replacingActiveCue {
                    players[descriptor.channel]?.stop()
                }
                players[descriptor.channel] = player
                playbackGeneration += 1
                emit(.playbackRequested, cue: cue, descriptor: descriptor)
                if player.play() {
                    emit(.playRequestAccepted, cue: cue, descriptor: descriptor)
                    emit(player.isPlaying ? .playerObservedActive : .playbackDidNotStart, cue: cue, descriptor: descriptor)
                } else {
                    emit(.playbackDidNotStart, cue: cue, descriptor: descriptor, reason: .playReturnedFalse)
                }
            } catch {
                emit(.playerInitializationFailed, cue: cue, descriptor: descriptor, reason: .playerInitializationFailed)
                recordAssetFailure(descriptor)
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
            }
        }
    }

    func pauseAll() {
        planner.pause()
        let activePlayers = Array(players.values)
        activePlayers.forEach { $0.pause() }
        if !activePlayers.isEmpty && activePlayers.allSatisfy({ !$0.isPlaying }) {
            emit(.playbackSuspended)
        }
    }

    func resumeAll() {
        planner.resume()
        guard !players.isEmpty else { return }
        try? configureAudioSessionIfNeeded()

        var observedActivePlayer = false
        players.values.filter { !$0.isPlaying }.forEach { player in
            let accepted = player.play()
            emit(accepted ? .playRequestAccepted : .playbackDidNotStart, reason: accepted ? nil : .playReturnedFalse)
            if player.isPlaying {
                observedActivePlayer = true
            }
        }
        if observedActivePlayer {
            emit(.playbackResumed)
        }
    }

    func stopAll(fadeOut: Bool) {
        planner.stop()
        playbackGeneration += 1
        let generation = playbackGeneration
        let activePlayers = Array(players.values)
        players.removeAll()

        guard fadeOut else {
            emit(.playbackStopRequested)
            activePlayers.forEach { $0.stop() }
            if !activePlayers.isEmpty && activePlayers.allSatisfy({ !$0.isPlaying }) {
                emit(.playbackStopped)
            }
            try? audioSession.deactivate()
            return
        }

        emit(.playbackFadeRequested)
        emit(.playbackStopRequested)
        activePlayers.forEach { $0.setVolume(0, fadeDuration: 0.25) }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            activePlayers.forEach { $0.stop() }
            if !activePlayers.isEmpty && activePlayers.allSatisfy({ !$0.isPlaying }) {
                emit(.playbackStopped)
            }
            guard playbackGeneration == generation else { return }
            try? audioSession.deactivate()
        }
    }

    private func configureAudioSessionIfNeeded() throws {
        emit(
            .audioSessionConfigurationStarted,
            routeCategory: audioSession.currentRouteCategory,
            sessionPolicy: .ambientMixWithOthers
        )
        do {
            try audioSession.configureAmbientMixing()
            try audioSession.activate()
        } catch {
            emit(
                .audioSessionConfigurationFailed,
                reason: .audioSessionConfigurationFailed,
                routeCategory: audioSession.currentRouteCategory,
                sessionPolicy: .ambientMixWithOthers
            )
            throw error
        }
        emit(
            .audioSessionConfigured,
            routeCategory: audioSession.currentRouteCategory,
            sessionPolicy: .ambientMixWithOthers
        )
    }

    private func installNotificationObservers() {
        notificationTokens.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor [weak self] in
                    self?.handleInterruption(notification)
                }
            }
        )
        notificationTokens.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor [weak self] in
                    self?.handleRouteChange(notification)
                }
            }
        )
    }

    private func handleInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }

        switch type {
        case .began:
            emit(.playbackInterrupted, reason: .interruption)
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            emit(
                .playbackInterruptionEnded,
                interruptionResumeDisposition: options.contains(.shouldResume) ? .shouldResume : .shouldNotResume
            )
        @unknown default:
            emit(.playbackInterrupted, reason: .interruption)
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0
        emit(
            .routeChanged,
            routeCategory: audioSession.currentRouteCategory,
            routeChangeReason: audioRouteChangeReason(for: AVAudioSession.RouteChangeReason(rawValue: rawReason) ?? .unknown)
        )
    }

    private func recordAssetFailure(_ descriptor: AudioAssetDescriptor) {
        guard failedAssetNames.insert(descriptor.assetName).inserted else { return }
    }

    private func clearFinishedPlayers() {
        guard !planner.isPaused else { return }
        let finishedChannels = players.compactMap { channel, player in
            player.isPlaying ? nil : channel
        }
        for channel in finishedChannels {
            players[channel] = nil
            planner.removeActiveCue(channel: channel)
        }
    }

    private func pan(for bias: AudioSpatialBias?) -> Float {
        switch bias {
        case .left: -0.2
        case .right: 0.2
        case .center, .behind, nil: 0
        }
    }

    private func emit(
        _ kind: AudioPlaybackDiagnosticKind,
        cue: AudioCue? = nil,
        descriptor: AudioAssetDescriptor? = nil,
        reason: AudioPlaybackReasonCode? = nil,
        routeCategory: AudioOutputRouteCategory? = nil,
        sessionPolicy: AudioSessionPolicyIdentifier? = nil,
        routeChangeReason: AudioRouteChangeReasonCode? = nil,
        interruptionResumeDisposition: AudioInterruptionResumeDisposition? = nil
    ) {
        diagnostic(AudioPlaybackDiagnostic(
            timestamp: Date(),
            kind: kind,
            cueKind: cue?.kind,
            channel: descriptor.map(diagnosticChannel(for:)),
            priority: descriptor?.priority,
            reasonCode: reason,
            routeCategory: routeCategory,
            routeChangeReason: routeChangeReason,
            interruptionResumeDisposition: interruptionResumeDisposition,
            sessionPolicy: sessionPolicy
        ))
    }

    private func emitPlannerSuppression(for cue: AudioCue, decision: AudioCuePlaybackPlanner.Decision) {
        let reason: AudioPlaybackReasonCode
        switch decision {
        case .ignoreDuplicate: reason = .duplicateCue
        case .ignoreLowerPriority: reason = .lowerPriority
        case .ignoreWhilePaused: reason = .sessionPaused
        case .ignoreUnsupported: reason = .unsupportedCue
        case .play: return
        }
        emit(.plannerSuppressed, cue: cue, reason: reason)
    }

    private func diagnosticChannel(for descriptor: AudioAssetDescriptor) -> AudioDiagnosticChannel {
        switch descriptor.channel {
        case .foreground: .foreground
        case .ambient: .ambient
        }
    }

    private func audioRouteChangeReason(for reason: AVAudioSession.RouteChangeReason) -> AudioRouteChangeReasonCode {
        switch reason {
        case .newDeviceAvailable: return .newDeviceAvailable
        case .oldDeviceUnavailable: return .oldDeviceUnavailable
        case .categoryChange: return .categoryChange
        case .override: return .override
        case .wakeFromSleep: return .wakeFromSleep
        case .noSuitableRouteForCategory: return .noSuitableRoute
        case .routeConfigurationChange: return .routeConfigurationChange
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }

    private static func defaultDiagnostic(_ diagnostic: AudioPlaybackDiagnostic) {
#if DEBUG
        print("[WaykinAudio] \(diagnostic.kind.rawValue)")
#endif
    }
}
