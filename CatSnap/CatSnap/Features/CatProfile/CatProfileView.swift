import SwiftUI

struct CatProfileView: View {
    @Environment(\.dismiss) private var dismiss
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
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
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

    // Source: `CatSnap App.html` lines 815–901 (CatProfile screen).
    private func loadedView(cat: Cat, sightings: [Sighting]) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    hero(cat: cat, sightings: sightings)
                    infoBody(cat: cat, sightings: sightings)
                }
            }
            stickyCTA
        }
    }

    private func hero(cat: Cat, sightings: [Sighting]) -> some View {
        let photoUrl = cat.primaryPhotoUrl ?? sightings.first?.photoUrl

        return ZStack(alignment: .top) {
            AsyncCatImage(url: photoUrl)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .clipped()

            // Gradient overlays — top for the back button, bottom for the title block.
            LinearGradient(
                colors: [Color.ink.opacity(0.4), .clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.3)
            )
            .frame(height: 320)
            .allowsHitTesting(false)

            LinearGradient(
                colors: [.clear, Color.ink.opacity(0.5)],
                startPoint: UnitPoint(x: 0.5, y: 0.6),
                endPoint: .bottom
            )
            .frame(height: 320)
            .allowsHitTesting(false)

            VStack {
                heroTopBar
                Spacer(minLength: 0)
                heroTitleBlock(cat: cat, sightings: sightings)
            }
            .frame(height: 320)
        }
        .frame(height: 320)
    }

    private var heroTopBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.creamSoft)
                    .frame(width: 40, height: 40)
                    .background(Color.ink.opacity(0.4), in: .circle)
                    .background(.ultraThinMaterial, in: .circle)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.creamSoft)
                .frame(width: 40, height: 40)
                .background(Color.ink.opacity(0.4), in: .circle)
                .background(.ultraThinMaterial, in: .circle)
        }
        .padding(.horizontal, 16)
        .padding(.top, 56) // safe-area approximation; exact layout via .ignoresSafeArea(.top)
    }

    private func heroTitleBlock(cat: Cat, sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            heroBadge(cat: cat, sightingCount: sightings.count)
            Text((cat.name ?? "unnamed").lowercased())
                .font(.Brand.frauncesBlackItalic(size: 44))
                .tracking(-1.6)
                .foregroundStyle(Color.creamSoft)
                .lineLimit(1)
            heroSubtitle(sightings: sightings)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func heroBadge(cat: Cat, sightingCount: Int) -> some View {
        let style = badgeStyle(for: cat.rarity)
        return Text(style.label(spots: sightingCount))
            .font(.Brand.jakarta(.bold, size: 10))
            .tracking(0.4)
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(style.background, in: .capsule)
    }

    @ViewBuilder
    private func heroSubtitle(sightings: [Sighting]) -> some View {
        if let text = heroSubtitleText(sightings: sightings) {
            Text(text)
                .font(.Brand.jakarta(.bold, size: 13))
                .foregroundStyle(Color.creamSoft.opacity(0.85))
                .lineLimit(1)
        }
    }

    private func heroSubtitleText(sightings: [Sighting]) -> String? {
        guard let last = sightings.first else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let when = formatter.localizedString(for: last.seenAt, relativeTo: Date())
        let location = last.locationLabel.map { "\($0.lowercased()) regular · " } ?? ""
        return "\(location)last seen \(when)"
    }

    // Body card with stats / mini-map / sightings grid sliding up over the hero.
    private func infoBody(cat: Cat, sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            statsRow(sightings: sightings, cat: cat)
            sightingsGrid(sightings: sightings)
            Color.clear.frame(height: 96) // breathing room behind sticky CTA
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 22, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 22
            )
            .fill(Color.cream)
        )
        .offset(y: -14)
    }

    private func statsRow(sightings: [Sighting], cat: Cat) -> some View {
        HStack(spacing: 8) {
            statCard(
                value: "\(sightings.count)",
                label: "SIGHTINGS"
            )
            statCard(
                value: uniqueSpotterValue(sightings: sightings),
                label: "SPOTTERS"
            )
            statCard(
                value: knownForValue(sightings: sightings, cat: cat),
                label: "KNOWN FOR"
            )
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.Brand.frauncesBlackItalic(size: 26))
                .tracking(-0.6)
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.Brand.mono(size: 9))
                .tracking(0.8)
                .foregroundStyle(Color.stone)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.creamSoft, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
    }

    private func uniqueSpotterValue(sightings: [Sighting]) -> String {
        let unique = Set(sightings.map { $0.userId }).count
        return "\(unique)"
    }

    private func knownForValue(sightings: [Sighting], cat: Cat) -> String {
        let earliest = sightings.last?.seenAt ?? cat.createdAt
        let days = Calendar.current.dateComponents([.day], from: earliest, to: Date()).day ?? 0
        return "\(max(days, 1))d"
    }

    private func sightingsGrid(sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("recent sightings")
                    .font(.Brand.frauncesBlackItalic(size: 20))
                    .tracking(-0.5)
                    .foregroundStyle(Color.ink)
                Spacer()
                if sightings.count > 6 {
                    Text("SEE ALL")
                        .font(.Brand.mono(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(Color.stone)
                }
            }

            if sightings.isEmpty {
                Text("no sightings yet")
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.stone)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                    spacing: 6
                ) {
                    ForEach(sightings.prefix(9)) { sighting in
                        SightingThumbnail(photoUrl: sighting.photoUrl, seenAt: sighting.seenAt)
                    }
                }
            }
        }
    }

    // Sticky bottom action — coral "I spotted them!" + heart side-button.
    private var stickyCTA: some View {
        HStack(spacing: 8) {
            Button { isSubmitPresented = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("I spotted them!")
                        .font(.Brand.jakarta(.bold, size: 15))
                }
                .foregroundStyle(Color.creamSoft)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.coral, in: .rect(cornerRadius: 14))
            }

            Button { /* heart / favourite — wired in v2 */ } label: {
                Image(systemName: "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 52, height: 52)
                    .background(Color.creamSoft, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 10)
        .background(
            LinearGradient(colors: [.clear, Color.cream.opacity(0.95)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private struct BadgeStyle {
        let foreground: Color
        let background: Color
        let prefix: String

        func label(spots: Int) -> String {
            let count = spots > 0 ? " · \(spots) SPOTS" : ""
            return "\(prefix)\(count)"
        }
    }

    private func badgeStyle(for rarity: Cat.Rarity) -> BadgeStyle {
        switch rarity {
        case .legendary: return BadgeStyle(foreground: .ink, background: .streetlampYellow, prefix: "★ LEGENDARY")
        case .rare:      return BadgeStyle(foreground: .creamSoft, background: .coral, prefix: "RARE")
        case .uncommon:  return BadgeStyle(foreground: .sage, background: .sage.opacity(0.25), prefix: "UNCOMMON")
        case .common:    return BadgeStyle(foreground: .stone, background: .creamDeep.opacity(0.85), prefix: "COMMON")
        }
    }
}
