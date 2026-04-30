import SwiftUI

// Field guide: 3-column grid of cats (the user's regional collection)
// with progress bar, filter chips, and locked silhouettes for un-spotted
// cats. Source: `CatSnap App.html` lines 285–333 (Spots `view === 'list'`).
struct GuideListView: View {
    @Binding var exploreView: ExploreSubview
    @State private var model = GuideModel()
    @State private var filter: GuideFilter = .all
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                SpotsHeader(view: $exploreView)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                progress
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                filterRow
                    .padding(.bottom, 10)

                grid
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.cream)
            .navigationDestination(for: UUID.self) { catId in
                CatProfileView(catId: catId)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await model.load() }
        }
    }

    private var visibleCats: [Cat] {
        model.cats.filter { cat in
            switch filter {
            case .all:      return true
            case .legends:  return cat.rarity == .legendary
            case .rare:     return cat.rarity == .rare
            case .today:    return model.spottedTodayCatIds.contains(cat.id)
            case .missing:  return !model.spottedCatIds.contains(cat.id)
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("your guide")
                    .font(.Brand.frauncesBlackItalic(size: 22))
                    .tracking(-0.6)
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("\(model.spottedCatIds.count) / \(model.cats.count)")
                    .font(.Brand.mono(size: 10))
                    .tracking(1)
                    .foregroundStyle(Color.stone)
            }

            GeometryReader { geo in
                let pct = model.cats.isEmpty ? 0
                    : Double(model.spottedCatIds.count) / Double(model.cats.count)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.creamDeep)
                    Capsule().fill(Color.coral)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 5)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(GuideFilter.allCases, id: \.self) { f in
                    FilterChip(
                        label: f.label,
                        isActive: filter == f,
                        action: { filter = f }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var grid: some View {
        if model.isLoading && model.cats.isEmpty {
            ProgressView().tint(Color.coral)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if visibleCats.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                    spacing: 8
                ) {
                    ForEach(visibleCats) { cat in
                        GuideCatCell(
                            cat: cat,
                            isSpotted: model.spottedCatIds.contains(cat.id),
                            spotPhotoUrl: model.catIdToPhotoUrl[cat.id]
                        )
                        .onTapGesture {
                            // Only push the profile for cats the user has actually
                            // spotted. Locked silhouettes stay locked.
                            if model.spottedCatIds.contains(cat.id) {
                                path.append(cat.id)
                            }
                        }
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
        switch filter {
        case .all:      return "no cats in the guide yet"
        case .today:    return "nothing spotted today"
        case .legends:  return "no legends here"
        case .rare:     return "no rare cats here"
        case .missing:  return "you've spotted them all"
        }
    }

    private var emptySubtitle: String {
        switch filter {
        case .all:      return "be the first to log a sighting."
        case .today:    return "snap one and it'll show up here."
        case .legends:  return "keep looking — they're around somewhere."
        case .rare:     return "rare cats only show after they've been logged."
        case .missing:  return "nice work."
        }
    }
}

private enum GuideFilter: CaseIterable, Hashable {
    case all, legends, rare, today, missing

    var label: String {
        switch self {
        case .all:      return "All"
        case .legends:  return "★ Legends"
        case .rare:     return "Rare"
        case .today:    return "Today"
        case .missing:  return "Missing"
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.Brand.jakarta(.bold, size: 12))
                .foregroundStyle(isActive ? Color.creamSoft : Color.stone)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(isActive ? Color.ink : Color.clear)
                )
                .overlay(
                    Capsule().stroke(isActive ? Color.clear : Color.stoneLight, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct GuideCatCell: View {
    let cat: Cat
    let isSpotted: Bool
    let spotPhotoUrl: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                photo
                if isSpotted, let badge = rarityBadge {
                    Text(badge.label)
                        .font(.Brand.jakarta(.bold, size: 8))
                        .tracking(0.4)
                        .foregroundStyle(badge.foreground)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badge.background, in: .capsule)
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.Brand.frauncesBlackItalic(size: 14))
                    .tracking(-0.3)
                    .foregroundStyle(isSpotted ? Color.ink : Color.stone)
                    .lineLimit(1)

                if isSpotted {
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
        .background(isSpotted ? Color.creamSoft : Color.creamDeep, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
        .opacity(isSpotted ? 1 : 0.6)
    }

    @ViewBuilder
    private var photo: some View {
        Color.creamDeep
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if isSpotted, let url = cat.primaryPhotoUrl ?? spotPhotoUrl {
                    AsyncCatImage(url: url)
                } else {
                    Text("?")
                        .font(.Brand.frauncesBlackItalic(size: 28))
                        .foregroundStyle(Color.stone)
                }
            }
            .clipShape(.rect(topLeadingRadius: 12, topTrailingRadius: 12))
    }

    private var displayName: String {
        if isSpotted, let name = cat.name, !name.isEmpty {
            return name.lowercased()
        }
        return "?"
    }

    private struct Badge {
        let label: String
        let background: Color
        let foreground: Color
    }

    private var rarityBadge: Badge? {
        switch cat.rarity {
        case .legendary: return Badge(label: "★ LEGEND", background: .streetlampYellow, foreground: .ink)
        case .rare:      return Badge(label: "RARE", background: .coral, foreground: .creamSoft)
        case .uncommon:  return Badge(label: "UNCOMMON", background: .sage.opacity(0.3), foreground: .sage)
        case .common:    return nil
        }
    }
}
