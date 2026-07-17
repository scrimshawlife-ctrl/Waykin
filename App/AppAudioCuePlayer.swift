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
    private static let descriptors: [AudioCueKind: AudioAssetDescriptor] = [
        .companionNear: .init(kind: .companionNear, assetName: "companion_near", fileExtension: "wav", priority: 2, channel: .foreground, volume: 0.20),
        .companionAhead: .init(kind: .companionAhead, assetName: "companion_ahead", fileExtension: "wav", priority: 2, channel: .foreground, volume: 0.20),
        .distantFootsteps: .init(kind: .distantFootsteps, assetName: "distant_presence", fileExtension: "wav", priority: 3, channel: .foreground, volume: 0.18),
        .pursuitPressure: .init(kind: .pursuitPressure, assetName: "pursuit_pressure", fileExtension: "wav", priority: 4, channel: .foreground, volume: 0.24),
        .pursuitRelease: .init(kind: .pursuitRelease, assetName: "pursuit_release", fileExtension: "wav", priority: 3, channel: .foreground, volume: 0.18),
        .bondMotif: .init(kind: .bondMotif, assetName: "bond_motif", fileExtension: "wav", priority: 5, channel: .foreground, volume: 0.22),
        .quietShift: .init(kind: .quietShift, assetName: "quiet_shift", fileExtension: "wav", priority: 1, channel: .ambient, volume: 0.14)
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
final class AppAudioCuePlayer: AudioCuePlaying {
    private let audioSession: AVAudioSession
    private let assetLocator: any AudioAssetLocating
    private let diagnostic: @MainActor (String) -> Void
    private var planner = AudioCuePlaybackPlanner()
    private var players: [AudioPlaybackChannel: AVAudioPlayer] = [:]
    private var failedAssetNames: Set<String> = []
    private var playbackGeneration = 0
    private var didReportAudioSessionFailure = false

    init(
        audioSession: AVAudioSession = .sharedInstance(),
        assetLocator: any AudioAssetLocating = BundleAudioAssetLocator(),
        diagnostic: @escaping @MainActor (String) -> Void = AppAudioCuePlayer.defaultDiagnostic
    ) {
        self.audioSession = audioSession
        self.assetLocator = assetLocator
        self.diagnostic = diagnostic
    }

    func handle(_ cues: [AudioCue]) {
        clearFinishedPlayers()
        for cue in cues.sorted(by: { $0.priority > $1.priority }) {
            guard case let .play(descriptor, replacingActiveCue) = planner.decision(for: cue) else {
                continue
            }

            guard !failedAssetNames.contains(descriptor.assetName) else {
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
                continue
            }
            guard let url = assetLocator.url(for: descriptor) else {
                recordAssetFailure(descriptor, reason: "missing")
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
                continue
            }

            do {
                try configureAudioSessionIfNeeded()
            } catch {
                if !didReportAudioSessionFailure {
                    didReportAudioSessionFailure = true
                    diagnostic("Audio session configuration failed; playback remains silent")
                }
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
                continue
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = 0
                player.volume = descriptor.volume * Float(max(0.25, cue.intensity))
                player.pan = pan(for: cue.spatialBias)
                player.prepareToPlay()

                if replacingActiveCue {
                    players[descriptor.channel]?.stop()
                }
                players[descriptor.channel] = player
                playbackGeneration += 1
                player.play()
            } catch {
                recordAssetFailure(descriptor, reason: "invalid")
                planner.removeActiveCue(kind: cue.kind, channel: descriptor.channel)
            }
        }
    }

    func pauseAll() {
        planner.pause()
        players.values.forEach { $0.pause() }
    }

    func resumeAll() {
        planner.resume()
        if !players.isEmpty {
            try? configureAudioSessionIfNeeded()
        }
        players.values.filter { !$0.isPlaying }.forEach { $0.play() }
    }

    func stopAll(fadeOut: Bool) {
        planner.stop()
        playbackGeneration += 1
        let generation = playbackGeneration
        let activePlayers = Array(players.values)
        players.removeAll()

        guard fadeOut else {
            activePlayers.forEach { $0.stop() }
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            return
        }

        activePlayers.forEach { $0.setVolume(0, fadeDuration: 0.25) }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            activePlayers.forEach { $0.stop() }
            guard playbackGeneration == generation else { return }
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func configureAudioSessionIfNeeded() throws {
        try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)
    }

    private func recordAssetFailure(_ descriptor: AudioAssetDescriptor, reason: String) {
        guard failedAssetNames.insert(descriptor.assetName).inserted else { return }
        diagnostic("Audio asset \(reason): \(descriptor.assetName).\(descriptor.fileExtension)")
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

    private static func defaultDiagnostic(_ message: String) {
#if DEBUG
        print("[WaykinAudio] \(message)")
#endif
    }
}
