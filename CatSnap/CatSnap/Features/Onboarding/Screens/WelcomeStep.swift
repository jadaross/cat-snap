import SwiftUI

// 01 · Welcome — blinking window mark, hero copy, "Get started →" + sign-in link.
struct WelcomeStep: View {
    let onAdvance: () -> Void
    let onAlreadyHaveAccount: () -> Void

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                CatWindowMark(size: 180, blink: true)

                Text("spot every\ncat.")
                    .font(.Brand.frauncesBlackItalic(size: 44))
                    .foregroundStyle(Color.ink)
                    .tracking(-1.6)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                Text("A field guide for the curious. Snap the cats in your neighbourhood — they all have stories.")
                    .font(.Brand.jakarta(.medium, size: 16))
                    .foregroundStyle(Color.stone)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: 320)

                Spacer()

                VStack(spacing: 14) {
                    OnboardingDots(activeIndex: 0, count: 9)
                    OnboardingPrimaryButton(title: "Get started →", action: onAdvance)
                    OnboardingTextButton(title: "I already have an account", action: onAlreadyHaveAccount)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    WelcomeStep(onAdvance: {}, onAlreadyHaveAccount: {})
}
