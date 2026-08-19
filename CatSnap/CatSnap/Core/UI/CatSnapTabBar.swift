import SwiftUI

// Custom 3-zone bottom bar. Native TabView can't host the design's centerpiece —
// a 96pt coral Snap button that overflows the bar upward by 36pt — so we render
// our own row plus an overlaid floating button. Source: handoff bundle
// `CatSnap App.html` lines 167–193 (TabBar component).

struct CatSnapTabBar: View {
    @Binding var active: MainTabView.Tab
    let onSnap: () -> Void
    /// Fires when a tab the user is already on gets tapped again — the host
    /// uses this to pop nav stacks to root and reset secondary state.
    var onTabReselect: ((MainTabView.Tab) -> Void)? = nil

    static let barHeight: CGFloat = 76
    static let snapOverflow: CGFloat = 36   // distance button protrudes above bar top

    /// Total vertical space the bar occupies, including the slice of the snap
    /// button that overhangs its top edge. Hosts must inset content by this —
    /// insetting by `barHeight` alone leaves the button's overhang floating
    /// over content, where its circular hit area silently eats taps.
    static let occupiedHeight: CGFloat = barHeight + snapOverflow

    private let snapSize: CGFloat = 96

    var body: some View {
        VStack(spacing: 0) {
            // Reserved, tap-transparent band standing in for the button's
            // overhang, so the bar reports its true height to `safeAreaInset`.
            Color.clear
                .frame(height: Self.snapOverflow)
                .allowsHitTesting(false)

            barRow
        }
        .overlay(alignment: .top) {
            // Top-aligned against the reserved band, so the button lands in
            // exactly the spot the old `.offset(y: -snapOverflow)` put it.
            SnapButton(size: snapSize, action: onSnap)
        }
    }

    private var barRow: some View {
        HStack(alignment: .top, spacing: 0) {
            TabItem(
                glyph: ExploreGlyph(),
                label: "Explore",
                isActive: active == .explore,
                action: {
                    if active == .explore {
                        onTabReselect?(.explore)
                    } else {
                        active = .explore
                    }
                }
            )

            // Reserved column for the floating snap button — keeps the side
            // tabs balanced. Width matches the JSX (110pt).
            Color.clear.frame(width: 110, height: Self.barHeight)

            TabItem(
                glyph: ProfileGlyph(),
                label: "You",
                isActive: active == .you,
                action: {
                    if active == .you {
                        onTabReselect?(.you)
                    } else {
                        active = .you
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, minHeight: Self.barHeight, alignment: .top)
        .background(
            Color.creamSoft
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.stoneLight).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct TabItem<Glyph: Shape>: View {
    let glyph: Glyph
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                glyph
                    .stroke(
                        isActive ? Color.ink : Color.stone,
                        style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 24, height: 24)

                Text(label)
                    .font(Font.Brand.jakarta(.bold, size: 11))
                    .tracking(0.2)
                    .foregroundStyle(isActive ? Color.ink : Color.stone)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SnapButton: View {
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer cream border ring (CSS `border: 5px solid CREAM_W`)
                Circle().fill(Color.creamSoft)
                // Inner coral disc, inset by the 5pt border
                Circle().fill(Color.coral).padding(5)

                VStack(spacing: 2) {
                    CameraGlyph()
                        .stroke(
                            Color.creamSoft,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 40, height: 40)

                    Text("snap")
                        .font(Font.Brand.frauncesBlackItalic(size: 13))
                        .tracking(-0.3)
                        .foregroundStyle(Color.creamSoft)
                }
            }
            .frame(width: size, height: size)
            // 1pt outset hairline ring (CSS `0 0 0 1px rgba(0,0,0,0.04)`)
            .overlay(Circle().strokeBorder(Color.ink.opacity(0.04), lineWidth: 1))
            .shadow(color: Color.coralDeep.opacity(0.45), radius: 12, x: 0, y: 10)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("snap a sighting")
    }
}
