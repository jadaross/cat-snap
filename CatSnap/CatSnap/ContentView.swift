import SwiftUI

// Brand smoke test screen — proves colors, fonts, and the cat-window mark
// load correctly. Replaced with real Auth + map navigation in the next phase.
struct ContentView: View {
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                CatWindowMark(size: 160)

                VStack(spacing: 8) {
                    Wordmark(size: 64)
                    Text("spot every cat.")
                        .font(.Brand.jakarta(.medium, size: 16))
                        .foregroundStyle(Color.stone)
                }

                Spacer()

                Text("system v1 · 2026")
                    .font(.Brand.mono(size: 11))
                    .foregroundStyle(Color.stone.opacity(0.7))
                    .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    ContentView()
}
