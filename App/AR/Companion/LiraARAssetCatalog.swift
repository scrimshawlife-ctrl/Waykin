import Foundation

/// Catalog for optional artist-authored AR assets (USDZ / RealityKit).
///
/// Runtime default remains the procedural Living Familiar mid-LOD from
/// `CompanionEntityFactory`. Drop a sculpted `Lira_AR_Base.usdz` under
/// `App/Resources/Companion/Lira/` when production mesh is ready; wire
/// async load in a follow-up that preserves A1–A3 node names.
enum LiraARAssetCatalog {
    static let baseUSDZName = "Lira_AR_Base"
    static let resourceSubdirectory = "Companion/Lira"

    /// Bundle URL for artist USDZ if present in the app package.
    static var baseUSDZURL: URL? {
        Bundle.main.url(
            forResource: baseUSDZName,
            withExtension: "usdz",
            subdirectory: resourceSubdirectory
        ) ?? Bundle.main.url(forResource: baseUSDZName, withExtension: "usdz")
    }

    /// Whether a production USDZ is packaged (not yet required for MVP).
    static var hasPackagedUSDZ: Bool { baseUSDZURL != nil }

    /// LOD ladder note for docs / diagnostics.
    static var activeARLODDescription: String {
        if hasPackagedUSDZ {
            "artist_usdz:\(baseUSDZName)"
        } else {
            "procedural_living_familiar_mid"
        }
    }
}
