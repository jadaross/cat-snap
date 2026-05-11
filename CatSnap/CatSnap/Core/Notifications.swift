import Foundation

extension Notification.Name {
    /// Posted after a sighting has been successfully inserted. The map view
    /// listens and re-queries `sightings_near` so the new pin appears without
    /// the user needing to pan.
    static let sightingSubmitted = Notification.Name("CatSnap.sightingSubmitted")

    /// Posted when the Explore tab is re-tapped while already active. The
    /// map and guide views listen and reset their navigation stacks so the
    /// user always lands on the root, regardless of how deep they were.
    static let popExploreToRoot = Notification.Name("CatSnap.popExploreToRoot")
}
