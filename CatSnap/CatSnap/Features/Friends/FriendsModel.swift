import Foundation
import Supabase
import PostgREST

@MainActor
@Observable
final class FriendsModel {
    var friends: [Friend] = []
    var activity: [NearbySighting] = []
    var isLoadingFriends = false
    var isLoadingActivity = false
    var error: String?

    func loadFriends() async {
        isLoadingFriends = true
        defer { isLoadingFriends = false }
        do {
            friends = try await supabase
                .rpc("my_friends")
                .execute()
                .value
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadActivity(limit: Int = 50) async {
        isLoadingActivity = true
        defer { isLoadingActivity = false }
        do {
            activity = try await supabase
                .rpc("friend_activity", params: ["p_limit": limit])
                .execute()
                .value
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func follow(userId: UUID) async throws {
        let me = try await supabase.auth.session.user.id
        struct Row: Encodable { let follower_id: UUID; let followee_id: UUID }
        try await supabase
            .from("follows")
            .insert(Row(follower_id: me, followee_id: userId))
            .execute()
    }

    func unfollow(userId: UUID) async throws {
        let me = try await supabase.auth.session.user.id
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: me)
            .eq("followee_id", value: userId)
            .execute()
    }

    func search(query: String, limit: Int = 20) async throws -> [ProfileSearchResult] {
        struct Params: Encodable { let p_query: String; let p_limit: Int }
        return try await supabase
            .rpc("search_profiles", params: Params(p_query: query, p_limit: limit))
            .execute()
            .value
    }
}
