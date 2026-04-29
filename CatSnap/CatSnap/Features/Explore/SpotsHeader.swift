import SwiftUI

// Top-of-Explore header: pill-toggle (Map / Guide) + a tappable location
// search pill. Source: `CatSnap App.html` lines 240–266 (SpotsHeader).
struct SpotsHeader: View {
    @Binding var view: ExploreSubview
    var locationLabel: String = "near you"
    var onLocationTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            toggle
            searchPill
        }
        .padding(.horizontal, 16)
    }

    private var toggle: some View {
        HStack(spacing: 0) {
            ToggleSegment(
                label: "Map",
                glyph: AnyShape(ExploreGlyph()),
                isActive: view == .map,
                action: { view = .map }
            )
            ToggleSegment(
                label: "Guide",
                glyph: AnyShape(GuideGlyph()),
                isActive: view == .guide,
                action: { view = .guide }
            )
        }
        .padding(3)
        .background(Color.creamSoft, in: .capsule)
        .overlay(Capsule().stroke(Color.stoneLight, lineWidth: 1))
        .shadow(color: Color.ink.opacity(0.08), radius: 6, y: 2)
    }

    private var searchPill: some View {
        Button(action: { onLocationTap?() }) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.stone)
                Text(locationLabel)
                    .font(.Brand.jakarta(.semibold, size: 13))
                    .foregroundStyle(Color.stone)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.creamSoft, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
            .shadow(color: Color.ink.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleSegment: View {
    let label: String
    let glyph: AnyShape
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                glyph
                    .stroke(
                        isActive ? Color.creamSoft : Color.stone,
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 14, height: 14)

                Text(label)
                    .font(.Brand.jakarta(.bold, size: 12))
                    .tracking(0.2)
                    .foregroundStyle(isActive ? Color.creamSoft : Color.stone)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isActive ? Color.ink : Color.clear, in: .capsule)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        SpotsHeader(view: .constant(.map))
        SpotsHeader(view: .constant(.guide))
    }
    .padding()
    .background(Color.cream)
}
