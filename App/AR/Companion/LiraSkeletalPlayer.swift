import Foundation
import RealityKit

/// Installs and plays joint-hierarchy skeletal clips on a Lira companion entity.
///
/// **Sources (priority):**
/// 1. **DCC** — `entity.availableAnimations` from packaged USDZ (Blender actions
///    `Lira_Idle` / `Lira_Follow` / …) when names map cleanly.
/// 2. **Puppet** — runtime-generated `LiraSkeletalAnimationLibrary` bound to
///    semantic entity names (permanent fallback).
///
/// When active, ambient joint motion is owned by RealityKit playback; the
/// renderer should skip pure-function channels on animated joints (hunter echo
/// and spawn scale remain procedural).
///
/// Uses direct `playAnimation` (iOS 17+) rather than `AnimationLibraryComponent`
/// (iOS 18+) so deployment target 17 remains green.
@MainActor
final class LiraSkeletalPlayer {
    enum ClipSource: String, Sendable {
        /// Full DCC set from USDZ availableAnimations.
        case dcc
        /// Runtime-generated entity-name puppet clips only.
        case puppet
        /// Some DCC clips overlaid on puppet fill.
        case hybrid
        case none
    }

    private(set) var isInstalled = false
    private(set) var isDriving = false
    private(set) var activeClip: LiraSkeletalAnimationLibrary.ClipID?
    private(set) var clipSource: ClipSource = .none
    private var library: [LiraSkeletalAnimationLibrary.ClipID: AnimationResource] = [:]
    private var playbackController: AnimationPlaybackController?

    /// Transition blend between ambient clips (seconds).
    var transitionDuration: TimeInterval = 0.22

    /// Build clip table when entity has skeletal joints.
    /// Prefers DCC clips from the USDZ when available; else puppet library.
    @discardableResult
    func install(on entity: Entity) -> Bool {
        stop()
        guard LiraSkeletalRig.hasSkeletalJoints(entity) else {
            isInstalled = false
            isDriving = false
            activeClip = nil
            clipSource = .none
            library = [:]
            return false
        }

        // Always build puppet library as base; overlay any DCC animations found on the entity.
        let puppet: [LiraSkeletalAnimationLibrary.ClipID: AnimationResource]
        do {
            puppet = try LiraSkeletalAnimationLibrary.makeLibrary()
        } catch {
            isInstalled = false
            isDriving = false
            activeClip = nil
            clipSource = .none
            library = [:]
            return false
        }
        let dcc = Self.mapDCCAnimations(from: entity)
        var merged = puppet
        for (id, resource) in dcc {
            merged[id] = resource
        }
        library = merged
        if dcc.isEmpty {
            clipSource = .puppet
        } else if dcc.count >= 3 {
            clipSource = .dcc
        } else {
            // Partial DCC (often only active action exports) + puppet fill.
            clipSource = .hybrid
        }

        // iOS 18+: also publish on entity for tooling / availableAnimations.
        if #available(iOS 18.0, *) {
            var component = AnimationLibraryComponent()
            for (id, resource) in library {
                component.animations[id.rawValue] = resource
            }
            entity.components.set(component)
        }
        isInstalled = true
        isDriving = true
        return true
    }

    /// Map RealityKit-available USD animations to clip IDs by name heuristics.
    static func mapDCCAnimations(from entity: Entity) -> [LiraSkeletalAnimationLibrary.ClipID: AnimationResource] {
        var result: [LiraSkeletalAnimationLibrary.ClipID: AnimationResource] = [:]
        for anim in entity.availableAnimations {
            let raw = anim.name ?? ""
            let key = raw.lowercased()
            let id: LiraSkeletalAnimationLibrary.ClipID?
            if key.contains("idle") {
                id = .idle
            } else if key.contains("follow") {
                id = .follow
            } else if key.contains("investigate") {
                id = .investigate
            } else if key.contains("alert") {
                id = .alert
            } else if key.contains("celebrate") {
                id = .celebrate
            } else if key.contains("spawn") {
                id = .spawn
            } else {
                id = nil
            }
            guard let id else { continue }
            // Prefer first match; Blender may emit duplicates.
            if result[id] == nil {
                result[id] = anim
            }
        }
        return result
    }

    /// Human-readable install source for chrome / tests.
    var sourceDescription: String {
        "\(clipSource.rawValue):\(library.count)_clips"
    }

    /// Play ambient (or one-shot) clip for presentation state.
    func play(state: CompanionPresentationState, on entity: Entity) {
        guard isInstalled else { return }
        let clip = LiraSkeletalAnimationLibrary.clip(for: state)
        play(clip: clip, on: entity)
    }

    /// Play an explicit clip id (e.g. spawn on place).
    func play(clip: LiraSkeletalAnimationLibrary.ClipID, on entity: Entity) {
        guard isInstalled else { return }
        // Prefer exact clip; fall back to idle / follow if DCC library is partial.
        let resource = library[clip]
            ?? library[.idle]
            ?? library[.follow]
            ?? library.values.first
        guard let resource else { return }
        if activeClip == clip, clip.isLooping {
            return
        }
        stopPlaybackOnly()
        let toPlay: AnimationResource
        if clip.isLooping {
            toPlay = resource.repeat()
        } else {
            toPlay = resource
        }
        playbackController = entity.playAnimation(
            toPlay,
            transitionDuration: max(0, transitionDuration),
            startsPaused: false
        )
        activeClip = clip
        isDriving = true
    }

    /// Stop playback but keep library installed.
    func stop() {
        stopPlaybackOnly()
        activeClip = nil
    }

    /// Full clear (session end).
    func clear() {
        stop()
        library = [:]
        isInstalled = false
        isDriving = false
        clipSource = .none
    }

    /// Disable driving without removing library (falls back to pure-function motion).
    func setDriving(_ enabled: Bool) {
        if !enabled {
            stop()
        }
        isDriving = enabled && isInstalled
    }

    private func stopPlaybackOnly() {
        playbackController?.stop()
        playbackController = nil
    }
}
