import SwiftUI

// Field guide grid. Three columns of cats, with a quick-filter chip row up
// top and a filter icon that opens GuideFilterSheet. Active sheet criteria
// surface as removable chips above the grid. Every cell is tappable —
// locked silhouettes for not-yet-spotted cats are visual treatment only.
struct GuideListView: View {
    @Binding var exploreView: ExploreSubview
    @State private var model = GuideModel()
    @State private var path = NavigationPath()
    @State private var isFilterSheetPresented = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                SpotsHeader(view: $exploreView)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                header
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                quickFilterRow
                    .padding(.bottom, 6)

                if !activeChips.isEmpty {
                    activeFilterChips
                        .padding(.bottom, 6)
                }

                grid
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.cream)
            .navigationDestination(for: UUID.self) { catId in
                CatProfileView(catId: catId)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await model.load() }
            .sheet(isPresented: $isFilterSheetPresented) {
                GuideFilterSheet(initial: model.criteria) { next in
                    Task { await model.apply(next) }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .popExploreToRoot)) { _ in
                path = NavigationPath()
            }
        }
    }

    // MARK: - Header (title + spotted count)

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("your guide")
                .font(.Brand.frauncesBlackItalic(size: 22))
                .tracking(-0.6)
                .foregroundStyle(Color.ink)
            Spacer()
            Text("\(model.spottedCount) / \(model.totalCount)")
                .font(.Brand.mono(size: 10))
                .tracking(1)
                .foregroundStyle(Color.stone)
        }
    }

    // MARK: - Quick filter chips + filter icon

    private var quickFilterRow: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    quickChip("All",         isActive: model.quickFilter == .all)        { model.quickFilter = .all; reload() }
                    quickChip("♥ Favourites", isActive: model.quickFilter == .favorites)  { model.quickFilter = .favorites; reload() }
                    quickChip("Spotted",      isActive: model.quickFilter == .spotted)    { model.quickFilter = .spotted; reload() }
                }
                .padding(.leading, 16)
            }

            Button { isFilterSheetPresented = true } label: {
                Image(systemName: "line.3.horizontal.decrease.circle\(model.criteria.hasActiveFilters ? ".fill" : "")")
                    .font(.system(size: 22))
                    .foregroundStyle(model.criteria.hasActiveFilters ? Color.coral : Color.stone)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("more filters")
            .padding(.trailing, 12)
        }
    }

    private func quickChip(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.Brand.jakarta(.bold, size: 12))
                .foregroundStyle(isActive ? Color.creamSoft : Color.stone)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Capsule().fill(isActive ? Color.ink : Color.clear))
                .overlay(Capsule().stroke(isActive ? Color.clear : Color.stoneLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func reload() {
        Task { await model.load() }
    }

    // MARK: - Active-filter removable chips

    private var activeChips: [ActiveChip] {
        var chips: [ActiveChip] = []
        let c = model.criteria

        // Status chip — only when set via the sheet (quick-filter row already
        // surfaces .all / .notSpotted).
        if c.status == .spotted {
            chips.append(ActiveChip(id: "status") {
                model.criteria.status = .all
            } label: { Text("Spotted") })
        }

        if let rarities = c.rarities, !rarities.isEmpty {
            chips.append(ActiveChip(id: "rarity") {
                model.criteria.rarities = nil
            } label: {
                Text(rarities.map(\.rawValue).joined(separator: " · ").capitalized)
            })
        }

        if let tags = c.tags, !tags.isEmpty {
            chips.append(ActiveChip(id: "tags") {
                model.criteria.tags = nil
            } label: {
                Text(tags.joined(separator: " · "))
            })
        }

        if c.seenAfter != nil || c.seenBefore != nil {
            let label = formatTimeWindow(after: c.seenAfter, before: c.seenBefore)
            chips.append(ActiveChip(id: "time") {
                model.criteria.seenAfter = nil
                model.criteria.seenBefore = nil
            } label: { Text(label) })
        }

        if c.nearLat != nil {
            let radius = (c.nearRadiusM.map { Double($0) / 1000.0 }) ?? 0
            chips.append(ActiveChip(id: "area") {
                model.criteria.nearLat = nil
                model.criteria.nearLng = nil
                model.criteria.nearRadiusM = nil
            } label: { Text(String(format: "Within %.1f km", radius)) })
        }

        return chips
    }

    private struct ActiveChip: Identifiable {
        let id: String
        let onRemove: () -> Void
        let label: () -> Text
    }

    private var activeFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(activeChips) { chip in
                    HStack(spacing: 4) {
                        chip.label()
                            .font(.Brand.jakarta(.bold, size: 11))
                            .foregroundStyle(Color.creamSoft)
                        Button {
                            chip.onRemove()
                            reload()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(Color.creamSoft)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.coral))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func formatTimeWindow(after: Date?, before: Date?) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        switch (after, before) {
        case (let a?, let b?): return "\(f.string(from: a)) → \(f.string(from: b))"
        case (let a?, nil):    return "After \(f.string(from: a))"
        case (nil, let b?):    return "Before \(f.string(from: b))"
        case (nil, nil):       return ""
        }
    }

    // MARK: - Grid

    @ViewBuilder
    private var grid: some View {
        if model.isLoading && model.rows.isEmpty {
            ProgressView().tint(Color.coral)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.rows.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                    spacing: 8
                ) {
                    ForEach(model.rows) { row in
                        GuideCatCell(row: row)
                            .onTapGesture { path.append(row.catId) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            CatWindowMark(size: 56, showSill: false).opacity(0.6)
            Text(emptyTitle)
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(Color.ink)
            Text(emptySubtitle)
                .font(.Brand.jakarta(.regular, size: 12))
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyTitle: String {
        if model.quickFilter == .favorites {
            return "no favourites yet"
        }
        if model.quickFilter == .spotted {
            return "no cats spotted yet"
        }
        return "nothing matches your filters"
    }

    private var emptySubtitle: String {
        if model.quickFilter == .favorites {
            return "tap the heart on a cat to add them here."
        }
        if model.quickFilter == .spotted {
            return "snap one and it'll show up here."
        }
        return "try clearing some filters."
    }
}

private struct GuideCatCell: View {
    let row: GuideRow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                photo
                if let badge = rarityBadge {
                    Text(badge.label)
                        .font(.Brand.jakarta(.bold, size: 8))
                        .tracking(0.4)
                        .foregroundStyle(badge.foreground)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badge.background, in: .capsule)
                        .padding(6)
                }
                if row.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.coral)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.Brand.frauncesBlackItalic(size: 14))
                    .tracking(-0.3)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                if row.isSpotted {
                    Text("SPOTTED")
                        .font(.Brand.mono(size: 9))
                        .tracking(0.5)
                        .foregroundStyle(Color.stone)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.creamSoft, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
    }

    @ViewBuilder
    private var photo: some View {
        Color.creamDeep
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let url = row.recentPhotoUrl ?? row.primaryPhotoUrl {
                    AsyncCatImage(url: url)
                } else {
                    CatWindowMark(size: 40, showSill: false)
                        .opacity(0.5)
                }
            }
            .clipShape(.rect(topLeadingRadius: 12, topTrailingRadius: 12))
    }

    private var displayName: String {
        let name = (row.catName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "unnamed" }
        return name.lowercased()
    }

    private struct Badge {
        let label: String
        let background: Color
        let foreground: Color
    }

    private var rarityBadge: Badge? {
        switch row.rarity {
        case .legendary: return Badge(label: "★ LEGEND", background: .streetlampYellow, foreground: .ink)
        case .rare:      return Badge(label: "RARE", background: .coral, foreground: .creamSoft)
        case .uncommon:  return Badge(label: "UNCOMMON", background: .sage.opacity(0.3), foreground: .sage)
        case .common:    return nil
        }
    }
}
