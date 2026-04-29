import SwiftUI

// Page indicator. The active dot widens to a 24×6 pill; inactive dots stay 6×6.
// We draw our own instead of relying on TabView's PageIndexView so we can match
// the exact pill geometry from the design.
struct OnboardingDots: View {
    let activeIndex: Int
    let count: Int
    var activeColor: Color = .ink
    var inactiveColor: Color = .stoneLight

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == activeIndex ? activeColor : inactiveColor)
                    .frame(width: i == activeIndex ? 24 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: activeIndex)
            }
        }
    }
}
