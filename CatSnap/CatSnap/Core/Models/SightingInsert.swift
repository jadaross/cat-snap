import Foundation

/// Encodable payload matching the `sightings` table for inserts.
/// `location` is sent as PostGIS-compatible WKT ("POINT(lng lat)"); the
/// column's SRID 4326 is applied automatically.
struct SightingInsert: Encodable {
    let userId: UUID
    let catId: UUID?
    let photoUrl: URL
    let location: String
    let locationLabel: String?
    let notes: String?
    let seenAt: Date

    init(
        userId: UUID,
        catId: UUID?,
        photoUrl: URL,
        latitude: Double,
        longitude: Double,
        locationLabel: String?,
        notes: String?,
        seenAt: Date
    ) {
        self.userId = userId
        self.catId = catId
        self.photoUrl = photoUrl
        self.location = "SRID=4326;POINT(\(longitude) \(latitude))"
        self.locationLabel = locationLabel
        self.notes = notes
        self.seenAt = seenAt
    }

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

/// Junction-table payload for `sighting_tags`.
struct SightingTagInsert: Encodable {
    let sightingId: UUID
    let tag: String

    enum CodingKeys: String, CodingKey {
        case sightingId = "sighting_id"
        case tag
    }
}
