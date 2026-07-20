import Foundation

/// Low-level 2D HUD transport for glasses displays.
///
/// Isolates third-party Meta DAT (or Mock Device Kit) from the rest of App.
/// Physical device rendering remains NOT_COMPUTABLE without direct evidence.
@MainActor
protocol GlassesHUDTransport: AnyObject {
    var connectionState: GlassesGlanceConnectionState { get }
    func connect() async
    func push(lines: [String])
    func disconnect()
}

/// In-process mock transport (Mock Device Kit stand-in).
/// Fully testable without Meta hardware or partner SDK.
@MainActor
final class MockGlassesHUDTransport: GlassesHUDTransport {
    private(set) var connectionState: GlassesGlanceConnectionState = .idle
    private(set) var connectCount = 0
    private(set) var disconnectCount = 0
    private(set) var pushedLineSets: [[String]] = []
    /// When true, connect fails and state becomes unavailable.
    var failConnect = false

    func connect() async {
        connectCount += 1
        if failConnect {
            connectionState = .unavailable
            return
        }
        connectionState = .connecting
        connectionState = .connected
    }

    func push(lines: [String]) {
        guard connectionState == .connected else { return }
        pushedLineSets.append(lines)
    }

    func disconnect() {
        disconnectCount += 1
        connectionState = .idle
        pushedLineSets.removeAll(keepingCapacity: false)
    }
}

/// Placeholder transport for Meta Wearables Device Access Toolkit.
///
/// Partner SDK integration lands here when the select-partner package is linked.
/// Until then this transport reports `unavailable` so production never claims
/// physical Ray-Ban Display behavior (NOT_COMPUTABLE).
@MainActor
final class MetaWearablesHUDTransport: GlassesHUDTransport {
    private(set) var connectionState: GlassesGlanceConnectionState = .idle
    private let fallback: MockGlassesHUDTransport?
    private(set) var usedMockFallback = false

    /// - Parameter useMockFallbackInLab: when true (DEBUG lab only), routes through mock.
    init(useMockFallbackInLab: Bool = false) {
        self.fallback = useMockFallbackInLab ? MockGlassesHUDTransport() : nil
    }

    func connect() async {
        if let fallback {
            usedMockFallback = true
            await fallback.connect()
            connectionState = fallback.connectionState
            return
        }
        // Real Meta DAT module not linked in this build.
        connectionState = .unavailable
    }

    func push(lines: [String]) {
        if let fallback, usedMockFallback {
            fallback.push(lines: lines)
            return
        }
        // No-op when unavailable — never invent physical HUD output.
    }

    func disconnect() {
        fallback?.disconnect()
        connectionState = .idle
        usedMockFallback = false
    }
}
