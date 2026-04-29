import SwiftUI

// Bottom-of-map peek with a horizontal "nearby cats" rail. Source:
// `CatSnap App.html` lines 369–392 (bottom card peek inside Spots map view).
struct NearbyCatsCard: View {
    let sightings: [NearbySighting]
    var onTap: (NearbySighting) -> Void

    var body: some View {
        VStack(spacing: 0) {
            handle

            HStack(alignment: .firstTextBaseline) {
                Text("nearby cats")
                    .font(.Brand.frauncesBlackItalic(size: 22))
                    .tracking(-0.6)
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("\(sightings.count) NEARBY")
                    .font(.Brand.mono(size: 10))
                    .tracking(1)
                    .foregroundStyle(Color.stone)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(sightings) { sighting in
                        CatRailCard(sighting: sighting)
                            .onTapGesture { onTap(sighting) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .padding(.top, 14)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 22, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 22
            )
            .fill(Color.creamSoft)
        )
        .shadow(color: Color.ink.opacity(0.08), radius: 12, y: -4)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.stoneLight)
            .frame(width: 36, height: 4)
            .padding(.bottom, 10)
    }
}

private struct CatRailCard: View {
    let sighting: NearbySighting

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncCatImage(url: sighting.catPhotoUrl ?? sighting.photoUrl)
                    .frame(width: 128, height: 86)
                    .clipped()

                if let badge = badge {
                    Text(badge.label)
                        .font(.Brand.jakarta(.bold, size: 8))
                        .tracking(0.5)
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badge.background, in: .capsule)
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text((sighting.catName ?? "unnamed").lowercased())
                    .font(.Brand.frauncesBlackItalic(size: 15))
                    .tracking(-0.3)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                Text(metaLine.uppercased())
                    .font(.Brand.mono(size: 9))
                    .tracking(0.4)
                    .foregroundStyle(Color.stone)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 128)
        .background(Color.cream, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var metaLine: String {
        let dist = formatDistance(sighting.distanceM)
        if let label = sighting.locationLabel, !label.isEmpty {
            return "\(dist) · \(label)"
        }
        return dist
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 { return "\(Int(meters))m" }
        return String(format: "%.1fkm", meters / 1000)
    }

    private struct Badge {
        let label: String
        let background: Color
    }

    private var badge: Badge? {
        guard let rarity = sighting.catRarity else { return nil }
        switch rarity {
        case .legendary: return Badge(label: "★ LEGEND", background: .streetlampYellow)
        case .rare:      return Badge(label: "RARE", background: .coral.opacity(0.85))
        default:         return nil
        }
    }
}
