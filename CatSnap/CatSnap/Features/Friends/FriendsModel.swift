import Foundation

// View-model for screens that show the user's friends list and recent
// friend activity. Stateless graph operations live in `FriendsGraph` —
// this type owns only the `@Observable` state and the local-cache mirror
// after `block(...)` so the UI updates without a re-fetch.
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
            friends = try await FriendsGraph.myFriends()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadActivity(limit: Int = 50) async {
        isLoadingActivity = true
        defer { isLoadingActivity = false }
        do {
            activity = try await FriendsGraph.friendActivity(limit: limit)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func block(userId: UUID) async throws {
        try await FriendsGraph.block(userId: userId)
        // The read RPCs filter blocked pairs server-side; mirror locally
        // so the UI updates immediately without a refetch.
        activity.removeAll { $0.userId == userId }
        friends.removeAll { $0.userId == userId }
    }
}
