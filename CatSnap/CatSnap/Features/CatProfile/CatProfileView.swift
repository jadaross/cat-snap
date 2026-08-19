import SwiftUI

struct CatProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: CatProfileModel
    @State private var isSubmitPresented = false
    @State private var isSpotConfirmPresented = false
    @State private var reportTarget: ReportTarget?
    @State private var statDetail: StatDetail?
    @State private var isTerritoryMapPresented = false

    /// Which stat tile was tapped. Presented as a sheet rather than a push:
    /// all three NavigationStacks that host this screen (MapView,
    /// GuideListView, UserProfileView) already register a
    /// `.navigationDestination(for: UUID.self)` pointing back here, so a
    /// second UUID-keyed destination would collide.
    private enum StatDetail: String, Identifiable, Hashable {
        case sightings, spotters, firstSighting
        var id: String { rawValue }
    }

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
        .sheet(isPresented: $isSpotConfirmPresented) {
            SpotConfirmSheet(
                catId: model.catId,
                catName: currentCatName
            )
        }
        .sheet(item: $reportTarget) { target in
            ReportSheet(target: target)
        }
        .sheet(item: $statDetail) { detail in
            statDetailSheet(detail)
        }
        .sheet(isPresented: $isTerritoryMapPresented) {
            if case .loaded(let cat, let sightings) = model.state {
                CatTerritoryMapSheet(catName: cat.name, sightings: sightings)
            }
        }
    }

    @ViewBuilder
    private func statDetailSheet(_ detail: StatDetail) -> some View {
        if case .loaded(let cat, let sightings) = model.state {
            switch detail {
            case .sightings:
                CatSightingsSheet(catName: cat.name, sightings: sightings)
            case .spotters:
                CatSpottersSheet(sightings: sightings)
            case .firstSighting:
                // Loaded seen_at DESC, so the earliest is last.
                FirstSightingSheet(catName: cat.name, sighting: sightings.last)
            }
        }
    }

    /// Reach back into the loaded state to surface the cat name to the
    /// SpotConfirmSheet — keeps the sheet decoupled from the view-model.
    private var currentCatName: String? {
        if case .loaded(let cat, _) = model.state { return cat.name }
        return nil
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
    private func loadedView(cat: Cat, sightings: [CatSighting]) -> some View {
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

    private func hero(cat: Cat, sightings: [CatSighting]) -> some View {
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
            Menu {
                Button("Report this cat", role: .destructive) {
                    reportTarget = .cat(model.catId)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.creamSoft)
                    .frame(width: 40, height: 40)
                    .background(Color.ink.opacity(0.4), in: .circle)
                    .background(.ultraThinMaterial, in: .circle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56) // safe-area approximation; exact layout via .ignoresSafeArea(.top)
    }

    private func heroTitleBlock(cat: Cat, sightings: [CatSighting]) -> some View {
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
    private func heroSubtitle(sightings: [CatSighting]) -> some View {
        if let text = heroSubtitleText(sightings: sightings) {
            Text(text)
                .font(.Brand.jakarta(.bold, size: 13))
                .foregroundStyle(Color.creamSoft.opacity(0.85))
                .lineLimit(1)
        }
    }

    private func heroSubtitleText(sightings: [CatSighting]) -> String? {
        guard let last = sightings.first else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let when = formatter.localizedString(for: last.seenAt, relativeTo: Date())
        let location = last.locationLabel.map { "\($0.lowercased()) regular · " } ?? ""
        return "\(location)last seen \(when)"
    }

    // Body card with stats / mini-map / sightings grid sliding up over the hero.
    private func infoBody(cat: Cat, sightings: [CatSighting]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            statsRow(sightings: sightings, cat: cat)
            territorySection(sightings: sightings)
            sightingsGrid(sightings: sightings)
            Color.clear.frame(height: 144) // breathing room behind sticky CTA (two-button stack)
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

    private func statsRow(sightings: [CatSighting], cat: Cat) -> some View {
        HStack(spacing: 8) {
            statCard(
                value: "\(sightings.count)",
                label: "SIGHTINGS",
                isEnabled: !sightings.isEmpty
            ) { statDetail = .sightings }

            statCard(
                value: uniqueSpotterValue(sightings: sightings),
                label: "SPOTTERS",
                isEnabled: !sightings.isEmpty
            ) { statDetail = .spotters }

            // Was labelled KNOWN FOR over a duration ("42d"), which described
            // neither a thing the cat is known for nor the first-sighting
            // detail behind the tap. A date says both.
            statCard(
                value: firstSeenValue(sightings: sightings, cat: cat),
                label: "FIRST SEEN",
                isEnabled: !sightings.isEmpty
            ) { statDetail = .firstSighting }
        }
    }

    private func statCard(
        value: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.Brand.frauncesBlackItalic(size: 26))
                    .tracking(-0.6)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.Brand.mono(size: 9))
                    .tracking(0.8)
                    .foregroundStyle(Color.stone)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.creamSoft, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
            // Deliberately not coral — three coral tiles would compete with
            // the sticky CTA below them.
            .overlay(alignment: .topTrailing) {
                if isEnabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.stone.opacity(0.6))
                        .padding(7)
                }
            }
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func uniqueSpotterValue(sightings: [CatSighting]) -> String {
        let unique = Set(sightings.map { $0.userId }).count
        return "\(unique)"
    }

    private func firstSeenValue(sightings: [CatSighting], cat: Cat) -> String {
        let earliest = sightings.last?.seenAt ?? cat.createdAt
        let formatter = DateFormatter()
        // Drop the year for same-year sightings — "3 Mar" reads better than
        // "3 Mar 2026" in a 26pt display face inside a third of the width.
        let sameYear = Calendar.current.isDate(earliest, equalTo: Date(), toGranularity: .year)
        formatter.setLocalizedDateFormatFromTemplate(sameYear ? "d MMM" : "MMM yy")
        return formatter.string(from: earliest)
    }

    @ViewBuilder
    private func territorySection(sightings: [CatSighting]) -> some View {
        if !sightings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("where they hang out")
                        .font(.Brand.frauncesBlackItalic(size: 20))
                        .tracking(-0.5)
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text(territoryCaption(sightings: sightings))
                        .font(.Brand.mono(size: 9))
                        .tracking(0.8)
                        .foregroundStyle(Color.stone)
                }

                Button { isTerritoryMapPresented = true } label: {
                    CatTerritoryMap(sightings: sightings)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.stoneLight, lineWidth: 1)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.ink)
                                .frame(width: 28, height: 28)
                                .background(Color.creamSoft, in: .circle)
                                .overlay(Circle().stroke(Color.stoneLight, lineWidth: 1))
                                .padding(8)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "open the full map"))
            }
        }
    }

    private func territoryCaption(sightings: [CatSighting]) -> String {
        let places = Set(sightings.compactMap { $0.locationLabel?.lowercased() }).count
        let spots = sightings.count == 1
            ? String(localized: "1 SPOT")
            : String(localized: "\(sightings.count) SPOTS")
        guard places > 1 else { return spots }
        return spots + String(localized: " ACROSS \(places) PLACES")
    }

    private func sightingsGrid(sightings: [CatSighting]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("recent sightings")
                    .font(.Brand.frauncesBlackItalic(size: 20))
                    .tracking(-0.5)
                    .foregroundStyle(Color.ink)
                Spacer()
                if sightings.count > 6 {
                    // Was a bare Text pretending to be a button.
                    Button { statDetail = .sightings } label: {
                        Text("SEE ALL")
                            .font(.Brand.mono(size: 10))
                            .tracking(0.8)
                            .foregroundStyle(Color.coral)
                    }
                    .buttonStyle(.plain)
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
                        Button { statDetail = .sightings } label: {
                            SightingThumbnail(photoUrl: sighting.photoUrl, seenAt: sighting.seenAt)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // Sticky bottom action — split CTA so the user can either log a quick
    // no-photo spot or open the full photo flow. Heart sits trailing on
    // the primary row.
    private var stickyCTA: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button { isSpotConfirmPresented = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("I spotted \(spottedActionName)")
                            .font(.Brand.jakarta(.bold, size: 15))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(Color.creamSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.coral, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    Task { await model.toggleFavorite() }
                } label: {
                    Image(systemName: model.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(model.isFavorite ? Color.coral : Color.ink)
                        .frame(width: 52, height: 52)
                        .background(Color.creamSoft, in: .rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.isFavorite)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.isFavorite ? "unfavourite" : "favourite")
            }

            Button { isSubmitPresented = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("upload a sighting of \(spottedActionName)")
                        .font(.Brand.jakarta(.bold, size: 14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.creamSoft, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 10)
        .background(
            LinearGradient(colors: [.clear, Color.cream.opacity(0.95)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    /// Lowercased cat name for in-button copy. Falls back to "this cat" so
    /// labels never read as "I spotted ".
    private var spottedActionName: String {
        let trimmed = (currentCatName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "this cat" : trimmed.lowercased()
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
