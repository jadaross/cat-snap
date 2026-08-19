import Foundation
import CoreLocation

// Matches the `sightings` table for inserts and single-record fetches.
// Note: the PostGIS `location` column is intentionally not modelled here —
// for reads we use the `sightings_near` RPC (see NearbySighting below); for
// inserts we'll send a server-side ST_MakePoint via a typed insert helper.
//
// `photoUrl` is optional because the no-photo "I spotted them" check-in
// (record_spot RPC, migration 0003) writes a sighting with photo_url = null.
struct Sighting: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var catId: UUID?
    var photoUrl: URL?
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

// Matches the return shape of the `public.sightings_near` RPC (migration 0003
// added `is_favorite` to the column list).
struct NearbySighting: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let catId: UUID?
    let photoUrl: URL?
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
    let isFavorite: Bool

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
        case isFavorite     = "is_favorite"
    }
}

// Matches the return shape of the `public.sightings_for_cat` RPC (migration
// 0005). Where `Sighting` is the raw table shape — and so has no coordinates,
// because PostgREST hands the geography column back as WKB hex — this carries
// lat/lng projected server-side plus the spotter's profile. That lets a cat
// profile draw its territory map, its grid, and its spotter list from one read.
struct CatSighting: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let catId: UUID?
    let photoUrl: URL?
    let locationLabel: String?
    let notes: String?
    let seenAt: Date
    let createdAt: Date
    let lat: Double
    let lng: Double
    // Optional, unlike NearbySighting: the RPC left-joins profiles, so a
    // deleted account leaves a real sighting with no spotter attached.
    let username: String?
    let displayName: String?
    let avatarUrl: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case userId         = "user_id"
        case catId          = "cat_id"
        case photoUrl       = "photo_url"
        case locationLabel  = "location_label"
        case notes
        case seenAt         = "seen_at"
        case createdAt      = "created_at"
        case lat
        case lng
        case username
        case displayName    = "display_name"
        case avatarUrl      = "avatar_url"
    }
}

extension CatSighting {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// Display name for the spotter, falling back through username to a
    /// neutral placeholder for deleted accounts.
    var spotterName: String {
        displayName ?? username ?? String(localized: "someone")
    }
}
