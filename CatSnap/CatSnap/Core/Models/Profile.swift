import Foundation

struct Profile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var username: String
    var displayName: String?
    var avatarUrl: URL?
    var bio: String?
    var isAdmin: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName  = "display_name"
        case avatarUrl    = "avatar_url"
        case bio
        case isAdmin      = "is_admin"
        case createdAt    = "created_at"
    }
}
