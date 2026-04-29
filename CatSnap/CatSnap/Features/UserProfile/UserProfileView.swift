import SwiftUI

struct UserProfileView: View {
    @Environment(AuthSession.self) private var session
    @State private var model = UserProfileModel()
    @State private var isEditPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("sign out") {
                        Task { try? await session.signOut() }
                    }
                    .font(.Brand.jakarta(.medium, size: 14))
                    .foregroundStyle(Color.stone)
                }
            }
            .task { await model.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView().tint(Color.coral)
        case .failed(let message):
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
        case .loaded(let profile, let sightings, let catCount):
            loadedView(profile: profile, sightings: sightings, catCount: catCount)
        }
    }

    private func loadedView(profile: Profile, sightings: [Sighting], catCount: Int) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                header(profile: profile)
                statsRow(catCount: catCount, sightingCount: sightings.count)
                editButton(profile: profile)
                sightingsGrid(sightings: sightings)
            }
            .padding(.top, 24)
        }
    }

    private func header(profile: Profile) -> some View {
        VStack(spacing: 12) {
            Color.creamDeep
                .frame(width: 88, height: 88)
                .clipShape(.circle)
                .overlay {
                    if let url = profile.avatarUrl {
                        AsyncCatImage(url: url)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.stone)
                    }
                }
                .clipShape(.circle)
                .overlay(Circle().stroke(Color.stoneLight, lineWidth: 1))

            VStack(spacing: 2) {
                Text(profile.displayName ?? profile.username)
                    .font(.Brand.jakarta(.bold, size: 20))
                    .foregroundStyle(Color.ink)
                Text("@\(profile.username)")
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.stone)
            }
        }
    }

    private func statsRow(catCount: Int, sightingCount: Int) -> some View {
        HStack(spacing: 24) {
            stat(value: "\(catCount)",     label: "cats")
            stat(value: "\(sightingCount)", label: "sightings")
        }
        .padding(.vertical, 12)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.Brand.jakarta(.bold, size: 22))
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.Brand.jakarta(.regular, size: 12))
                .foregroundStyle(Color.stone)
        }
    }

    private func editButton(profile: Profile) -> some View {
        Button {
            isEditPresented = true
        } label: {
            Text("edit profile")
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.creamSoft, in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stoneLight, lineWidth: 1))
        }
        .padding(.horizontal, 24)
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
    }

    private func sightingsGrid(sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("my sightings")
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 24)

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
        .padding(.top, 12)
    }

    private var emptySightings: some View {
        VStack(spacing: 12) {
            CatWindowMark(size: 80, showSill: false)
                .opacity(0.5)
            Text("no sightings yet")
                .font(.Brand.jakarta(.medium, size: 14))
                .foregroundStyle(Color.stone)
            Text("tap the + tab to log one.")
                .font(.Brand.jakarta(.regular, size: 12))
                .foregroundStyle(Color.stone.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
