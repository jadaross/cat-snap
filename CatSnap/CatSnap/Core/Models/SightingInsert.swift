import Foundation

/// Encodable payload matching the `sightings` table for inserts.
/// The `location` PostGIS column accepts a GeoJSON object; PostgREST
/// auto-casts to `geography(Point, 4326)` when the column type is set.
struct SightingInsert: Encodable {
    let userId: UUID
    let catId: UUID?
    let photoUrl: URL
    let location: GeoJSONPoint
    let locationLabel: String?
    let notes: String?
    let seenAt: Date

    enum CodingKeys: String, CodingKey {
        case userId         = "user_id"
        case catId          = "cat_id"
        case photoUrl       = "photo_url"
        case location
        case locationLabel  = "location_label"
        case notes
        case seenAt         = "seen_at"
    }
}

struct GeoJSONPoint: Encodable {
    let type = "Point"
    let coordinates: [Double]  // [lng, lat] — GeoJSON convention is x, y

    init(latitude: Double, longitude: Double) {
        self.coordinates = [longitude, latitude]
    }
}

/// Junction-table payload for `sighting_tags`.
struct SightingTagInsert: Encodable {
    let sightingId: UUID
    let tag: String

    enum CodingKeys: String, CodingKey {
        case sightingId = "sighting_id"
        case tag
    }
}
