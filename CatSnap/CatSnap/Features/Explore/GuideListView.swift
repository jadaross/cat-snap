import SwiftUI

// Field guide list — the cat collection grid with progress, filter chips,
// and locked-silhouette placeholders for un-spotted cats. Source:
// `CatSnap App.html` lines 285–333 (Spots `view === 'list'`).
//
// Phase 2b lands the shell only: SpotsHeader + a placeholder body. The
// progress bar, filter chips, and grid arrive in Phase 2e once we settle
// how to model the "60-cat region guide" (which doesn't exist server-side
// yet — likely a hardcoded slug per region in v1).
struct GuideListView: View {
    @Binding var exploreView: ExploreSubview

    var body: some View {
        VStack(spacing: 0) {
            SpotsHeader(view: $exploreView)
                .padding(.top, 8)
                .padding(.bottom, 10)

            placeholder
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.cream)
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            CatWindowMark(size: 64, showSill: false)
                .opacity(0.6)
            Text("your guide")
                .font(.Brand.frauncesBlackItalic(size: 28))
                .foregroundStyle(Color.ink)
            Text("the field-guide grid lands in phase 2e.")
                .font(.Brand.jakarta(.regular, size: 13))
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

#Preview {
    GuideListView(exploreView: .constant(.guide))
}
