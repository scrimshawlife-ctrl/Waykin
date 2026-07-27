import RealityKit
import UIKit

@MainActor
struct CompanionEntityFactory {
    static let rootName = "LiraRoot"

    private let staticAssetName: String
    private let walkingAssetName: String

    init(
        staticAssetName: String = "Lira",
        walkingAssetName: String = "Lira_Walking"
    ) {
        self.staticAssetName = staticAssetName
        self.walkingAssetName = walkingAssetName
    }

    /// Asynchronously loads the Lira USDZ static mesh, applies configuration height and ground offset once.
    /// Returns nil for missing/malformed assets (caller defers rendering safely).
    func makeLira(configuration: CompanionVisualConfiguration = .liraPlaceholder) async -> Entity? {
        guard let url = Bundle.main.url(forResource: staticAssetName, withExtension: "usdz") else {
            return nil
        }

        do {
            let root = try await Entity.load(contentsOf: url)
            root.name = Self.rootName

            // Apply CompanionVisualConfiguration height and ground offset *once* after loading the imported mesh.
            // Reference height chosen to approximate prior placeholder scaling behavior for visual consistency.
            let referenceHeight: Float = 0.72
            let scaleFactor = configuration.companionHeightMeters / referenceHeight
            if scaleFactor.isFinite && scaleFactor > 0 {
                root.scale = SIMD3<Float>(repeating: scaleFactor)
            }
            // Ground offset applied to root position (state presentations supply only bounded deltas).
            if configuration.groundOffsetMeters.isFinite {
                root.position.y = configuration.groundOffsetMeters
            }

            return root
        } catch {
            // Malformed asset: defer safely, do not mutate gameplay.
            return nil
        }
    }

    /// Loads the walking animation clip from its dedicated USDZ. Returns nil if asset or clip unavailable.
    /// Caller decides whether to defer based on use case.
    func loadWalkingAnimation() async -> AnimationResource? {
        guard let url = Bundle.main.url(forResource: walkingAssetName, withExtension: "usdz") else {
            return nil
        }

        do {
            let animSource = try await Entity.load(contentsOf: url)
            guard let firstClip = animSource.availableAnimations.first else {
                return nil
            }
            // Return a repeating version; playback site controls start/stop.
            return firstClip.repeat()
        } catch {
            return nil
        }
    }
}
