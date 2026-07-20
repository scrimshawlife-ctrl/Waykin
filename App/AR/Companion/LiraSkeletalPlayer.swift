import Foundation
import RealityKit

/// Installs and plays joint-hierarchy skeletal clips on a Lira companion entity.
///
/// When active, ambient joint motion is owned by RealityKit playback; the
/// renderer should skip pure-function channels on animated joints (hunter echo
/// and spawn scale remain procedural).
///
/// Uses direct `playAnimation` (iOS 17+) rather than `AnimationLibraryComponent`
/// (iOS 18+) so deployment target 17 remains green.
@MainActor
final class LiraSkeletalPlayer {
    private(set) var isInstalled = false
    private(set) var isDriving = false
    private(set) var activeClip: LiraSkeletalAnimationLibrary.ClipID?
    private var library: [LiraSkeletalAnimationLibrary.ClipID: AnimationResource] = [:]
    private var playbackController: AnimationPlaybackController?

    /// Transition blend between ambient clips (seconds).
    var transitionDuration: TimeInterval = 0.22

    /// Build clip table when entity has skeletal joints.
    @discardableResult
    func install(on entity: Entity) -> Bool {
        stop()
        guard LiraSkeletalRig.hasSkeletalJoints(entity) else {
            isInstalled = false
            isDriving = false
            activeClip = nil
            library = [:]
            return false
        }
        do {
            library = try LiraSkeletalAnimationLibrary.makeLibrary()
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
        } catch {
            isInstalled = false
            isDriving = false
            activeClip = nil
            library = [:]
            return false
        }
    }

    /// Play ambient (or one-shot) clip for presentation state.
    func play(state: CompanionPresentationState, on entity: Entity) {
        guard isInstalled else { return }
        let clip = LiraSkeletalAnimationLibrary.clip(for: state)
        play(clip: clip, on: entity)
    }

    /// Play an explicit clip id (e.g. spawn on place).
    func play(clip: LiraSkeletalAnimationLibrary.ClipID, on entity: Entity) {
        guard isInstalled, let resource = library[clip] else { return }
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
