import SwiftUI

struct TagChip: View {
    let tag: String
    var isActive: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { chip }.buttonStyle(.plain)
            } else {
                chip
            }
        }
    }

    private var chip: some View {
        Text(tag)
            .font(.Brand.jakarta(.medium, size: 12))
            .foregroundStyle(isActive ? Color.coralDeep : Color.stone)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isActive ? Color.creamSoft : Color.stoneLight.opacity(0.5), in: .capsule)
            .overlay(
                Capsule().stroke(
                    isActive ? Color.coral : Color.clear,
                    lineWidth: 1
                )
            )
    }

    // Source: catsnap-data.jsx tag palette used in the Submit screen.
    static let presets: [String] = [
        "friendly", "shy",
        "orange", "black", "white", "tabby", "calico", "grey",
        "fluffy", "chonky", "bold", "kitten",
    ]
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 6) {
            TagChip(tag: "friendly", isActive: true)
            TagChip(tag: "shy")
            TagChip(tag: "tabby", isActive: true)
        }
        TagChip(tag: "static label")
    }
    .padding()
    .background(Color.cream)
}
