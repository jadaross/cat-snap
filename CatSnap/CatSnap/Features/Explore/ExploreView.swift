import SwiftUI

// Top-level Explore tab. Subview state (.map / .guide) lives in MainTabView
// so a re-tap on the Explore tab can force a return to the map. Each child
// renders its own SpotsHeader and NavigationStack.
struct ExploreView: View {
    @Binding var view: ExploreSubview

    var body: some View {
        switch view {
        case .map:
            MapView(exploreView: $view)
        case .guide:
            GuideListView(exploreView: $view)
        }
    }
}
