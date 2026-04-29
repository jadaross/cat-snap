import SwiftUI

struct CatProfileView: View {
    @State private var model: CatProfileModel
    @State private var isSubmitPresented = false

    init(catId: UUID) {
        _model = State(initialValue: CatProfileModel(catId: catId))
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .fullScreenCover(isPresented: $isSubmitPresented) {
            SubmitView(prefilledCatId: model.catId)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView().tint(Color.coral)
        case .failed(let message):
            failureView(message)
        case .loaded(let cat, let sightings):
            loadedView(cat: cat, sightings: sightings)
        }
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("couldn't load cat")
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

    private func loadedView(cat: Cat, sightings: [Sighting]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                hero(cat: cat, sightings: sightings)
                infoCard(cat: cat, sightings: sightings)
                sightingsGrid(sightings: sightings)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private func hero(cat: Cat, sightings: [Sighting]) -> some View {
        let photoUrl = cat.primaryPhotoUrl ?? sightings.first?.photoUrl
        // Use a container of fixed size so the AsyncCatImage's aspect-fill
        // can't grow the layout when the photo finishes loading.
        return Color.creamDeep
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .overlay {
                AsyncCatImage(url: photoUrl)
            }
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                RarityBadge(rarity: cat.rarity)
                    .padding(16)
            }
    }

    private func infoCard(cat: Cat, sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(cat.name ?? "unnamed cat")
                    .font(.Brand.jakarta(.bold, size: 24))
                    .foregroundStyle(Color.ink)
                if let lastLabel = sightings.first?.locationLabel {
                    Text("last seen · \(lastLabel)")
                        .font(.Brand.jakarta(.regular, size: 13))
                        .foregroundStyle(Color.stone)
                }
            }

            HStack(spacing: 24) {
                stat(label: "sightings", value: "\(sightings.count)")
                if let firstSeen = sightings.last?.seenAt {
                    stat(label: "first seen", value: firstSeen.formatted(.dateTime.month(.abbreviated).day()))
                }
                stat(label: "rarity", value: cat.rarity.label)
            }

            if let description = cat.description, !description.isEmpty {
                Text(description)
                    .font(.Brand.jakarta(.regular, size: 14))
                    .foregroundStyle(Color.ink.opacity(0.85))
            }

            Button {
                isSubmitPresented = true
            } label: {
                Text("i saw this cat")
                    .font(.Brand.jakarta(.semibold, size: 16))
                    .foregroundStyle(Color.creamSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.coral, in: .rect(cornerRadius: 10))
            }
        }
        .padding(20)
        .background(
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, topTrailing: 16))
                .fill(Color.creamSoft)
        )
        .padding(.top, -16)
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.Brand.jakarta(.bold, size: 18))
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.Brand.jakarta(.regular, size: 11))
                .foregroundStyle(Color.stone)
        }
    }

    private func sightingsGrid(sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("sightings")
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 20)

            if sightings.isEmpty {
                Text("no sightings yet")
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.stone)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
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
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 16)
        .background(Color.creamSoft)
    }
}

private extension Cat.Rarity {
    var label: String {
        switch self {
        case .common:    return "common"
        case .uncommon:  return "uncommon"
        case .rare:      return "rare"
        case .legendary: return "legendary"
        }
    }
}
