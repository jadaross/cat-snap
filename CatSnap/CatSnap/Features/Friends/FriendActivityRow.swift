import SwiftUI

// Compact friend-activity row used inside the You profile "RECENT"
// snippet and the full Friends activity feed. Source: `CatSnap App.html`
// lines 1133–1150 (compact card).
struct FriendActivityRow: View {
    let sighting: NearbySighting
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                avatar

                VStack(alignment: .leading, spacing: 1) {
                    spottedLine
                    Text(metaLine)
                        .font(.Brand.mono(size: 9))
                        .tracking(0.4)
                        .foregroundStyle(Color.stone)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                AsyncCatImage(url: sighting.catPhotoUrl ?? sighting.photoUrl)
                    .frame(width: 32, height: 42)
                    .clipShape(.rect(cornerRadius: 8))
            }
            .padding(10)
            .background(Color.creamSoft, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var avatar: some View {
        ZStack {
            Color.ink
            if let url = sighting.avatarUrl {
                AsyncCatImage(url: url)
            } else {
                CatWindowMark(size: 26, showSill: false)
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(.rect(cornerRadius: 8))
    }

    private var spottedLine: some View {
        let who = sighting.displayName ?? sighting.username
        let cat = sighting.catName ?? "a cat"
        return (
            Text(who).bold()
            + Text(" spotted ").foregroundStyle(Color.ink)
            + Text(cat).bold()
        )
        .font(.Brand.jakarta(.regular, size: 12))
        .foregroundStyle(Color.ink)
        .lineLimit(1)
    }

    private var metaLine: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let when = formatter.localizedString(for: sighting.seenAt, relativeTo: Date())
        if let label = sighting.locationLabel, !label.isEmpty {
            return "\(label.uppercased()) · \(when.uppercased())"
        }
        return when.uppercased()
    }
}
