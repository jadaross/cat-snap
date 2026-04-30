import SwiftUI
import MapKit
import Supabase
import PostgREST

@MainActor
@Observable
final class MapModel {
    var sightings: [NearbySighting] = []
    var isLoading = false
    var error: String?

    /// Latest centre + radius used for fetching — for the post-submit refresh
    /// where the user hasn't moved.
    private var lastFetchCentre: CLLocationCoordinate2D?
    private var lastRadiusMeters: Double = 5_000
    private let refetchThresholdMeters: Double = 500

    func fetchIfNeeded(centre: CLLocationCoordinate2D, radiusMeters: Double) async {
        if let last = lastFetchCentre {
            let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: centre.latitude, longitude: centre.longitude))
            if distance < refetchThresholdMeters && !sightings.isEmpty {
                return
            }
        }
        await fetch(centre: centre, radiusMeters: radiusMeters)
    }

    func refresh() async {
        guard let centre = lastFetchCentre else { return }
        await fetch(centre: centre, radiusMeters: lastRadiusMeters)
    }

    func fetch(centre: CLLocationCoordinate2D, radiusMeters: Double) async {
        isLoading = true
        defer { isLoading = false }
        lastFetchCentre = centre
        lastRadiusMeters = radiusMeters
        do {
            let params: [String: Double] = [
                "p_lat": centre.latitude,
                "p_lng": centre.longitude,
                "p_radius": radiusMeters,
                "p_limit": 200,
            ]
            let response: [NearbySighting] = try await supabase
                .rpc("sightings_near", params: params)
                .execute()
                .value
            sightings = response
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

enum TimeFilter: String, CaseIterable, Hashable {
    case today, week, all

    var label: String { rawValue }

    func includes(_ date: Date, now: Date = Date()) -> Bool {
        switch self {
        case .all:
            return true
        case .today:
            return Calendar.current.isDate(date, inSameDayAs: now)
        case .week:
            guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return true }
            return date >= weekAgo
        }
    }
}

struct MapView: View {
    @Binding var exploreView: ExploreSubview
    @State private var model = MapModel()
    @State private var locationManager = LocationManager()
    @State private var selectedSighting: NearbySighting?
    @State private var path = NavigationPath()
    @State private var timeFilter: TimeFilter = .all
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: .london,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    )
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: .london,
        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    )

    private static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)

    private var filteredSightings: [NearbySighting] {
        model.sightings.filter { timeFilter.includes($0.seenAt) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            mapContent
                .navigationDestination(for: UUID.self) { catId in
                    CatProfileView(catId: catId)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var mapContent: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition, selection: Binding(
                get: { selectedSighting?.id },
                set: { id in
                    selectedSighting = id.flatMap { tag in filteredSightings.first { $0.id == tag } }
                }
            )) {
                ForEach(filteredSightings) { sighting in
                    Annotation(
                        sighting.catName ?? "",
                        coordinate: CLLocationCoordinate2D(latitude: sighting.lat, longitude: sighting.lng),
                        anchor: .bottom
                    ) {
                        CatPin(
                            photoUrl: sighting.catPhotoUrl ?? sighting.photoUrl,
                            isSelected: selectedSighting?.id == sighting.id
                        )
                    }
                    .tag(sighting.id)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onMapCameraChange(frequency: .onEnd) { context in
                mapRegion = context.region
                Task {
                    let centre = context.region.center
                    let radius = max(context.region.span.latitudeDelta, context.region.span.longitudeDelta) * 111_000
                    await model.fetchIfNeeded(centre: centre, radiusMeters: max(radius, 1_000))
                }
            }
            .ignoresSafeArea(edges: .bottom)

            if let selected = selectedSighting {
                PinDetailCard(sighting: selected) {
                    if let catId = selected.catId {
                        path.append(catId)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 96)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if !filteredSightings.isEmpty {
                NearbyCatsCard(sightings: filteredSightings) { sighting in
                    focus(on: sighting)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Empty-state card. Shown when nothing matched the filter.
            if !model.isLoading && filteredSightings.isEmpty && selectedSighting == nil {
                emptyStateCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 96)
                    .transition(.opacity)
            }

            if model.isLoading {
                ProgressView()
                    .tint(Color.coral)
                    .padding(8)
                    .background(Color.creamSoft, in: .capsule)
                    .padding(.top, 64)
                    .frame(maxHeight: .infinity, alignment: .top)
            }

            // Top header (Map / Guide toggle + location pill) and recentre button.
            VStack(spacing: 8) {
                SpotsHeader(view: $exploreView)
                    .padding(.top, 8)

                if let recent = mostRecentSighting, selectedSighting == nil {
                    LiveTickerChip(
                        title: tickerTitle(for: recent),
                        timestamp: relativeShort(for: recent.seenAt),
                        onTap: { focus(on: recent) }
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                HStack(alignment: .top) {
                    timeFilterRow
                    Spacer()
                    VStack(spacing: 8) {
                        recenterButton
                        zoomButtons
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedSighting?.id)
        .animation(.easeInOut(duration: 0.2), value: filteredSightings.count)
        .task {
            await initialCentre()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sightingSubmitted)) { _ in
            Task { await model.refresh() }
        }
    }

    private var timeFilterRow: some View {
        HStack(spacing: 6) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                TagChip(
                    tag: filter.label,
                    isActive: timeFilter == filter,
                    onTap: { timeFilter = filter }
                )
            }
        }
        .padding(6)
        .background(Color.creamSoft.opacity(0.92), in: .capsule)
        .shadow(color: Color.ink.opacity(0.12), radius: 6, y: 2)
    }

    private var recenterButton: some View {
        Button {
            Task { await recenterToUser(prompting: true) }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.coral)
                .frame(width: 44, height: 44)
                .background(Color.creamSoft, in: .circle)
                .shadow(color: Color.ink.opacity(0.18), radius: 6, y: 2)
        }
        .accessibilityLabel("recenter map")
    }

    private var zoomButtons: some View {
        VStack(spacing: 0) {
            Button { zoom(factor: 0.5) } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.coral)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("zoom in")
            Rectangle()
                .fill(Color.stoneLight)
                .frame(width: 28, height: 1)
            Button { zoom(factor: 2.0) } label: {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.coral)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("zoom out")
        }
        .background(Color.creamSoft, in: .rect(cornerRadius: 12))
        .shadow(color: Color.ink.opacity(0.18), radius: 6, y: 2)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 8) {
            CatWindowMark(size: 48, showSill: false)
                .opacity(0.7)
            Text(emptyStateTitle)
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(Color.ink)
            Text("tap + to log one.")
                .font(.Brand.jakarta(.regular, size: 12))
                .foregroundStyle(Color.stone)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.creamSoft.opacity(0.95), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
        .shadow(color: Color.ink.opacity(0.08), radius: 8, y: 2)
    }

    private var emptyStateTitle: String {
        switch timeFilter {
        case .today: return "no sightings today"
        case .week:  return "no sightings this week"
        case .all:   return "no cats spotted nearby"
        }
    }

    // Most recent sighting in the last hour — drives the live ticker chip.
    private var mostRecentSighting: NearbySighting? {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return model.sightings
            .filter { $0.seenAt > oneHourAgo }
            .max(by: { $0.seenAt < $1.seenAt })
    }

    private func tickerTitle(for sighting: NearbySighting) -> String {
        let name = sighting.catName ?? "a cat"
        if let label = sighting.locationLabel, !label.isEmpty {
            return "\(name) just spotted · \(label)"
        }
        return "\(name) just spotted nearby"
    }

    private func relativeShort(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func zoom(factor: Double) {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(max(mapRegion.span.latitudeDelta * factor, 0.001), 120),
            longitudeDelta: min(max(mapRegion.span.longitudeDelta * factor, 0.001), 120)
        )
        let newRegion = MKCoordinateRegion(center: mapRegion.center, span: newSpan)
        mapRegion = newRegion
        withAnimation {
            cameraPosition = .region(newRegion)
        }
    }

    private func focus(on sighting: NearbySighting) {
        selectedSighting = sighting
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: sighting.lat, longitude: sighting.lng),
                span: Self.defaultSpan
            ))
        }
    }

    private func initialCentre() async {
        // If location's already granted, centre on the user. Otherwise default
        // to London — don't pop a permission prompt just for the map.
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            await recenterToUser(prompting: false)
        default:
            await model.fetch(centre: .london, radiusMeters: 5_000)
        }
    }

    private func recenterToUser(prompting: Bool) async {
        do {
            // If we'd trigger a permission prompt and the caller said no, bail.
            if !prompting && locationManager.authorizationStatus == .notDetermined {
                await model.fetch(centre: .london, radiusMeters: 5_000)
                return
            }
            let location = try await locationManager.requestOneShot()
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: Self.defaultSpan
                ))
            }
            await model.fetch(centre: location.coordinate, radiusMeters: 5_000)
        } catch {
            // Silent failure — user can pan manually. Map already centred on London.
            await model.fetch(centre: .london, radiusMeters: 5_000)
        }
    }
}

private extension CLLocationCoordinate2D {
    static let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
}
