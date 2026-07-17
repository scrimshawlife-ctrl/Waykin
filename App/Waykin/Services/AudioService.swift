import Foundation
import AVFoundation
import UIKit
import WaykinCore

/// Maps AudioCue events to sound. The MPOC uses system sounds + haptics so it
/// ships with zero bundled assets; swap in real audio files later.
final class AudioService {
    static let shared = AudioService()

    private var lastHeartbeat = Date.distantPast

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func play(_ cue: AudioCue) {
        switch cue {
        case .ambient:
            break // ambience is silence for now
        case .heartbeatSlow:
            heartbeat(minInterval: 2.0, style: .light)
        case .heartbeatFast:
            heartbeat(minInterval: 0.8, style: .heavy)
        case .chime:
            AudioServicesPlaySystemSound(1057)
        case .victory:
            AudioServicesPlaySystemSound(1025)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .ghostWhoosh:
            AudioServicesPlaySystemSound(1050)
        }
    }

    private func heartbeat(minInterval: TimeInterval, style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard Date().timeIntervalSince(lastHeartbeat) >= minInterval else { return }
        lastHeartbeat = Date()
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
