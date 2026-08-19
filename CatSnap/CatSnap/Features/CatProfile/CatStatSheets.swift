import SwiftUI

// The three sheets behind the cat profile's stat tiles. Sheets rather than
// pushes: every NavigationStack that hosts CatProfileView already claims
// UUID as a destination type, so a second UUID-keyed push would collide.
//
// All three read from the [CatSighting] the profile already loaded — no
// extra queries, because `sightings_for_cat` carries the spotter profile.

// MARK: - Sightings

struct CatSightingsSheet: View {
    let catName: String?
    let sightings: [CatSighting]

    @Environment(\.dismiss) private var dismiss
    @State private var expanded: CatSighting?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                        spacing: 6
                    ) {
                        // The profile grid caps at 9; this is the full set.
                        ForEach(sightings) { sighting in
                            Button { expanded = sighting } label: {
                                SightingThumbnail(
                                    photoUrl: sighting.photoUrl,
                                    seenAt: sighting.seenAt
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { doneButton { dismiss() } }
            .sheet(item: $expanded) { sighting in
                SightingDetailSheet(sighting: sighting)
            }
        }
    }

    private var titleText: String {
        sightings.count == 1
            ? String(localized: "1 sighting")
            : String(localized: "\(sightings.count) sightings")
    }
}

// MARK: - Spotters

struct CatSpottersSheet: View {
    let sightings: [CatSighting]

    @Environment(\.dismiss) private var dismiss

    // Derived client-side: sightings_for_cat already carries username,
    // display_name and avatar_url, so no profiles lookup is needed.
    private struct SpotterRow: Identifiable {
        let id: UUID
        let name: String
        let avatarUrl: URL?
        let count: Int
        let lastSeen: Date
    }

    private var spotters: [SpotterRow] {
        Dictionary(grouping: sightings, by: \.userId)
            .compactMap { userId, group -> SpotterRow? in
                guard let first = group.first else { return nil }
                return SpotterRow(
                    id: userId,
                    name: first.spotterName,
                    avatarUrl: first.avatarUrl,
                    count: group.count,
                    lastSeen: group.map(\.seenAt).max() ?? first.seenAt
                )
            }
            .sorted { ($0.count, $1.name) > ($1.count, $0.name) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        // Deliberately not tappable: the app has no
                        // read-only profile screen for another person yet.
                        ForEach(spotters) { spotter in
                            HStack(spacing: 12) {
                                AsyncCatImage(url: spotter.avatarUrl)
                                    .frame(width: 32, height: 32)
                                    .clipShape(.circle)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spotter.name)
                                        .font(.Brand.jakarta(.bold, size: 15))
                                        .foregroundStyle(Color.ink)
                                        .lineLimit(1)
                                    Text(detail(for: spotter))
                                        .font(.Brand.mono(size: 10))
                                        .tracking(0.6)
                                        .foregroundStyle(Color.stone)
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.creamSoft, in: .rect(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stoneLight, lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { doneButton { dismiss() } }
            .presentationDetents([.medium, .large])
        }
    }

    private var titleText: String {
        spotters.count == 1
            ? String(localized: "1 spotter")
            : String(localized: "\(spotters.count) spotters")
    }

    private func detail(for spotter: SpotterRow) -> String {
        let count = spotter.count == 1
            ? String(localized: "1 SIGHTING")
            : String(localized: "\(spotter.count) SIGHTINGS")
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let when = formatter.localizedString(for: spotter.lastSeen, relativeTo: Date())
        return "\(count) · \(when.uppercased())"
    }
}

// MARK: - First sighting

struct FirstSightingSheet: View {
    let catName: String?
    let sighting: CatSighting?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                if let sighting {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            AsyncCatImage(url: sighting.photoUrl)
                                .frame(maxWidth: .infinity)
                                .frame(height: 260)
                                .clipped()
                                .clipShape(.rect(cornerRadius: 16))

                            Text(String(localized: "first spotted by \(sighting.spotterName)"))
                                .font(.Brand.frauncesBlackItalic(size: 22))
                                .tracking(-0.5)
                                .foregroundStyle(Color.ink)

                            SightingFactsBlock(sighting: sighting)

                            // One-pin reuse of the territory map.
                            CatTerritoryMap(sightings: [sighting], height: 160)
                                .clipShape(.rect(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.stoneLight, lineWidth: 1)
                                )
                        }
                        .padding(16)
                    }
                } else {
                    Text(String(localized: "no sightings yet"))
                        .font(.Brand.jakarta(.regular, size: 14))
                        .foregroundStyle(Color.stone)
                }
            }
            .navigationTitle(String(localized: "first seen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { doneButton { dismiss() } }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Shared pieces

/// One sighting blown up, reached from the sightings grid.
struct SightingDetailSheet: View {
    let sighting: CatSighting

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        AsyncCatImage(url: sighting.photoUrl)
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipped()
                            .clipShape(.rect(cornerRadius: 16))

                        Text(String(localized: "spotted by \(sighting.spotterName)"))
                            .font(.Brand.jakarta(.bold, size: 16))
                            .foregroundStyle(Color.ink)

                        SightingFactsBlock(sighting: sighting)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { doneButton { dismiss() } }
            .presentationDetents([.large])
        }
    }
}

private struct SightingFactsBlock: View {
    let sighting: CatSighting

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            factRow(label: "WHEN", value: absoluteDate)
            if let place = sighting.locationLabel, !place.isEmpty {
                factRow(label: "WHERE", value: place)
            }
            if let notes = sighting.notes, !notes.isEmpty {
                factRow(label: "NOTES", value: notes)
            }
        }
    }

    private var absoluteDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: sighting.seenAt)
    }

    private func factRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.Brand.mono(size: 9))
                .tracking(0.8)
                .foregroundStyle(Color.stone)
            Text(value)
                .font(.Brand.jakarta(.medium, size: 14))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@ToolbarContentBuilder
private func doneButton(_ action: @escaping () -> Void) -> some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
        Button(String(localized: "done"), action: action)
            .font(.Brand.jakarta(.medium, size: 14))
            .foregroundStyle(Color.coral)
    }
}
