import Foundation

// Matches the `sightings` table for inserts and single-record fetches.
// Note: the PostGIS `location` column is intentionally not modelled here —
// for reads we use the `sightings_near` RPC (see NearbySighting below); for
// inserts we'll send a server-side ST_MakePoint via a typed insert helper.
struct Sighting: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var catId: UUID?
    var photoUrl: URL
    var locationLabel: String?
    var notes: String?
    var seenAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId         = "user_id"
        case catId          = "cat_id"
        case photoUrl       = "photo_url"
        case locationLabel  = "location_label"
        case notes
        case seenAt         = "seen_at"
        case createdAt      = "created_at"
    }
}

// Matches the return shape of the `public.sightings_near` RPC.
struct NearbySighting: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let catId: UUID?
    let photoUrl: URL
    let locationLabel: String?
    let notes: String?
    let seenAt: Date
    let lat: Double
    let lng: Double
    let catName: String?
    let catPhotoUrl: URL?
    let catRarity: Cat.Rarity?
    let username: String
    let displayName: String?
    let avatarUrl: URL?
    let distanceM: Double

    enum CodingKeys: String, CodingKey {
        case id
        case userId         = "user_id"
        case catId          = "cat_id"
        case photoUrl       = "photo_url"
        case locationLabel  = "location_label"
        case notes
        case seenAt         = "seen_at"
        case lat
        case lng
        case catName        = "cat_name"
        case catPhotoUrl    = "cat_photo_url"
        case catRarity      = "cat_rarity"
        case username
        case displayName    = "display_name"
        case avatarUrl      = "avatar_url"
        case distanceM      = "distance_m"
    }
}
