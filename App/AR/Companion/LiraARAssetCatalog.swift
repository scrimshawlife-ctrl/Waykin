import Foundation

/// Catalog for optional artist-authored AR assets (USDZ / RealityKit).
///
/// Runtime default remains procedural Living Familiar mid-LOD.
/// Drop sculpted `Lira_AR_Base.usdz` under `App/Resources/Companion/Lira/`;
/// `LiraARAssetLoader.preloadFromBundle()` validates A1–A3 hierarchy and
/// falls back to procedural if missing or invalid.
enum LiraARAssetCatalog {
    static let baseUSDZName = "Lira_AR_Base"
    static let resourceSubdirectory = "Companion/Lira"

    /// Bundle URL for artist USDZ if present in the app package.
    static var baseUSDZURL: URL? {
        // Prefer nested path, then bundle root (xcodegen packages root Resources reliably).
        Bundle.main.url(
            forResource: baseUSDZName,
            withExtension: "usdz",
            subdirectory: resourceSubdirectory
        )
            ?? Bundle.main.url(forResource: baseUSDZName, withExtension: "usdz")
            ?? Bundle.main.url(
                forResource: baseUSDZName,
                withExtension: "usdz",
                subdirectory: "Companion/Lira"
            )
    }

    /// Whether a production USDZ file is packaged (load may still fail validation).
    static var hasPackagedUSDZ: Bool { baseUSDZURL != nil }

    /// Package presence only — prefer `LiraARAssetLoader.activeLODDescription` at runtime.
    /// Current package: **ARTIST_BLEND_HERO_DCC_MID_LOD** (artist multi-part mid-LOD armature + hero paint + DCC clips).
    /// Fallback generator remains GENERATED_MID_LOD.
    static var packagedLODHint: String {
        if hasPackagedUSDZ {
            "packaged_usdz:\(baseUSDZName):ARTIST_BLEND_HERO_DCC_MID_LOD"
        } else {
            "procedural_living_familiar_mid"
        }
    }

    /// Explicit evidence class for packaged AR asset.
    static let packagedEvidenceClass = "ARTIST_BLEND_HERO_DCC_MID_LOD"
}
