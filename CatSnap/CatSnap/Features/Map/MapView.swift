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

struct MapView: View {
    @State private var model = MapModel()
    @State private var selectedSighting: NearbySighting?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: .london,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition, selection: Binding(
                get: { selectedSighting?.id },
                set: { id in
                    selectedSighting = id.flatMap { tag in model.sightings.first { $0.id == tag } }
                }
            )) {
                ForEach(model.sightings) { sighting in
                    Annotation(
                        sighting.catName ?? "",
                        coordinate: CLLocationCoordinate2D(latitude: sighting.lat, longitude: sighting.lng)
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
                Task {
                    let centre = context.region.center
                    let radius = max(context.region.span.latitudeDelta, context.region.span.longitudeDelta) * 111_000
                    await model.fetchIfNeeded(centre: centre, radiusMeters: max(radius, 1_000))
                }
            }
            .ignoresSafeArea(edges: .bottom)

            if let selected = selectedSighting {
                PinDetailCard(sighting: selected) {
                    // TODO (slice 3.C): push CatProfileView for selected.catId.
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 96)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if model.isLoading {
                ProgressView()
                    .tint(Color.coral)
                    .padding(8)
                    .background(Color.creamSoft, in: .capsule)
                    .padding(.top, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedSighting?.id)
        .task {
            await model.fetch(centre: .london, radiusMeters: 5_000)
        }
        .onReceive(NotificationCenter.default.publisher(for: .sightingSubmitted)) { _ in
            Task { await model.refresh() }
        }
    }
}

private extension CLLocationCoordinate2D {
    static let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
}
