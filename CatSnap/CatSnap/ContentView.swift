import SwiftUI

// Top-level gate. Routing depends on auth state and two onboarding flags:
//
//   pre-auth done?  signed in?  post-auth done?  → destination
//   no              no          —                  PreAuthOnboardingView
//   yes             no          —                  AuthView
//   —               yes         no                 PostAuthOnboardingView
//   —               yes         yes                MainTabView
//
// The two flags exist because sign-up can require email confirmation: the user
// finishes pre-auth, leaves to confirm, returns. We don't want to re-run the
// permission screens.
struct ContentView: View {
    @Environment(AuthSession.self) private var session
    @AppStorage(OnboardingFlags.preAuthDoneKey) private var preAuthDone: Bool = false
    @AppStorage(OnboardingFlags.postAuthDoneKey) private var postAuthDone: Bool = false

    var body: some View {
        switch session.state {
        case .loading:
            BrandSplash()
        case .signedOut:
            if preAuthDone {
                AuthView()
            } else {
                PreAuthOnboardingView()
            }
        case .signedIn:
            if postAuthDone {
                MainTabView()
            } else {
                PostAuthOnboardingView()
            }
        }
    }
}

private struct BrandSplash: View {
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            VStack(spacing: 20) {
                CatWindowMark(size: 140)
                Wordmark(size: 56)
                Text("spot every cat.")
                    .font(.Brand.jakarta(.medium, size: 15))
                    .foregroundStyle(Color.stone)
            }
        }
    }
}

#Preview("Splash")    { BrandSplash() }
