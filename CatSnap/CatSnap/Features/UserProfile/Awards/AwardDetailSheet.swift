import SwiftUI

// Presented when an AwardTile is tapped. Explains the award and how it's
// earned; locked awards still show their criteria so users have something
// to chase.
struct AwardDetailSheet: View {
    let award: Award
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            grabber
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 18) {
                    emoji
                        .padding(.top, 16)

                    Text(award.label)
                        .font(.Brand.frauncesBlackItalic(size: 30))
                        .tracking(-0.8)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)

                    statusBadge
                        .padding(.top, -4)

                    Text(award.description)
                        .font(.Brand.jakarta(.regular, size: 14))
                        .foregroundStyle(Color.stone)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("HOW TO EARN")
                            .font(.Brand.mono(size: 10))
                            .tracking(1.2)
                            .foregroundStyle(Color.stone)
                        Text(award.criteria)
                            .font(.Brand.jakarta(.semibold, size: 14))
                            .foregroundStyle(Color.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.creamSoft, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
                    .padding(.horizontal, 20)

                    Color.clear.frame(height: 24)
                }
                .frame(maxWidth: .infinity)
            }

            Button { dismiss() } label: {
                Text("done")
                    .font(.Brand.jakarta(.bold, size: 15))
                    .foregroundStyle(Color.creamSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.ink, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 4)
        }
        .background(Color.cream.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private var emoji: some View {
        Text(award.earned ? award.emoji : "❓")
            .font(.system(size: 80))
            .opacity(award.earned ? 1 : 0.45)
            .frame(width: 132, height: 132)
            .background(
                Circle().fill(award.earned && award.rare ? Color.streetlampYellow : Color.creamSoft)
            )
            .overlay(Circle().stroke(Color.stoneLight, lineWidth: 1))
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.stoneLight)
            .frame(width: 36, height: 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if award.earned {
            Text("EARNED")
                .font(.Brand.mono(size: 10))
                .tracking(1.4)
                .foregroundStyle(Color.creamSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.coral, in: .capsule)
        } else {
            Text("NOT YET EARNED")
                .font(.Brand.mono(size: 10))
                .tracking(1.4)
                .foregroundStyle(Color.stone)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.creamDeep, in: .capsule)
                .overlay(Capsule().stroke(Color.stoneLight, lineWidth: 1))
        }
    }
}
