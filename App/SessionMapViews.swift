import MapKit
import SwiftUI
import WaykinCore

// Issue #155: full interactive session map + route creation chrome.

/// Compact session map: walked path + planned route preview; tappable to expand.
struct CompactSessionMap: View {
    let latitude: Double?
    let longitude: Double?
    var trace: WalkPathTrace = WalkPathTrace()
    var plannedRoute: PlannedWalkRoute = .empty
    var onOpenFullMap: (() -> Void)? = nil

    @Environment(\.wkTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var camera: MapCameraPosition = .automatic

    var locationAccessibilityValue: String {
        guard latitude != nil, longitude != nil else {
            return "Waiting for a location update."
        }
        var parts: [String] = []
        if trace.count >= 2 {
            parts.append("Current location and the walked path so far are shown.")
        } else {
            parts.append("Current location is available for this walk.")
        }
        if plannedRoute.isReady {
            parts.append(plannedRoute.accessibilitySummary)
        }
        return parts.joined(separator: " ")
    }

    private var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude ?? 37.7749,
            longitude: longitude ?? -122.4194
        )
    }

    private func region(around coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Map", systemImage: "map")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                    .accessibilityHidden(true)
                Spacer()
                if plannedRoute.isReady {
                    Text(plannedRoute.summaryLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.bondText)
                        .lineLimit(1)
                        .accessibilityIdentifier("waykin.session.map.routeSummary")
                }
            }

            ZStack {
                Map(position: $camera, interactionModes: []) {
                    if plannedRoute.isReady {
                        MapPolyline(coordinates: plannedRoute.polyline.map(\.coordinate))
                            .stroke(
                                theme.bond.opacity(0.9),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 4])
                            )
                        Marker(plannedRoute.destinationName.isEmpty ? "Destination" : plannedRoute.destinationName,
                               systemImage: "flag.fill",
                               coordinate: plannedRoute.destinationCoordinate)
                        .tint(theme.bond)
                    }
                    if trace.count >= 2 {
                        MapPolyline(coordinates: trace.points.map(\.coordinate))
                            .stroke(
                                theme.guide.opacity(0.85),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                    }
                    if latitude != nil, longitude != nil {
                        Marker("Current location", coordinate: center)
                    }
                }
                .accessibilityHidden(true)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { onOpenFullMap?() }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Map")
                    .accessibilityValue(locationAccessibilityValue)
                    .accessibilityHint(onOpenFullMap == nil ? "" : "Opens the full map and route tools.")
                    .accessibilityAddTraits(.isButton)
                    .accessibilitySortPriority(-1)
                    .accessibilityIdentifier("waykin.session.map")
            }
            .frame(height: plannedRoute.isReady ? 120 : 96)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 10) {
                Button {
                    onOpenFullMap?()
                } label: {
                    Label("Open map", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.semibold))
                        .frame(minHeight: 36)
                }
                .buttonStyle(.bordered)
                .tint(theme.guide)
                .accessibilityIdentifier("waykin.session.map.open")

                Button {
                    onOpenFullMap?()
                } label: {
                    Label(plannedRoute.isReady ? "Edit route" : "Create route", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.caption.weight(.semibold))
                        .frame(minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.guide)
                .accessibilityIdentifier("waykin.session.map.createRoute")
            }
        }
        .onAppear { camera = region(around: center) }
        .onChange(of: latitude) { _, _ in follow() }
        .onChange(of: longitude) { _, _ in follow() }
        .onChange(of: plannedRoute.status) { _, _ in follow() }
    }

    private func follow() {
        guard latitude != nil, longitude != nil else { return }
        let target = region(around: center)
        if reduceMotion {
            camera = target
        } else {
            withAnimation(.easeInOut(duration: 0.6)) { camera = target }
        }
    }
}

/// Full-screen interactive map: pan/zoom, place search, create/clear walking route.
struct SessionMapFullView: View {
    let latitude: Double?
    let longitude: Double?
    let trace: WalkPathTrace
    @Binding var plannedRoute: PlannedWalkRoute
    var planner: WalkRoutePlanner
    var onDismiss: () -> Void

