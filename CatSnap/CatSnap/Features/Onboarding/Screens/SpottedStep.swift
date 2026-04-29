import SwiftUI

// 08 · Spotted! — illustrative naming/tagging card. The name and tag selections
// are not persisted; this screen just walks the user through the shape of the
// real submit flow.
struct SpottedStep: View {
    let onAdvance: () -> Void

    @State private var name: String = "Marmalade"

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                // Photo card with details.
                VStack(spacing: 0) {
                    photoHeader
                    detailsBody
                }
                .background(Color.creamSoft, in: .rect(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18).stroke(Color.stoneLight, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
                .padding(.horizontal, 24)

                pinnedLine
                    .padding(.top, 16)

                Spacer()

                VStack(spacing: 14) {
                    OnboardingDots(activeIndex: 7, count: 9)
                    OnboardingPrimaryButton(title: "Pin it on the map →", palette: .coral, action: onAdvance)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var pinnedLine: Text {
        Text("Pinned at ")
            .font(.Brand.jakarta(.regular, size: 13))
            .foregroundColor(Color.stone)
        + Text("Brick Lane, E1")
            .font(.Brand.jakarta(.bold, size: 13))
            .foregroundColor(Color.ink)
        + Text(" · just now")
            .font(.Brand.jakarta(.regular, size: 13))
            .foregroundColor(Color.stone)
    }

    private var photoHeader: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xB8A394),
                    Color(hex: 0x6B5C4F),
                    Color(hex: 0x3A322C)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Cat silhouette teaser, anchored bottom-center.
            VStack {
                Spacer()
                FirstSnapCatSilhouette()
                    .fill(Color.ink.opacity(0.85))
                    .frame(width: 120, height: 100)
                    .overlay(
                        ZStack {
                            Circle().fill(Color.streetlampYellow).frame(width: 6, height: 6)
                                .offset(x: -12, y: -2)
                            Circle().fill(Color.streetlampYellow).frame(width: 6, height: 6)
                                .offset(x: 12, y: -2)
                        }
                        .offset(y: 14)
                    )
            }

            // FIRST SNAP ★ badge, anchored top-trailing.
            VStack {
                HStack {
                    Spacer()
                    Text("FIRST SNAP ★")
                        .font(.Brand.jakarta(.bold, size: 10))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.streetlampYellow, in: .capsule)
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(height: 200)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 18, bottomLeading: 0, bottomTrailing: 0, topTrailing: 18)
            )
        )
    }

    private var detailsBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SPOTTED · NEW CAT")
                .font(.Brand.mono(size: 10))
                .foregroundStyle(Color.coral)
                .tracking(1.4)

            Text("name them.")
                .font(.Brand.frauncesBlackItalic(size: 32))
                .foregroundStyle(Color.ink)
                .tracking(-1)
                .padding(.top, 6)

            TextField("", text: $name)
                .font(.Brand.jakarta(.semibold, size: 16))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.cream, in: .rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.stoneLight, lineWidth: 1))
                .padding(.top, 14)

            // Tag chips — first two pre-selected.
            HStack(spacing: 6) {
                tagChip("orange", selected: true)
                tagChip("tabby", selected: true)
                tagChip("friendly", selected: false)
                tagChip("shy", selected: false)
                tagChip("TNR ✓", selected: false)
            }
            .padding(.top, 12)
        }
        .padding(18)
    }

    private func tagChip(_ text: String, selected: Bool) -> some View {
        Text(selected ? "✓ \(text)" : "+ \(text)")
            .font(.Brand.jakarta(.semibold, size: 12))
            .foregroundStyle(selected ? Color.coralDeep : Color.stone)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                selected ? Color(hex: 0xFFE2DC) : Color.cream,
                in: .capsule
            )
            .overlay(
                Capsule().stroke(selected ? Color.clear : Color.stoneLight, lineWidth: 1)
            )
    }
}

// Big cat silhouette used in the photo teaser. 200×140 viewBox, drawn with the
// onboarding-design path (lines 350–354 of CatSnap Onboarding.html).
private struct FirstSnapCatSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let sx = rect.width / 200
        let sy = rect.height / 140
        let pt = { (x: CGFloat, y: CGFloat) in CGPoint(x: x * sx, y: y * sy) }

        p.move(to: pt(30, 138))
        p.addLine(to: pt(30, 84))
        p.addCurve(to: pt(26, 44), control1: pt(30, 72), control2: pt(28, 56))
        p.addCurve(to: pt(36, 38), control1: pt(24, 36), control2: pt(30, 32))
        p.addCurve(to: pt(64, 76), control1: pt(46, 50), control2: pt(56, 64))
        p.addCurve(to: pt(100, 68), control1: pt(76, 70), control2: pt(90, 68))
        p.addCurve(to: pt(136, 76), control1: pt(110, 68), control2: pt(124, 70))
        p.addCurve(to: pt(164, 38), control1: pt(144, 64), control2: pt(154, 50))
        p.addCurve(to: pt(174, 44), control1: pt(170, 32), control2: pt(176, 36))
        p.addCurve(to: pt(170, 84), control1: pt(172, 56), control2: pt(170, 72))
        p.addLine(to: pt(170, 138))
        p.closeSubpath()
        return p
    }
}

#Preview {
    SpottedStep(onAdvance: {})
}
