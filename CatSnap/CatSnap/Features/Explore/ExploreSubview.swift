import Foundation

// Which sub-screen the Explore tab is showing. Owned by ExploreView and
// passed down to MapView / GuideListView so the SpotsHeader's pill toggle
// updates the parent.
enum ExploreSubview: Hashable {
    case map
    case guide
}
