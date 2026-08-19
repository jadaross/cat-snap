import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .explore
    @State private var exploreView: ExploreSubview = .map
    @State private var isSubmitPresented = false

    enum Tab: Hashable { case explore, you }

    var body: some View {
        Group {
            switch selectedTab {
            case .explore: ExploreView(view: $exploreView)
            case .you:     UserProfileView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // safeAreaInset rather than a ZStack overlay: the bar reports its full
        // occupied height (bar + snap-button overhang), so every screen below
        // is inset clear of the button instead of having its bottom controls
        // sit under it. Screens that want to bleed art under the bar opt out
        // with their own .ignoresSafeArea(edges: .bottom).
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CatSnapTabBar(
                active: $selectedTab,
                onSnap: { isSubmitPresented = true },
                onTabReselect: { tab in
                    // Tapping Explore while already on Explore — pop to root
                    // and snap the subview back to .map. Notification reaches
                    // both the MapView and GuideListView NavigationStacks.
                    if tab == .explore {
                        exploreView = .map
                        NotificationCenter.default.post(name: .popExploreToRoot, object: nil)
                    }
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $isSubmitPresented) {
            SubmitView()
        }
    }
}
