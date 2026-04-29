import SwiftUI

struct SightingThumbnail: View {
    let photoUrl: URL?
    let seenAt: Date?

    var body: some View {
        Color.creamDeep
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AsyncCatImage(url: photoUrl)
            }
            .clipShape(.rect(cornerRadius: 8))
            .overlay(alignment: .bottomLeading) {
                if let seenAt {
                    Text(seenAt.relativeShort)
                        .font(.Brand.mono(size: 10))
                        .foregroundStyle(Color.creamSoft)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.ink.opacity(0.6), in: .capsule)
                        .padding(6)
                }
            }
    }
}

private extension Date {
    var relativeShort: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
