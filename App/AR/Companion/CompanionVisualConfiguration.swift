import simd

struct CompanionVisualConfiguration: Equatable, Sendable {
    let companionHeightMeters: Float
    let groundOffsetMeters: Float
    let glowIntensity: Float

    init(
        companionHeightMeters: Float = 0.72,
        groundOffsetMeters: Float = 0.02,
        glowIntensity: Float = 1.0
    ) {
        self.companionHeightMeters = companionHeightMeters.isFinite
            ? min(max(companionHeightMeters, 0.25), 1.5)
            : 0.72
        self.groundOffsetMeters = groundOffsetMeters.isFinite
            ? min(max(groundOffsetMeters, 0), 0.2)
            : 0.02
        self.glowIntensity = glowIntensity.isFinite
            ? min(max(glowIntensity, 0), 3)
            : 1
    }

    static let liraPlaceholder = CompanionVisualConfiguration()
}
