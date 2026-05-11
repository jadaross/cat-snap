import Foundation

// Mirrors the row shape returned by `public.guide_list(...)` in migration
// 0003. One row per cat with per-user state baked in (is_spotted,
// is_favorite, last_seen_at, recent_photo_url).
struct GuideRow: Codable, Identifiable, Hashable, Sendable {
    let catId: UUID
    let catName: String?
    let primaryPhotoUrl: URL?
    let rarity: Cat.Rarity
    let isSpotted: Bool
    let isFavorite: Bool
    let lastSeenAt: Date?
    let recentPhotoUrl: URL?
    let distanceM: Double?

    var id: UUID { catId }

    enum CodingKeys: String, CodingKey {
        case catId            = "cat_id"
        case catName          = "cat_name"
        case primaryPhotoUrl  = "primary_photo_url"
        case rarity
        case isSpotted        = "is_spotted"
        case isFavorite       = "is_favorite"
        case lastSeenAt       = "last_seen_at"
        case recentPhotoUrl   = "recent_photo_url"
        case distanceM        = "distance_m"
    }
}

// Filter criteria sent to `public.guide_list(...)`. All fields optional;
// nil means "no filter on this axis".
struct GuideFilterCriteria: Encodable, Equatable, Hashable, Sendable {
    enum Status: String, Codable, Hashable, Sendable {
        case all
        case spotted
        case notSpotted = "not_spotted"
    }

    var favoritesOnly: Bool = false
    var status: Status = .all
    var rarities: [Cat.Rarity]? = nil
    var tags: [String]? = nil
    var seenAfter: Date? = nil
    var seenBefore: Date? = nil
    var nearLat: Double? = nil
    var nearLng: Double? = nil
    var nearRadiusM: Int? = nil

    /// True when the user has any active filter beyond the default.
    var hasActiveFilters: Bool {
        favoritesOnly
        || status != .all
        || (rarities?.isEmpty == false)
        || (tags?.isEmpty == false)
        || seenAfter != nil
        || seenBefore != nil
        || nearLat != nil
    }

    enum CodingKeys: String, CodingKey {
        case favoritesOnly  = "p_favorites_only"
        case status         = "p_status"
        case rarities       = "p_rarities"
        case tags           = "p_tags"
        case seenAfter      = "p_seen_after"
        case seenBefore     = "p_seen_before"
        case nearLat        = "p_near_lat"
        case nearLng        = "p_near_lng"
        case nearRadiusM    = "p_near_radius_m"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(favoritesOnly, forKey: .favoritesOnly)
        try c.encode(status.rawValue, forKey: .status)
        try c.encodeIfPresent(rarities?.map(\.rawValue), forKey: .rarities)
        try c.encodeIfPresent(tags, forKey: .tags)
        try c.encodeIfPresent(seenAfter, forKey: .seenAfter)
        try c.encodeIfPresent(seenBefore, forKey: .seenBefore)
        try c.encodeIfPresent(nearLat, forKey: .nearLat)
        try c.encodeIfPresent(nearLng, forKey: .nearLng)
        try c.encodeIfPresent(nearRadiusM, forKey: .nearRadiusM)
    }
}
