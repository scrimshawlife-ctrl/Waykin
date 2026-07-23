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
    /// Per-state DCC clip USDZs (sidecar packages from the Blender export pipeline).
    static let clipsSubdirectory = "Companion/Lira/Clips"
    /// Filenames without extension, matching `author_lira_armature_clips` / export.
    static let dccClipBaseNames: [String] = [
        "Lira_Idle",
        "Lira_Follow",
        "Lira_Investigate",
        "Lira_Alert",
        "Lira_Celebrate",
        "Lira_Spawn",
    ]

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

    /// Bundle URL for a single DCC clip sidecar USDZ, if packaged.
    static func dccClipUSDZURL(baseName: String) -> URL? {
        Bundle.main.url(
            forResource: baseName,
            withExtension: "usdz",
            subdirectory: clipsSubdirectory
        )
            ?? Bundle.main.url(
                forResource: baseName,
                withExtension: "usdz",
                subdirectory: "Companion/Lira/Clips"
            )
            ?? Bundle.main.url(forResource: baseName, withExtension: "usdz")
    }

    /// All packaged DCC clip sidecar URLs (name → url). Missing files are omitted.
    static var dccClipUSDZURLs: [(baseName: String, url: URL)] {
        dccClipBaseNames.compactMap { name in
            guard let url = dccClipUSDZURL(baseName: name) else { return nil }
            return (name, url)
        }
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
