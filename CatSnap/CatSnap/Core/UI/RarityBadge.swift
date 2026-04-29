import SwiftUI

struct RarityBadge: View {
    let rarity: Cat.Rarity
    var size: Size = .regular

    enum Size {
        case small, regular
        var font: Font {
            switch self {
            case .small:   return .Brand.jakarta(.semibold, size: 10)
            case .regular: return .Brand.jakarta(.semibold, size: 12)
            }
        }
        var padding: EdgeInsets {
            switch self {
            case .small:   return .init(top: 2, leading: 6,  bottom: 2, trailing: 6)
            case .regular: return .init(top: 4, leading: 10, bottom: 4, trailing: 10)
            }
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            if rarity == .legendary {
                Text("★")
            }
            Text(rarity.label)
        }
        .font(size.font)
        .foregroundStyle(rarity.foreground)
        .padding(size.padding)
        .background(rarity.background, in: .capsule)
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
    var foreground: Color {
        switch self {
        case .common:    return Color.Rarity.commonForeground
        case .uncommon:  return Color.Rarity.uncommonForeground
        case .rare:      return Color.Rarity.rareForeground
        case .legendary: return Color.Rarity.legendaryForeground
        }
    }
    var background: Color {
        switch self {
        case .common:    return Color.Rarity.commonBackground
        case .uncommon:  return Color.Rarity.uncommonBackground
        case .rare:      return Color.Rarity.rareBackground
        case .legendary: return Color.Rarity.legendaryBackground
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(Cat.Rarity.allCases, id: \.self) { r in
            RarityBadge(rarity: r)
        }
        RarityBadge(rarity: .legendary, size: .small)
    }
    .padding()
    .background(Color.cream)
}
