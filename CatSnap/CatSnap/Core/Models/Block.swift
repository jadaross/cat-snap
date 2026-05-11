import Foundation

// Mirrors `public.blocks`. Writes go through FriendsModel.block /
// .unblock; reads aren't needed in v1 because blocking is symmetric
// and the RPCs filter server-side.
struct Block: Codable, Hashable, Sendable {
    let blockerId: UUID
    let blockedId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case blockerId = "blocker_id"
        case blockedId = "blocked_id"
        case createdAt = "created_at"
    }
}
