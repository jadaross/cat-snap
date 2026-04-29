import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .explore
    @State private var isSubmitPresented = false

    enum Tab: Hashable { case explore, you }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .explore: ExploreView()
                case .you:     UserProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 76)

            CatSnapTabBar(active: $selectedTab) {
                isSubmitPresented = true
            }
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $isSubmitPresented) {
            SubmitView()
        }
    }
}
