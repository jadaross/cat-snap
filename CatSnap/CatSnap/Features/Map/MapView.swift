import SwiftUI
import MapKit

@MainActor
@Observable
final class MapModel {
    var sightings: [NearbySighting] = []
    var isLoading = false
    var error: String?

    /// Latest centre + radius + favourites-only flag used for fetching — for the
    /// post-submit refresh where the user hasn't moved.
    private var lastFetchCentre: CLLocationCoordinate2D?
    private var lastRadiusMeters: Double = 5_000
    private var lastFavoritesOnly: Bool = false
    private let refetchThresholdMeters: Double = 500

    func fetchIfNeeded(centre: CLLocationCoordinate2D, radiusMeters: Double, favoritesOnly: Bool) async {
        if let last = lastFetchCentre, lastFavoritesOnly == favoritesOnly {
            let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: centre.latitude, longitude: centre.longitude))
            if distance < refetchThresholdMeters && !sightings.isEmpty {
                return
            }
        }
        await fetch(centre: centre, radiusMeters: radiusMeters, favoritesOnly: favoritesOnly)
    }

    func refresh() async {
        guard let centre = lastFetchCentre else { return }
        await fetch(centre: centre, radiusMeters: lastRadiusMeters, favoritesOnly: lastFavoritesOnly)
    }

    func fetch(centre: CLLocationCoordinate2D, radiusMeters: Double, favoritesOnly: Bool) async {
        isLoading = true
        defer { isLoading = false }
        lastFetchCentre = centre
        lastRadiusMeters = radiusMeters
        lastFavoritesOnly = favoritesOnly
        do {
            sightings = try await SightingsReads.nearby(
                centre: centre,
                radiusMeters: radiusMeters,
                favoritesOnly: favoritesOnly
            )
            error = nil
        } catch {
            self.error = AppError.map(error).localizedDescription
        }
    }
}

struct MapView: View {
    @Binding var exploreView: ExploreSubview
    @State private var model = MapModel()
    @State private var locationManager = LocationManager()
    @State private var path = NavigationPath()
    @State private var favoritesOnly: Bool = false
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

