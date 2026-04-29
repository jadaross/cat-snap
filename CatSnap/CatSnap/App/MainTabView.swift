import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .map
    @State private var isSubmitPresented = false

    enum Tab: Hashable { case map, profile }

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem { Label("map", systemImage: "map") }
                .tag(Tab.map)

            UserProfilePlaceholder()
                .tabItem { Label("profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(Color.coral)
        .overlay(alignment: .bottom) {
            // Center "+" submit button — overlays the tab bar per the
            // catsnap-screens.jsx SnapScreen entry pattern.
            Button {
                isSubmitPresented = true
            } label: {
                ZStack {
                    Circle().fill(Color.coral).frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.creamSoft)
                }
                .shadow(color: Color.ink.opacity(0.18), radius: 8, y: 2)
            }
            .offset(y: -4)
            .accessibilityLabel("snap a sighting")
        }
        .fullScreenCover(isPresented: $isSubmitPresented) {
            SubmitView()
        }
    }
}

// Placeholder until slice 3.D builds the user profile.
private struct UserProfilePlaceholder: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            VStack(spacing: 16) {
                CatWindowMark(size: 96)
                Text("profile coming next")
                    .font(.Brand.jakarta(.semibold, size: 16))
                    .foregroundStyle(Color.ink)
                Button("sign out") {
                    Task { try? await session.signOut() }
                }
                .font(.Brand.jakarta(.medium, size: 14))
                .foregroundStyle(Color.coral)
            }
        }
    }
}

