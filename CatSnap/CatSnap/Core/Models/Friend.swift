import Foundation

// Mirrors the row shape returned by `public.my_friends()` — see migration
// `v1_follows_and_friend_activity`.
struct Friend: Codable, Identifiable, Hashable, Sendable {
    let userId: UUID
    let username: String
    let displayName: String?
    let avatarUrl: URL?
    let followedAt: Date

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId       = "user_id"
        case username
        case displayName  = "display_name"
        case avatarUrl    = "avatar_url"
        case followedAt   = "followed_at"
    }
}

// Mirrors the row shape returned by `public.search_profiles(text, int)`.
struct ProfileSearchResult: Codable, Identifiable, Hashable, Sendable {
    let userId: UUID
    let username: String
    let displayName: String?
    let avatarUrl: URL?
    var isFollowing: Bool

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId       = "user_id"
        case username
        case displayName  = "display_name"
        case avatarUrl    = "avatar_url"
        case isFollowing  = "is_following"
    }
}