    /// Rough conversion: at the equator, 1 degree of latitude ≈ 111 km.
    /// Good enough for picking a fetch radius from a map span.
    private static let metersPerDegree = 111_000.0

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
            // Tapping a pin sets the selection binding; we route that to a
            // navigation push immediately so there's no intermediate detail
            // card. The selection-id source-of-truth is left at nil; the
            // setter just consumes the tap.
            Map(position: $cameraPosition, selection: Binding<UUID?>(
                get: { nil },
                set: { id in
                    guard
                        let id,
                        let sighting = model.sightings.first(where: { $0.id == id }),
                        let catId = sighting.catId
                    else { return }
                    path.append(catId)
                }
            )) {
                ForEach(model.sightings) { sighting in
                    Annotation(
                        sighting.catName ?? "",
                        coordinate: CLLocationCoordinate2D(latitude: sighting.lat, longitude: sighting.lng),
                        anchor: .bottom
                    ) {
                        CatPin(
                            photoUrl: sighting.catPhotoUrl ?? sighting.photoUrl,
                            isSelected: false
                        )
                    }
                    .tag(sighting.id)
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .onMapCameraChange(frequency: .onEnd) { context in
                mapRegion = context.region
                Task {
                    let centre = context.region.center
                    let radius = max(context.region.span.latitudeDelta, context.region.span.longitudeDelta) * Self.metersPerDegree
                    await model.fetchIfNeeded(
                        centre: centre,
                        radiusMeters: max(radius, 1_000),
                        favoritesOnly: favoritesOnly
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Empty-state card.
            if !model.isLoading && model.sightings.isEmpty {
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

            // Top header (Map / Guide toggle + location pill) and recentre / zoom / favourites buttons.
            VStack(spacing: 8) {
                SpotsHeader(view: $exploreView)
                    .padding(.top, 8)

                if let recent = mostRecentSighting {
                    LiveTickerChip(
                        title: tickerTitle(for: recent),
                        timestamp: relativeShort(for: recent.seenAt),
                        onTap: { recentre(on: recent) }
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                HStack(alignment: .top) {
                    Spacer()
                    VStack(spacing: 8) {
                        favoritesToggleButton
                        recenterButton
                        zoomButtons
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.sightings.count)
        .task {
            await initialCentre()
        }
        .onChange(of: favoritesOnly) { _, _ in
            Task {
                let centre = mapRegion.center
                let radius = max(mapRegion.span.latitudeDelta, mapRegion.span.longitudeDelta) * Self.metersPerDegree
                await model.fetch(
                    centre: centre,
                    radiusMeters: max(radius, 1_000),
                    favoritesOnly: favoritesOnly
                )
                frameCameraOnPins()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sightingSubmitted)) { _ in
            Task { await model.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .popExploreToRoot)) { _ in
            path = NavigationPath()
        }
    }

    private var favoritesToggleButton: some View {
        Button {
            favoritesOnly.toggle()
        } label: {
            Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(favoritesOnly ? Color.creamSoft : Color.coral)
                .frame(width: 44, height: 44)
                .background(favoritesOnly ? Color.coral : Color.creamSoft, in: .circle)
                .shadow(color: Color.ink.opacity(0.18), radius: 6, y: 2)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: favoritesOnly)
        }
        .accessibilityLabel(favoritesOnly ? "show all cats" : "show only favourites")
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
            Text(emptyStateSubtitle)
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
        favoritesOnly ? "no favourites in this area" : "no cats spotted nearby"
    }

    private var emptyStateSubtitle: String {
        favoritesOnly ? "tap the heart to show all cats." : "tap + to log one."
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

    /// Centre the map on a sighting without selecting it — used by the live
    /// ticker chip so tapping "kitty just spotted nearby" pans to its pin
    /// without bouncing the user out to the cat profile.
    private func recentre(on sighting: NearbySighting) {
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
            await model.fetch(centre: .london, radiusMeters: 5_000, favoritesOnly: favoritesOnly)
            frameCameraOnPins()
        }
    }

    private func recenterToUser(prompting: Bool) async {
        do {
            // If we'd trigger a permission prompt and the caller said no, bail.
            if !prompting && locationManager.authorizationStatus == .notDetermined {
                await model.fetch(centre: .london, radiusMeters: 5_000, favoritesOnly: favoritesOnly)
                frameCameraOnPins()
                return
            }
            let location = try await locationManager.requestOneShot()
            // Centre on the user immediately so the map isn't blank during the
            // fetch; the post-fetch frameCameraOnPins() will tighten in around
            // the cats nearby (or stay put if nothing came back).
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: Self.defaultSpan
                ))
            }
            await model.fetch(centre: location.coordinate, radiusMeters: 5_000, favoritesOnly: favoritesOnly)
            frameCameraOnPins(includingUser: location.coordinate)
        } catch {
            // Silent failure — user can pan manually. Map already centred on London.
            await model.fetch(centre: .london, radiusMeters: 5_000, favoritesOnly: favoritesOnly)
            frameCameraOnPins()
        }
    }

    /// Re-frame the camera to comfortably fit every pin in `model.sightings`.
    /// Skipped when there are no pins — leaves whatever centring the caller
    /// already established (user location / London fallback). The `including`
    /// coordinate (typically the user) is folded into the bounding box when
    /// supplied so the user's location isn't lost off-screen.
    private func frameCameraOnPins(includingUser user: CLLocationCoordinate2D? = nil) {
        guard !model.sightings.isEmpty else { return }

        var lats = model.sightings.map(\.lat)
        var lngs = model.sightings.map(\.lng)
        if let user {
            lats.append(user.latitude)
            lngs.append(user.longitude)
        }

        guard
            let minLat = lats.min(), let maxLat = lats.max(),
            let minLng = lngs.min(), let maxLng = lngs.max()
        else { return }

        let centre = CLLocationCoordinate2D(
            latitude:  (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        // 1.4× padding around the bounding box so pins aren't kissing the
        // edges. Minimum span keeps a single pin from zooming uncomfortably
        // close (≈1km wide).
        let minSpan: CGFloat = 0.009
        let span = MKCoordinateSpan(
            latitudeDelta:  max((maxLat - minLat) * 1.4, minSpan),
            longitudeDelta: max((maxLng - minLng) * 1.4, minSpan)
        )

        let region = MKCoordinateRegion(center: centre, span: span)
        mapRegion = region
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(region)
        }
    }
}

private extension CLLocationCoordinate2D {
    static let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
}
