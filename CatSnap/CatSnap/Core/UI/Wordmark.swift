import SwiftUI

// Per docs/brand.md: Fraunces 900 italic, "cat" in Ink + "snap" in Coral,
// letter-spacing ~ -0.8.
struct Wordmark: View {
    var size: CGFloat = 64

    var body: some View {
        HStack(spacing: 0) {
            Text("cat")
                .foregroundStyle(Color.ink)
            Text("snap")
                .foregroundStyle(Color.coral)
        }
        .font(.Brand.frauncesBlackItalic(size: size))
        .tracking(-0.8 * (size / 64))
    }
}

#Preview {
    VStack(spacing: 24) {
        Wordmark(size: 80)
        Wordmark(size: 48)
        Wordmark(size: 28)
    }
    .padding()
    .background(Color.cream)
}
