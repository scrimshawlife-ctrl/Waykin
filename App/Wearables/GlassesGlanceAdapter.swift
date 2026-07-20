import Foundation

/// App-layer glasses glance adapter. Never imported by WaykinCore.
///
/// Consumes presentation snapshots only; does not invent gameplay state.
@MainActor
protocol GlassesGlanceAdapter: AnyObject {
    var isEnabled: Bool { get }
    var connectionState: GlassesGlanceConnectionState { get }
    /// Last published snapshot (nil if never published or disabled).
    var lastSnapshot: GlassesGlanceSnapshot? { get }

    func startSession() async
    func publish(_ snapshot: GlassesGlanceSnapshot)
    func endSession()
}

/// No-op adapter used when the feature flag is off (default).
@MainActor
final class NullGlassesGlanceAdapter: GlassesGlanceAdapter {
    let isEnabled = false
    let connectionState: GlassesGlanceConnectionState = .disabled
    private(set) var lastSnapshot: GlassesGlanceSnapshot?

    func startSession() async {}
    func publish(_ snapshot: GlassesGlanceSnapshot) {
        // Intentionally ignore — flag off means zero side effects.
        _ = snapshot
    }
    func endSession() {}
}

/// Production-shaped adapter: feature-gated, transport-injected.
@MainActor
final class DefaultGlassesGlanceAdapter: GlassesGlanceAdapter {
    private let transport: any GlassesHUDTransport
    private let enabled: Bool
    private(set) var lastSnapshot: GlassesGlanceSnapshot?
    private var sessionActive = false

    var isEnabled: Bool { enabled }

    var connectionState: GlassesGlanceConnectionState {
        guard enabled else { return .disabled }
        return transport.connectionState
    }

    init(
        transport: any GlassesHUDTransport,
        enabled: Bool = GlassesGlanceFeature.isEnabled
    ) {
        self.transport = transport
        self.enabled = enabled
    }

    func startSession() async {
        guard enabled else { return }
        sessionActive = true
        await transport.connect()
    }

    func publish(_ snapshot: GlassesGlanceSnapshot) {
        guard enabled, sessionActive else { return }
        lastSnapshot = snapshot
        guard transport.connectionState == .connected else { return }
        transport.push(lines: snapshot.hudLines)
    }

    func endSession() {
        guard enabled else { return }
        sessionActive = false
        lastSnapshot = nil
        transport.disconnect()
    }
}

/// Factory: default-off Null; when enabled, Mock transport (tests/lab) or Meta placeholder.
enum GlassesGlanceAdapterFactory {
    /// - Parameter preferMockTransport: force mock HUD (tests / Mock Device Kit path).
    @MainActor
    static func make(
        enabled: Bool = GlassesGlanceFeature.isEnabled,
        preferMockTransport: Bool = false
    ) -> any GlassesGlanceAdapter {
        guard enabled else { return NullGlassesGlanceAdapter() }
        let transport: any GlassesHUDTransport
        if preferMockTransport {
            transport = MockGlassesHUDTransport()
        } else {
            // Physical Meta SDK not linked — lab mock fallback keeps adapter functional
            // for development; physical glasses claims stay NOT_COMPUTABLE.
            transport = MetaWearablesHUDTransport(useMockFallbackInLab: true)
        }
        return DefaultGlassesGlanceAdapter(transport: transport, enabled: true)
    }
}
