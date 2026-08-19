import SwiftUI
import MapKit

// "Where they hang out" — every place a cat has been seen, on one map.
//
// Coordinates come from the `sightings_for_cat` RPC (migration 0005); they
// can't come from a plain table read, because PostGIS geography arrives over
// PostgREST as WKB hex.
struct CatTerritoryMap: View {
    let sightings: [CatSighting]
    var height: CGFloat = 180
    /// Inline the map is inert and taps open the full-screen sheet — a
    /// pannable map inside a ScrollView fights the user's finger. The sheet
    /// passes true.
    var isInteractive: Bool = false

    var body: some View {
        Map(initialPosition: initialPosition, interactionModes: isInteractive ? .all : []) {
            ForEach(sightings) { sighting in
                Annotation("", coordinate: sighting.coordinate) {
                    // 84pt (the CatPin default) would carpet a 180pt card.
                    CatPin(photoUrl: sighting.photoUrl, size: isInteractive ? 64 : 44)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .frame(height: height)
        .allowsHitTesting(isInteractive)
    }

    private var initialPosition: MapCameraPosition {
        guard let region = MKCoordinateRegion.fitting(sightings.map(\.coordinate)) else {
            return .automatic
        }
        return .region(region)
    }
}

// Full-screen version, reached by tapping the inline card.
struct CatTerritoryMapSheet: View {
    let catName: String?
    let sightings: [CatSighting]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CatTerritoryMap(sightings: sightings, height: .infinity, isInteractive: true)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "done")) { dismiss() }
                            .font(.Brand.jakarta(.medium, size: 14))
                            .foregroundStyle(Color.coral)
                    }
                }
        }
    }

    private var title: String {
        let trimmed = (catName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? String(localized: "where they hang out")
            : String(localized: "where \(trimmed.lowercased()) hangs out")
    }
}
