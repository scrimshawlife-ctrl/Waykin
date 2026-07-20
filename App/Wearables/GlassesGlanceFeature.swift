import Foundation

/// Feature flag for the glasses glance presentation surface.
///
/// **Default off** — zero behavior change until explicitly enabled via
/// UserDefaults or process argument (tests / lab).
enum GlassesGlanceFeature {
    static let defaultsKey = "waykin.wearables.glassesGlance.enabled"
    static let processArgument = "-WAYKIN_GLASSES_GLANCE"

    /// Process argument overrides UserDefaults. Missing/false → disabled.
    static var isEnabled: Bool {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: processArgument), idx + 1 < args.count {
            let val = args[idx + 1].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            return val == "YES" || val == "TRUE" || val == "1" || val == "ON"
        }
        if args.contains(processArgument) {
            // Bare flag without value counts as enabled for lab convenience.
            return true
        }
        return UserDefaults.standard.bool(forKey: defaultsKey)
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: defaultsKey)
    }
}
