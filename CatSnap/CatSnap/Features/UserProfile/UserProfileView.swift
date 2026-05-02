import SwiftUI

// You-tab profile, mirroring `CatSnap App.html` lines 1004–1154: coral
// header with stats, 4-column awards grid, ink streak card, friends
// section (avatar row + Add button + recent activity), then the user's
// own sightings grid.
struct UserProfileView: View {
    @Environment(AuthSession.self) private var session
    @State private var model = UserProfileModel()
    @State private var friendsModel = FriendsModel()
    @State private var isEditPresented = false
    @State private var isSettingsPresented = false
    @State private var path = NavigationPath()

    enum Route: Hashable {
        case addFriends
        case friendsActivity
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                Color.cream.ignoresSafeArea()
                content
            }
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(edges: .top)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .addFriends:
                    AddFriendsView()
                case .friendsActivity:
                    FriendsActivityView()
                }
            }
            .navigationDestination(for: UUID.self) { catId in
                CatProfileView(catId: catId)
            }
            .task {
                async let profile: Void = model.load()
                async let friends: Void = friendsModel.loadFriends()
                async let activity: Void = friendsModel.loadActivity(limit: 6)
                _ = await (profile, friends, activity)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView().tint(Color.coral)
        case .failed(let message):
            failureView(message)
        case .loaded(let profile, let sightings, let catCount):
            loadedView(profile: profile, sightings: sightings, catCount: catCount)
        }
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("couldn't load profile")
                .font(.Brand.jakarta(.semibold, size: 16))
                .foregroundStyle(Color.ink)
            Text(message)
                .font(.Brand.jakarta(.regular, size: 13))
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("retry") { Task { await model.load() } }
                .font(.Brand.jakarta(.medium, size: 14))
                .foregroundStyle(Color.coral)
        }
    }

    private func loadedView(profile: Profile, sightings: [Sighting], catCount: Int) -> some View {
        let streak = currentStreak(sightings: sightings)
        let awards = earnedAwards(sightings: sightings, catCount: catCount, streak: streak)

        return ScrollView {
            VStack(spacing: 0) {
                coralHeader(
                    profile: profile,
                    sightingCount: sightings.count,
                    catCount: catCount,
                    streak: streak,
                    awardCount: awards.filter(\.earned).count
                )

                awardsSection(awards: awards)
                    .padding(.top, 18)

                streakCard(streak: streak, sightings: sightings)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                friendsSection
                    .padding(.top, 18)

                mySightingsSection(sightings: sightings)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $isEditPresented) {
            EditProfileSheet(profile: profile) { update in
                if let avatar = update.avatar {
                    try await model.uploadAvatar(avatar)
                }
                if (profile.displayName ?? "") != update.displayName {
                    try await model.updateDisplayName(update.displayName)
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheet()
        }
    }

    // MARK: - Coral header

    private func coralHeader(
        profile: Profile,
        sightingCount: Int,
        catCount: Int,
        streak: Int,
        awardCount: Int
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Wordmark(size: 20)
                    .colorInvert()
                Spacer()
                Menu {
                    Button("edit profile") { isEditPresented = true }
                    Button("settings") { isSettingsPresented = true }
                    Button("sign out", role: .destructive) {
                        Task { try? await session.signOut() }
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.creamSoft)
                        .frame(width: 36, height: 36)
                        .background(Color.creamSoft.opacity(0.2), in: .circle)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
            .padding(.bottom, 14)

            HStack(alignment: .top, spacing: 14) {
                avatar(profile: profile)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayName ?? profile.username)
                        .font(.Brand.frauncesBlackItalic(size: 28))
                        .tracking(-0.8)
                        .foregroundStyle(Color.creamSoft)
                        .lineLimit(1)

                    Text("@\(profile.username)")
                        .font(.Brand.mono(size: 11))
                        .tracking(0.6)
                        .foregroundStyle(Color.creamSoft.opacity(0.85))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)

            // Stats row
            HStack(spacing: 0) {
                statCell(value: "\(sightingCount)", label: "SIGHTINGS", showDivider: true)
                statCell(value: "\(catCount)", label: "CATS", showDivider: true)
                statCell(value: "\(streak)", label: "STREAK", showDivider: true)
                statCell(value: "\(awardCount)", label: "AWARDS", showDivider: false)
            }
            .padding(.vertical, 10)
            .background(Color.ink.opacity(0.15), in: .rect(cornerRadius: 14))
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.coral.ignoresSafeArea(edges: .top))
    }

    private func avatar(profile: Profile) -> some View {
        ZStack {
            Color.creamSoft
            if let url = profile.avatarUrl {
                AsyncCatImage(url: url)
            } else {
                CatWindowMark(size: 60, showSill: false)
            }
        }
        .frame(width: 76, height: 76)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: Color.ink.opacity(0.15), radius: 6, y: 4)
    }

    private func statCell(value: String, label: String, showDivider: Bool) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.Brand.frauncesBlackItalic(size: 22))
                    .foregroundStyle(Color.creamSoft)
                Text(label)
                    .font(.Brand.mono(size: 9))
                    .tracking(0.6)
                    .foregroundStyle(Color.creamSoft.opacity(0.8))
            }
            .frame(maxWidth: .infinity)

            if showDivider {
                Rectangle()
                    .fill(Color.creamSoft.opacity(0.18))
                    .frame(width: 1, height: 28)
            }
        }
    }

    // MARK: - Awards

    private func awardsSection(awards: [Award]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("awards")
                    .font(.Brand.frauncesBlackItalic(size: 22))
                    .tracking(-0.6)
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("\(awards.filter(\.earned).count) / \(awards.count)")
                    .font(.Brand.mono(size: 10))
                    .tracking(0.8)
                    .foregroundStyle(Color.stone)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(awards) { award in
                    AwardTile(award: award)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Streak card

    private func streakCard(streak: Int, sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CURRENT STREAK")
                .font(.Brand.mono(size: 10))
                .tracking(1.4)
                .foregroundStyle(Color.streetlampYellow)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(streak)")
                    .font(.Brand.frauncesBlackItalic(size: 56))
                    .tracking(-2)
                    .foregroundStyle(Color.creamSoft)
                Text(streak == 1 ? "day" : "days")
                    .font(.Brand.jakarta(.bold, size: 16))
                    .foregroundStyle(Color.creamSoft)
            }
            .padding(.top, 6)

            HStack(spacing: 4) {
                ForEach(Array(streakHeatmap(sightings: sightings).enumerated()), id: \.offset) { _, active in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(active ? Color.streetlampYellow : Color.creamSoft.opacity(0.15))
                        .frame(maxWidth: .infinity)
                        .frame(height: 18)
                }
            }
            .padding(.top, 12)

            HStack {
                Text("2 WEEKS AGO")
                    .font(.Brand.mono(size: 9))
                    .tracking(0.5)
                    .foregroundStyle(Color.creamSoft.opacity(0.6))
                Spacer()
                Text("TODAY")
                    .font(.Brand.mono(size: 9))
                    .tracking(0.5)
                    .foregroundStyle(Color.streetlampYellow)
            }
            .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ink, in: .rect(cornerRadius: 16))
    }

    // MARK: - Friends section (CatSnap App.html lines 1101–1154)

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    path.append(Route.friendsActivity)
                } label: {
                    HStack(spacing: 6) {
                        Text("friends")
                            .font(.Brand.frauncesBlackItalic(size: 22))
                            .tracking(-0.6)
                            .foregroundStyle(Color.ink)
                        Text("· \(friendsModel.friends.count)")
                            .font(.Brand.mono(size: 11))
                            .tracking(0.8)
                            .foregroundStyle(Color.stone)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Color.stone)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button { path.append(Route.addFriends) } label: {
                    HStack(spacing: 4) {
                        Text("+").font(.system(size: 14, weight: .light))
                        Text("Add").font(.Brand.jakarta(.bold, size: 12))
                    }
                    .foregroundStyle(Color.creamSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.coral, in: .capsule)
                }
                .buttonStyle(.plain)
            }

            if friendsModel.friends.isEmpty {
                emptyFriendsCard
            } else {
                friendsAvatarRow
                recentFriendActivity
            }
        }
        .padding(.horizontal, 16)
    }

    private var friendsAvatarRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(friendsModel.friends) { friend in
                    VStack(spacing: 4) {
                        ZStack {
                            Color.creamDeep
                            if let url = friend.avatarUrl {
                                AsyncCatImage(url: url)
                            } else {
                                CatWindowMark(size: 44, showSill: false)
                            }
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.creamSoft, lineWidth: 2))

                        Text(friend.displayName ?? friend.username)
                            .font(.Brand.jakarta(.bold, size: 11))
                            .foregroundStyle(Color.ink)
                            .lineLimit(1)
                            .frame(maxWidth: 64)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentFriendActivity: some View {
        if !friendsModel.activity.isEmpty {
            HStack {
                Text("RECENT")
                    .font(.Brand.mono(size: 10))
                    .tracking(1.2)
                    .foregroundStyle(Color.stone)
                Spacer()
                Button { path.append(Route.friendsActivity) } label: {
                    HStack(spacing: 2) {
                        Text("See all").font(.Brand.jakarta(.bold, size: 11))
                        Text("›").font(.system(size: 12))
                    }
                    .foregroundStyle(Color.coralDeep)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)

            VStack(spacing: 8) {
                ForEach(friendsModel.activity.prefix(2)) { sighting in
                    FriendActivityRow(sighting: sighting) {
                        if let id = sighting.catId { path.append(id) }
                    }
                }
            }
        }
    }

    private var emptyFriendsCard: some View {
        Button { path.append(Route.addFriends) } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.stone)
                VStack(alignment: .leading, spacing: 2) {
                    Text("no friends yet")
                        .font(.Brand.jakarta(.bold, size: 13))
                        .foregroundStyle(Color.ink)
                    Text("follow other spotters to see their cats here.")
                        .font(.Brand.jakarta(.regular, size: 11))
                        .foregroundStyle(Color.stone)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Color.stone)
            }
            .padding(12)
            .background(Color.creamSoft, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - My sightings (kept while Phase 8 friends feed is deferred)

    private func mySightingsSection(sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("my sightings")
                    .font(.Brand.frauncesBlackItalic(size: 20))
                    .tracking(-0.5)
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            .padding(.horizontal, 16)

            if sightings.isEmpty {
                emptySightings
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3),
                    spacing: 4
                ) {
                    ForEach(sightings) { sighting in
                        SightingThumbnail(photoUrl: sighting.photoUrl, seenAt: sighting.seenAt)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var emptySightings: some View {
        VStack(spacing: 12) {
            CatWindowMark(size: 80, showSill: false)
                .opacity(0.5)
            Text("no sightings yet")
                .font(.Brand.jakarta(.medium, size: 14))
                .foregroundStyle(Color.stone)
            Text("tap Snap to log one.")
                .font(.Brand.jakarta(.regular, size: 12))
                .foregroundStyle(Color.stone.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Streak / heatmap helpers

    private func currentStreak(sightings: [Sighting]) -> Int {
        let cal = Calendar.current
        let activeDays = Set(sightings.map { cal.startOfDay(for: $0.seenAt) })
        let today = cal.startOfDay(for: Date())

        // Anchor the count on the most recent active day in {today, yesterday}
        // so the streak doesn't reset to zero the moment the calendar flips
        // before the user has logged a sighting today.
        var endDay = today
        if !activeDays.contains(endDay) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                  activeDays.contains(yesterday) else { return 0 }
            endDay = yesterday
        }

        var streak = 0
        var day = endDay
        while activeDays.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private func streakHeatmap(sightings: [Sighting]) -> [Bool] {
        let cal = Calendar.current
        let activeDays = Set(sightings.map { cal.startOfDay(for: $0.seenAt) })
        let today = cal.startOfDay(for: Date())
        return (0..<17).map { offset in
            guard let day = cal.date(byAdding: .day, value: -(16 - offset), to: today) else { return false }
            return activeDays.contains(day)
        }
    }

    // MARK: - Awards (computed locally; backend awards table is v2 work)

    private func earnedAwards(sightings: [Sighting], catCount: Int, streak: Int) -> [Award] {
        let totalSightings = sightings.count
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let spottedToday = sightings.contains { cal.isDate($0.seenAt, inSameDayAs: today) }
        let nightOwl = sightings.contains { sighting in
            let h = cal.component(.hour, from: sighting.seenAt)
            return h < 6 || h >= 22
        }

        return [
            Award(emoji: "🏅", label: "First Snap", rare: false, earned: totalSightings >= 1),
            Award(emoji: "🔥", label: "10-day streak", rare: false, earned: streak >= 10),
            Award(emoji: "★", label: "Legend", rare: true, earned: totalSightings >= 50),
            Award(emoji: "🌙", label: "Night owl", rare: false, earned: nightOwl),
            Award(emoji: "📚", label: "20 cats", rare: false, earned: catCount >= 20),
            Award(emoji: "🎯", label: "Today's snap", rare: false, earned: spottedToday),
            Award(emoji: "🤝", label: "5 cats", rare: false, earned: catCount >= 5),
            Award(emoji: "🌧", label: "30 sightings", rare: false, earned: totalSightings >= 30),
            Award(emoji: "?", label: "50 cats", rare: false, earned: catCount >= 50),
            Award(emoji: "?", label: "100 day", rare: true, earned: streak >= 100),
            Award(emoji: "?", label: "Mystery", rare: false, earned: false),
            Award(emoji: "?", label: "???", rare: false, earned: false),
        ]
    }
}

private struct Award: Identifiable {
    let id = UUID()
    let emoji: String
    let label: String
    let rare: Bool
    let earned: Bool
}

private struct AwardTile: View {
    let award: Award

    var body: some View {
        VStack(spacing: 2) {
            Text(award.earned ? award.emoji : "?")
                .font(.system(size: 22))
                .opacity(award.earned ? 1 : 0.4)
            Text(award.label)
                .font(.Brand.jakarta(.bold, size: 8))
                .tracking(0.2)
                .foregroundStyle(award.earned ? Color.ink : Color.stone)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(background, in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(award.rare && award.earned ? Color.ink : Color.stoneLight, lineWidth: 1)
        )
        .shadow(
            color: award.rare && award.earned ? Color.ink.opacity(0.85) : .clear,
            radius: 0, x: 2, y: 2
        )
        .opacity(award.earned ? 1 : 0.5)
    }

    private var background: Color {
        if !award.earned { return Color.creamDeep }
        if award.rare    { return Color.streetlampYellow }
        return Color.creamSoft
    }
}
