import SwiftUI

// Full Friends activity feed. Source: `CatSnap App.html` lines 1162–1253
// (Friends screen). Shows the friend stories row at the top and a
// chronological feed of the most recent sightings from people the user
// follows. Cards push to CatProfileView via the host NavigationStack.
struct FriendsActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model = FriendsModel()

    var body: some View {
        ZStack(alignment: .top) {
            Color.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 14) {
                        if !model.friends.isEmpty {
                            storiesRow
                        }
                        feed
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
        .task {
            async let friends: Void = model.loadFriends()
            async let activity: Void = model.loadActivity()
            _ = await (friends, activity)
        }
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
            Text("friends")
                .font(.Brand.frauncesBlackItalic(size: 30))
                .tracking(-1)
                .foregroundStyle(Color.ink)
            Spacer()
            NavigationLink(value: UserProfileView.Route.addFriends) {
                HStack(spacing: 4) {
                    Text("+").font(.system(size: 14, weight: .light))
                    Text("Add").font(.Brand.jakarta(.bold, size: 12))
                }
                .foregroundStyle(Color.creamSoft)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.coral, in: .capsule)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private var storiesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(model.friends) { friend in
                    VStack(spacing: 4) {
                        ZStack {
                            Color.creamDeep
                            if let url = friend.avatarUrl {
                                AsyncCatImage(url: url)
                            } else {
                                CatWindowMark(size: 48, showSill: false)
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.creamSoft, lineWidth: 2))

                        Text(friend.displayName ?? friend.username)
                            .font(.Brand.jakarta(.bold, size: 11))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                            .frame(maxWidth: 68)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var feed: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVITY")
                .font(.Brand.mono(size: 10))
                .tracking(1.2)
                .foregroundStyle(Color.stone)
                .padding(.horizontal, 16)

            if model.isLoadingActivity && model.activity.isEmpty {
                ProgressView().tint(Color.coral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if model.activity.isEmpty {
                emptyFeed
            } else {
                VStack(spacing: 10) {
                    ForEach(model.activity) { sighting in
                        FeedCard(sighting: sighting)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptyFeed: some View {
        VStack(spacing: 8) {
            CatWindowMark(size: 48, showSill: false).opacity(0.6)
            Text("no friend activity yet")
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(Color.ink)
            Text("once your friends start spotting, their snaps land here.")
                .font(.Brand.jakarta(.regular, size: 12))
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

private struct FeedCard: View {
    let sighting: NearbySighting

    var body: some View {
        // The card itself is non-tappable for this view; tapping the cat
        // photo navigates into CatProfileView via the parent stack.
        VStack(alignment: .leading, spacing: 0) {
            header
            photo
        }
        .background(Color.creamSoft, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
        .clipShape(.rect(cornerRadius: 14))
    }

    private var header: some View {
        HStack(spacing: 8) {
            avatar

            VStack(alignment: .leading, spacing: 1) {
                spottedLine
                Text(metaLine)
                    .font(.Brand.mono(size: 10))
                    .tracking(0.4)
                    .foregroundStyle(Color.stone)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var avatar: some View {
        ZStack {
            Color.ink
            if let url = sighting.avatarUrl {
                AsyncCatImage(url: url)
            } else {
                CatWindowMark(size: 26, showSill: false)
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(.rect(cornerRadius: 8))
    }

    private var spottedLine: some View {
        let who = sighting.displayName ?? sighting.username
        let cat = sighting.catName ?? "a cat"
        return (
            Text(who).bold()
            + Text(" spotted ")
            + Text(cat).bold()
        )
        .font(.Brand.jakarta(.regular, size: 13))
        .foregroundStyle(Color.ink)
        .lineLimit(1)
    }

    private var metaLine: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let when = formatter.localizedString(for: sighting.seenAt, relativeTo: Date())
        if let label = sighting.locationLabel, !label.isEmpty {
            return "\(label.uppercased()) · \(when.uppercased())"
        }
        return when.uppercased()
    }

    @ViewBuilder
    private var photo: some View {
        if let id = sighting.catId {
            NavigationLink(value: id) {
                AsyncCatImage(url: sighting.photoUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
            }
            .buttonStyle(.plain)
        } else {
            AsyncCatImage(url: sighting.photoUrl)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipped()
        }
    }
}
