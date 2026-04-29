import Foundation

extension Notification.Name {
    /// Posted after a sighting has been successfully inserted. The map view
    /// listens and re-queries `sightings_near` so the new pin appears without
    /// the user needing to pan.
    static let sightingSubmitted = Notification.Name("CatSnap.sightingSubmitted")
}
