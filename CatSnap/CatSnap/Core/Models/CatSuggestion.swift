import Foundation

// Matches the return shape of the `public.search_cats` RPC (migration 0005).
// Backs the type-ahead under the Submit form's NAME field, so a repeat
// sighting attaches to the cat that already exists rather than creating a
// second row under the same name.
struct CatSuggestion: Codable, Identifiable, Hashable, Sendable {
    let catId: UUID
    let catName: String?
    let primaryPhotoUrl: URL?
    let rarity: Cat.Rarity?
    let sightingCount: Int
    let lastSeenAt: Date?
    let lastPhotoUrl: URL?

    var id: UUID { catId }

    enum CodingKeys: String, CodingKey {
        case catId            = "cat_id"
        case catName          = "cat_name"
        case primaryPhotoUrl  = "primary_photo_url"
        case rarity
        case sightingCount    = "sighting_count"
        case lastSeenAt       = "last_seen_at"
        case lastPhotoUrl     = "last_photo_url"
    }
}
