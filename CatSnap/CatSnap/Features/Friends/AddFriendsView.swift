import SwiftUI

// Search profiles + follow. Source: `CatSnap App.html` lines 1256–1314
// (AddFriends screen). The QR scan and share-invite quick actions from
// the design have been intentionally cut.
struct AddFriendsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var results: [ProfileSearchResult] = []
    @State private var isSearching = false
    @State private var error: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .top) {
            Color.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                searchBar
                resultsList
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.creamSoft, in: .circle)
                    .overlay(Circle().stroke(Color.stoneLight, lineWidth: 1))
            }
            Text("add friends")
                .font(.Brand.frauncesBlackItalic(size: 24))
                .tracking(-0.6)
                .foregroundStyle(Color.ink)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.stone)
            TextField("Search by username…", text: $query)
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: query) { _, newValue in
                    debounceSearch(newValue)
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.creamSoft, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var resultsList: some View {
        if query.isEmpty {
            emptyHint
        } else if isSearching && results.isEmpty {
            ProgressView().tint(Color.coral)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if results.isEmpty {
            VStack(spacing: 6) {
                Text("no spotters match \"\(query)\"")
                    .font(.Brand.jakarta(.semibold, size: 14))
                    .foregroundStyle(Color.ink)
                Text("usernames are case-insensitive.")
                    .font(.Brand.jakarta(.regular, size: 12))
                    .foregroundStyle(Color.stone)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(results) { profile in
                        ProfileRow(
                            profile: profile,
                            onFollow: { Task { await follow(profile) } },
                            onUnfollow: { Task { await unfollow(profile) } }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 8) {
            Text("RESULTS")
                .font(.Brand.mono(size: 10))
                .tracking(1.2)
                .foregroundStyle(Color.stone)
            Text("type a username to find a spotter.")
                .font(.Brand.jakarta(.regular, size: 13))
                .foregroundStyle(Color.stone)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 32)
    }

    private func debounceSearch(_ value: String) {
        searchTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
            isSearching = true
            do {
                results = try await FriendsGraph.search(query: trimmed)
                error = nil
            } catch {
                self.error = error.localizedDescription
            }
            isSearching = false
        }
    }

    private func follow(_ profile: ProfileSearchResult) async {
        do {
            try await FriendsGraph.follow(userId: profile.userId)
            updateRow(profile.userId, isFollowing: true)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func unfollow(_ profile: ProfileSearchResult) async {
        do {
            try await FriendsGraph.unfollow(userId: profile.userId)
            updateRow(profile.userId, isFollowing: false)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func updateRow(_ userId: UUID, isFollowing: Bool) {
        if let idx = results.firstIndex(where: { $0.userId == userId }) {
            results[idx].isFollowing = isFollowing
        }
    }
}

private struct ProfileRow: View {
    let profile: ProfileSearchResult
    let onFollow: () -> Void
    let onUnfollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName ?? profile.username)
                    .font(.Brand.jakarta(.bold, size: 14))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                Text("@\(profile.username)")
                    .font(.Brand.mono(size: 10))
                    .tracking(0.4)
                    .foregroundStyle(Color.stone)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            followButton
        }
        .padding(12)
        .background(Color.creamSoft, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
    }

    private var avatar: some View {
        ZStack {
            Color.creamDeep
            if let url = profile.avatarUrl {
                AsyncCatImage(url: url)
            } else {
                CatWindowMark(size: 36, showSill: false)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var followButton: some View {
        Button(action: profile.isFollowing ? onUnfollow : onFollow) {
            Text(profile.isFollowing ? "✓ Following" : "+ Add")
                .font(.Brand.jakarta(.bold, size: 12))
                .foregroundStyle(profile.isFollowing ? Color.ink : Color.creamSoft)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    profile.isFollowing ? Color.cream : Color.coral,
                    in: .capsule
                )
                .overlay(
                    Capsule().stroke(
                        profile.isFollowing ? Color.stoneLight : Color.clear,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }
}
