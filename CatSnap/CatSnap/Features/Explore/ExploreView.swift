import SwiftUI

// Top-level Explore tab. Owns the map/guide toggle state and swaps between
// MapView and GuideListView. Each child renders its own SpotsHeader and
// NavigationStack, so the toggle pill stays interactive in either view.
struct ExploreView: View {
    @State private var view: ExploreSubview = .map

    var body: some View {
        switch view {
        case .map:
            MapView(exploreView: $view)
        case .guide:
            GuideListView(exploreView: $view)
        }
    }
}
