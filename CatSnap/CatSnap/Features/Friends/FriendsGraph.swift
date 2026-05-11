import Foundation
import Supabase
import PostgREST

// Stateless data layer for the friends graph: follows, blocks, reports,
// search, and the read-side RPCs (`my_friends`, `friend_activity`,
// `search_profiles`). All four read RPCs filter blocked pairs server-side
// — clients don't need to re-derive that filter.
enum FriendsGraph {
    static func myFriends() async throws -> [Friend] {
        try await supabase
            .rpc("my_friends")
            .execute()
            .value
    }

    static func friendActivity(limit: Int = 50) async throws -> [NearbySighting] {
        try await supabase
            .rpc("friend_activity", params: ["p_limit": limit])
            .execute()
            .value
    }

    static func search(query: String, limit: Int = 20) async throws -> [ProfileSearchResult] {
        struct Params: Encodable { let p_query: String; let p_limit: Int }
        return try await supabase
            .rpc("search_profiles", params: Params(p_query: query, p_limit: limit))
            .execute()
            .value
    }

    static func follow(userId: UUID) async throws {
        let me = try await supabase.auth.session.user.id
        struct Row: Encodable { let follower_id: UUID; let followee_id: UUID }
        try await supabase
            .from("follows")
            .insert(Row(follower_id: me, followee_id: userId))
            .execute()
    }

    static func unfollow(userId: UUID) async throws {
        let me = try await supabase.auth.session.user.id
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: me)
            .eq("followee_id", value: userId)
            .execute()
    }

    static func block(userId: UUID) async throws {
        let me = try await supabase.auth.session.user.id
        struct Row: Encodable { let blocker_id: UUID; let blocked_id: UUID }
        try await supabase
            .from("blocks")
            .insert(Row(blocker_id: me, blocked_id: userId))
            .execute()
    }

    static func unblock(userId: UUID) async throws {
        let me = try await supabase.auth.session.user.id
        try await supabase
            .from("blocks")
            .delete()
            .eq("blocker_id", value: me)
            .eq("blocked_id", value: userId)
            .execute()
    }

    static func report(
        targetType: String,
        targetId: UUID,
        reason: String,
        details: String?
    ) async throws {
        let me = try await supabase.auth.session.user.id
        struct Row: Encodable {
            let reporter_id: UUID
            let target_type: String
            let target_id: UUID
            let reason: String
            let details: String?
        }
        try await supabase
            .from("reports")
            .insert(Row(
                reporter_id: me,
                target_type: targetType,
                target_id: targetId,
                reason: reason,
                details: details
            ))
            .execute()
    }
}
