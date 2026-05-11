import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .explore
    @State private var exploreView: ExploreSubview = .map
    @State private var isSubmitPresented = false

    enum Tab: Hashable { case explore, you }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .explore: ExploreView(view: $exploreView)
                case .you:     UserProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 76)

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
