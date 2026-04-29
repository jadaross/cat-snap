import SwiftUI

// 09 · On the map — the user's pin in the center with sparkles + pulse,
// ambient pins around it, and a bottom panel with the closing CTA.
//
// Tapping "Explore the map →" calls `onAdvance`, which is responsible for
// rendering+uploading the chosen avatar and dismissing the flow.
struct OnTheMapStep: View {
    let avatar: AvatarChoice
    let isWorking: Bool
    let onAdvance: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.cream.ignoresSafeArea()

            // Map fills above the panel.
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .topLeading) {
                    OnboardingMiniMap()

                    MapPin(size: 36, bgColor: .coral, catColor: .ink)
                        .offset(x: w * 0.20, y: h * 0.15)
                    MapPin(size: 36, bgColor: .coral, catColor: Color(hex: 0x3A2A1C))
                        .offset(x: w * 0.70, y: h * 0.22)
                    MapPin(size: 36, bgColor: .coral, catColor: Color(hex: 0x8A8580))
                        .offset(x: w * 0.15, y: h * 0.55)
                    MapPin(size: 36, bgColor: .sage, catColor: .creamSoft, glassColor: .sage)
                        .offset(x: w * 0.75, y: h * 0.50)

                    // User's hero pin — colored from the avatar choice — with sparkles.
                    ZStack {
                        MapPin(size: 84, bgColor: .coral, catColor: avatar.color, pulse: true)

                        // Sparkles (2 above, 2 below the face).
                        Group {
                            Text("✦").offset(x: -42, y: -30)
                            Text("✦").offset(x: 42, y: -16)
                            Text("✦").offset(x: -36, y: 60)
                            Text("✦").offset(x: 38, y: 50)
                        }
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.streetlampYellowDeep)
                    }
                    .position(x: w * 0.50, y: h * 0.40)
                }
            }
            .padding(.bottom, 220) // leave room for the bottom panel

            // Bottom panel.
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("🎉").font(.system(size: 18))
                    Text("YOU DID IT")
                        .font(.Brand.mono(size: 11))
                        .foregroundStyle(Color.coral)
                        .tracking(1.4)
                }

                Text("marmalade is on the map.")
                    .font(.Brand.frauncesBlackItalic(size: 30))
                    .foregroundStyle(Color.ink)
                    .tracking(-1.2)

                Text("That's one cat in your guide. Find the next one wherever you go.")
                    .font(.Brand.jakarta(.regular, size: 14))
                    .foregroundStyle(Color.stone)
                    .lineSpacing(3)

                OnboardingDots(activeIndex: 8, count: 9)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                OnboardingPrimaryButton(
                    title: "Explore the map →",
                    isWorking: isWorking,
                    action: onAdvance
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)
            .background(
                Color.creamSoft
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(topLeading: 24, bottomLeading: 0, bottomTrailing: 0, topTrailing: 24)
                        )
                    )
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -8)
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    OnTheMapStep(avatar: .default, isWorking: false, onAdvance: {})
}
