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