    @Environment(\.wkTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var camera: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var searchHits: [WalkRoutePlaceHit] = []
    @State private var isSearching = false
    @State private var followUser = true
    @FocusState private var searchFocused: Bool

    private var origin: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude ?? 37.7749,
            longitude: longitude ?? -122.4194
        )
    }

    private var hasUserFix: Bool { latitude != nil && longitude != nil }

    private var showsClearRoute: Bool {
        switch plannedRoute.status {
        case .ready, .failed: return true
        case .none, .searching: return false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchChrome
                mapBody
                routeChrome
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Walk map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                        .accessibilityIdentifier("waykin.session.map.done")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        followUser = true
                        recenter()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                    .accessibilityLabel("Center on me")
                    .accessibilityIdentifier("waykin.session.map.recenter")
                }
            }
            .onAppear {
                recenter()
            }
        }
    }

    private var searchChrome: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.textTertiary)
                TextField("Search a place for your route", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onSubmit { Task { await runSearch() } }
                    .accessibilityIdentifier("waykin.session.map.searchField")
                if isSearching {
                    ProgressView()
                        .controlSize(.small)
                } else if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchHits = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.textTertiary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(12)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if !searchHits.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchHits) { hit in
                            Button {
                                Task { await selectPlace(hit) }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(hit.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(theme.textPrimary)
                                    if !hit.subtitle.isEmpty {
                                        Text(hit.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .accessibilityIdentifier("waykin.session.map.place.\(hit.id.hashValue)")
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 180)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 12)
            }
        }
    }

    private var mapBody: some View {
        MapReader { proxy in
            Map(position: $camera, interactionModes: [.pan, .zoom, .pitch]) {
                if plannedRoute.isReady {
                    MapPolyline(coordinates: plannedRoute.polyline.map(\.coordinate))
                        .stroke(
                            theme.bond.opacity(0.95),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [8, 5])
                        )
                    Marker(
                        plannedRoute.destinationName.isEmpty ? "Destination" : plannedRoute.destinationName,
                        systemImage: "flag.fill",
                        coordinate: plannedRoute.destinationCoordinate
                    )
                    .tint(theme.bond)
                }
                if trace.count >= 2 {
                    MapPolyline(coordinates: trace.points.map(\.coordinate))
                        .stroke(
                            theme.guide.opacity(0.9),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                }
                if hasUserFix {
                    Annotation("You", coordinate: origin) {
                        ZStack {
                            Circle()
                                .fill(theme.guide.opacity(0.25))
                                .frame(width: 28, height: 28)
                            Circle()
                                .fill(theme.guide)
                                .frame(width: 12, height: 12)
                        }
                        .accessibilityHidden(true)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .onMapCameraChange(frequency: .onEnd) { _ in
                followUser = false
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.55)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        guard case .second(true, let drag?) = value else { return }
                        if let coordinate = proxy.convert(drag.location, from: .local) {
                            Task {
                                await planToCoordinate(
                                    coordinate,
                                    name: "Pinned place"
                                )
                            }
                        }
                    }
            )
            .accessibilityIdentifier("waykin.session.map.full")
        }
    }

    private var routeChrome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(routeStatusText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(routeStatusIsCaution ? theme.caution : theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("waykin.session.map.routeStatus")
                .accessibilityLabel("Route status")
                .accessibilityValue(plannedRoute.accessibilitySummary)

            Text("Guide only — not turn-by-turn navigation. Lira still follows your real walk.")
                .font(.caption)
                .foregroundStyle(theme.textTertiary)

            HStack(spacing: 12) {
                if showsClearRoute {
                    Button(role: .destructive) {
                        plannedRoute = .empty
                        searchHits = []
                    } label: {
                        Text("Clear route")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("waykin.session.map.clearRoute")
                }

                Spacer()

                Button {
                    Task { await runSearch() }
                } label: {
                    Text("Search")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.guide)
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || isSearching)
                .accessibilityIdentifier("waykin.session.map.searchButton")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }

    private func runSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return }
        isSearching = true
        defer { isSearching = false }
        searchHits = await planner.searchPlaces(query: query, near: origin)
        searchFocused = false
    }

    private func selectPlace(_ hit: WalkRoutePlaceHit) async {
        searchHits = []
        searchText = hit.name
        await planToCoordinate(hit.coordinate, name: hit.name)
    }

    private func planToCoordinate(_ destination: CLLocationCoordinate2D, name: String) async {
        guard hasUserFix else {
            plannedRoute = PlannedWalkRoute(
                destinationName: name,
                destinationLatitude: destination.latitude,
                destinationLongitude: destination.longitude,
                polyline: [],
                distanceMeters: 0,
                expectedTravelTime: 0,
                status: .failed("Wait for GPS before creating a route.")
            )
            return
        }
        plannedRoute = PlannedWalkRoute(
            destinationName: name,
            destinationLatitude: destination.latitude,
            destinationLongitude: destination.longitude,
            polyline: [],
            distanceMeters: 0,
            expectedTravelTime: 0,
            status: .searching
        )
        let result = await planner.plan(from: origin, to: destination, destinationName: name)
        plannedRoute = result
        if result.isReady {
            fitRoute(result)
        }
    }

    private var routeStatusText: String {
        switch plannedRoute.status {
        case .none:
            return "Search for a place or long-press the map to create a walking route."
        default:
            return plannedRoute.summaryLabel
        }
    }

    private var routeStatusIsCaution: Bool {
        if case .failed = plannedRoute.status { return true }
        return false
    }

    private func recenter() {
        let target: MapCameraPosition = .region(MKCoordinateRegion(
            center: origin,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
        if reduceMotion {
            camera = target
        } else {
            withAnimation(.easeInOut(duration: 0.45)) { camera = target }
        }
    }

    private func fitRoute(_ route: PlannedWalkRoute) {
        let coords = route.polyline.map(\.coordinate) + [origin]
        guard let minLat = coords.map(\.latitude).min(),
              let maxLat = coords.map(\.latitude).max(),
              let minLon = coords.map(\.longitude).min(),
              let maxLon = coords.map(\.longitude).max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLat - minLat) * 1.4),
            longitudeDelta: max(0.01, (maxLon - minLon) * 1.4)
        )
        let target: MapCameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        if reduceMotion {
            camera = target
        } else {
            withAnimation(.easeInOut(duration: 0.55)) { camera = target }
        }
        followUser = false
    }
}
