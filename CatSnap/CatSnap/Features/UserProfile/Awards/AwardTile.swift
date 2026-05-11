import SwiftUI

// One cell in the awards grid. Tappable; tapping passes the award up so the
// host view can present an AwardDetailSheet. Sized to read clearly at 3 cols.
struct AwardTile: View {
    let award: Award
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(award.earned ? award.emoji : "❓")
                    .font(.system(size: 36))
                    .opacity(award.earned ? 1 : 0.45)

                Text(award.label)
                    .font(.Brand.jakarta(.bold, size: 11))
                    .tracking(0.2)
                    .foregroundStyle(award.earned ? Color.ink : Color.stone)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(background, in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        award.rare && award.earned ? Color.ink : Color.stoneLight,
                        lineWidth: award.rare && award.earned ? 1.5 : 1
                    )
            )
            .shadow(
                color: award.rare && award.earned ? Color.ink.opacity(0.85) : .clear,
                radius: 0, x: 2, y: 2
            )
            .opacity(award.earned ? 1 : 0.6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to see how to earn this award.")
    }

    private var background: Color {
        if !award.earned { return Color.creamDeep }
        if award.rare    { return Color.streetlampYellow }
        return Color.creamSoft
    }

    private var accessibilityLabel: String {
        let state = award.earned ? "earned" : "not yet earned"
        return "\(award.label), \(state)"
    }
}
