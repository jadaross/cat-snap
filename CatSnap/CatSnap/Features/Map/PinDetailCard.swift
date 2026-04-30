import SwiftUI

struct PinDetailCard: View {
    let sighting: NearbySighting
    var onTapToOpen: (() -> Void)? = nil

    private var isOpenable: Bool { sighting.catId != nil }

    var body: some View {
        if isOpenable {
            Button(action: { onTapToOpen?() }) { card }
                .buttonStyle(.plain)
        } else {
            card
        }
    }

    private var card: some View {
        HStack(spacing: 12) {
            AsyncCatImage(url: sighting.photoUrl)
                .frame(width: 56, height: 56)
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(sighting.catName ?? "unnamed cat")
                        .font(.Brand.jakarta(.semibold, size: 15))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    if let rarity = sighting.catRarity {
                        RarityBadge(rarity: rarity, size: .small)
                    }
                }

                if let label = sighting.locationLabel {
                    Text(label)
                        .font(.Brand.jakarta(.regular, size: 12))
                        .foregroundStyle(Color.stone)
                        .lineLimit(1)
                }

                Text(sighting.seenAt.relativeShort)
                    .font(.Brand.mono(size: 11))
                    .foregroundStyle(Color.stone.opacity(0.8))
            }

            Spacer(minLength: 0)

            if isOpenable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.stone)
            }
        }
        .padding(12)
        .background(Color.creamSoft, in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1)
        )
        .shadow(color: Color.ink.opacity(0.08), radius: 12, y: 4)
    }
}

private extension Date {
    var relativeShort: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
