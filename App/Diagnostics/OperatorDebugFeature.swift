import Foundation

/// Live operator strip + expanded diagnostics (D3).
/// Enabled in DEBUG builds, or when launched with `-WAYKIN_OPERATOR_DEBUG`
/// / `-WAYKIN_UI_TESTING` so Release field builds can opt in without permanent chrome.
enum OperatorDebugFeature {
    static let processArgument = "-WAYKIN_OPERATOR_DEBUG"

    static var isEnabled: Bool {
        #if DEBUG
        return true
        #else
        let args = ProcessInfo.processInfo.arguments
        return args.contains(processArgument)
            || args.contains("-WAYKIN_UI_TESTING")
        #endif
    }
}

/// Gates the in-session AR diagnostics HUD (the capability / Lira / LOD / mesh /
/// motion / continuity text strip drawn over the live camera).
///
/// Hidden by default — including in DEBUG sideload builds — so a real field session
/// shows only the camera and the real controls (close / pause / end). Unlike
/// ``OperatorDebugFeature`` this is *not* on-by-default under DEBUG, because the
/// developer-facing HUD reads as unusable "gobbledygook" over the camera in normal use.
///
/// Opt in with `-WAYKIN_OPERATOR_DEBUG`. It is always enabled under
/// `-WAYKIN_UI_TESTING` so UI tests can still read `waykin.ar.canonical.*` identifiers.
enum ARDiagnosticsHUDFeature {
    static var isEnabled: Bool {
        // Follows the operator strip: on in DEBUG / sideloaded dev builds where the AR
        // path is actively being diagnosed, off in Release so field users never see it.
        // (Scheme launch arguments proved unreliable — Xcode caches the scheme.)
        OperatorDebugFeature.isEnabled
    }
}
