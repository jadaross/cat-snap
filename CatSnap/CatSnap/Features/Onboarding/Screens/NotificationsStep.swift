import SwiftUI
import UserNotifications

// 05 · Notifications — window mark with a "3 new" badge + sample notification.
// We capture the OS-level grant only; push handling (APNs, token upload) is v2.
struct NotificationsStep: View {
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                // Window mark with the "3 new" pill.
                ZStack(alignment: .topTrailing) {
                    CatWindowMark(size: 140, showSill: false)
                        .padding(.top, 6)
                        .padding(.trailing, 6)

                    Text("3 new")
                        .font(.Brand.jakarta(.bold, size: 12))
                        .foregroundStyle(Color.creamSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.coral, in: .capsule)
                        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 2)
                }

                Text(String(localized: "get a buzz\nwhen cats\nshow up."))
                    .font(.Brand.frauncesBlackItalic(size: 36))
                    .foregroundStyle(Color.ink)
                    .tracking(-1.4)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                Text(String(localized: "Gentle pings when a regular returns to your area, or when someone spots a legend. No spam."))
                    .font(.Brand.jakarta(.regular, size: 15))
                    .foregroundStyle(Color.stone)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 14)
                    .padding(.horizontal, 32)
                    .frame(maxWidth: 320)

                // Sample notification card.
                HStack(spacing: 12) {
                    MapPin(size: 36, bgColor: .coral, catColor: Color(hex: 0xC97F3F))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Marmalade is back"))
                            .font(.Brand.jakarta(.bold, size: 13))
                            .foregroundStyle(Color.ink)
                        Text(String(localized: "Spotted on Brick Lane · 2 min ago"))
                            .font(.Brand.jakarta(.regular, size: 12))
                            .foregroundStyle(Color.stone)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.creamSoft, in: .rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 12) {
                    OnboardingDots(activeIndex: 4, count: 9)
                    OnboardingPrimaryButton(title: String(localized: "Turn on notifications")) {
                        Task {
                            // Capture grant for future v2 push; ignore the result.
                            _ = try? await UNUserNotificationCenter.current()
                                .requestAuthorization(options: [.alert, .sound, .badge])
                        }
                        onAdvance()
                    }
                    OnboardingTextButton(title: String(localized: "Not now"), action: onAdvance)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    NotificationsStep(onAdvance: {})
}
