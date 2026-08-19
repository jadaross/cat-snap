import MapKit

extension MKCoordinateRegion {
    /// Region that comfortably fits every coordinate.
    ///
    /// Extracted from `MapView.frameCameraOnPins` so the cat profile's
    /// territory map frames its pins by the same rules as the map tab.
    ///
    /// - Parameters:
    ///   - padding: multiplier on the bounding box so pins aren't kissing the
    ///     edges.
    ///   - minSpan: floor on the span (≈1km) so a single pin doesn't zoom
    ///     uncomfortably close.
    /// - Returns: nil when given no coordinates, so callers can leave whatever
    ///   centring they already had.
    static func fitting(
        _ coordinates: [CLLocationCoordinate2D],
        padding: Double = 1.4,
        minSpan: CLLocationDegrees = 0.009
    ) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }

        let lats = coordinates.map(\.latitude)
        let lngs = coordinates.map(\.longitude)

        guard
            let minLat = lats.min(), let maxLat = lats.max(),
            let minLng = lngs.min(), let maxLng = lngs.max()
        else { return nil }

        let centre = CLLocationCoordinate2D(
            latitude:  (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta:  max((maxLat - minLat) * padding, minSpan),
            longitudeDelta: max((maxLng - minLng) * padding, minSpan)
        )
        return MKCoordinateRegion(center: centre, span: span)
    }
}
