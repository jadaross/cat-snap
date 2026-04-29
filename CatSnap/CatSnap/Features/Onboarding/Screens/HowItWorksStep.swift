import SwiftUI

// 02 · How it works — three step cards (Snap / Spot / Collect) with sample pins.
struct HowItWorksStep: View {
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("HOW IT WORKS")
                        .font(.Brand.mono(size: 11))
                        .foregroundStyle(Color.stone)
                        .tracking(1.4)
                    Text("three steps\nto your field\nguide.")
                        .font(.Brand.frauncesBlackItalic(size: 36))
                        .foregroundStyle(Color.ink)
                        .tracking(-1.4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 24)

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    stepCard(num: "01", title: "Snap", body: "See a cat? Take a photo.") {
                        MapPin(size: 48, bgColor: .coral, catColor: .ink)
                    }
                    stepCard(num: "02", title: "Spot", body: "Pin it on the map. Help everyone find them.") {
                        MapPin(size: 48, bgColor: .coral, catColor: Color(hex: 0xC97F3F), pulse: true)
                    }
                    stepCard(num: "03", title: "Collect", body: "Build your field guide. Track regulars, find legends.") {
                        MapPin(size: 48, bgColor: .streetlampYellow, catColor: .ink, ringColor: .ink, showStar: true)
                    }
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    OnboardingDots(activeIndex: 1, count: 9)
                    OnboardingPrimaryButton(title: "Next →", action: onAdvance)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private func stepCard<Icon: View>(num: String, title: String, body: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 16) {
            ZStack { icon() }
                .frame(width: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(num)
                    .font(.Brand.mono(size: 10))
                    .foregroundStyle(Color.coral)
                    .tracking(1.2)
                Text(title)
                    .font(.Brand.jakarta(.bold, size: 18))
                    .foregroundStyle(Color.ink)
                    .tracking(-0.4)
                Text(body)
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.stone)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.creamSoft, in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.stoneLight, lineWidth: 1)
        )
    }
}

#Preview {
    HowItWorksStep(onAdvance: {})
}
