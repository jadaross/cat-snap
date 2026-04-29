import SwiftUI

// Top-level gate: while the auth session is loading, show the brand splash.
// Once known, route to AuthView or SightingsListView based on session state.
struct ContentView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        switch session.state {
        case .loading:
            BrandSplash()
        case .signedOut:
            AuthView()
        case .signedIn:
            SightingsListView()
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
