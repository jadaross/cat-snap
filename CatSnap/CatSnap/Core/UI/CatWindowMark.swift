import SwiftUI

// Ported from the JSX `Window` component in
// ~/Downloads/cat-snap-branding-and-design/CatSnap Brand System.html (lines 33–56).
// Drawn in a 200×200 SVG-style coordinate space, then scaled to `size`.
// Frame stroke and sill height = 14u, mullions = 4u.
struct CatWindowMark: View {
    var size: CGFloat = 200
    var showSill: Bool = true
    var frameColor: Color = .coral
    var glassColor: Color = .cream
    var catColor: Color = .ink
    var scleraColor: Color = .creamSoft
    var noseColor: Color = .coralDeep
    var blink: Bool = false

    private static let canvasUnit: CGFloat = 200

    var body: some View {
        let glassHeight: CGFloat = showSill ? 132 : 136
        let outerHeight: CGFloat = showSill ? 152 : 156
        let mullionBottom: CGFloat = showSill ? 164 : 168

        ZStack(alignment: .topLeading) {
            if showSill {
                RoundedRectangle(cornerRadius: 2)
                    .fill(frameColor)
                    .frame(width: 172, height: 14)
                    .offset(x: 14, y: 170)
            }

            RoundedRectangle(cornerRadius: 6)
                .fill(frameColor)
                .frame(width: 156, height: outerHeight)
                .offset(x: 22, y: 22)

            RoundedRectangle(cornerRadius: 2)
                .fill(glassColor)
                .frame(width: 136, height: glassHeight)
                .offset(x: 32, y: 32)

            // Cat silhouette + eyes + nose, clipped to the glass pane.
            ZStack(alignment: .topLeading) {
                CatSilhouette()
                    .fill(catColor)
                    .frame(width: Self.canvasUnit, height: Self.canvasUnit)

                Eye(scleraColor: scleraColor, pupilColor: catColor, blink: blink)
                    .frame(width: 16, height: 16)
                    .offset(x: 76, y: 130)

                Eye(scleraColor: scleraColor, pupilColor: catColor, blink: blink)
                    .frame(width: 16, height: 16)
                    .offset(x: 120, y: 130)

                NoseTriangle()
                    .fill(noseColor)
                    .frame(width: 8, height: 6)
                    .offset(x: 102, y: 152)
            }
            .frame(width: Self.canvasUnit, height: Self.canvasUnit, alignment: .topLeading)
            .clipShape(
                RoundedRectangle(cornerRadius: 2)
                    .offset(x: 32, y: 32)
                    .size(width: 136, height: glassHeight)
            )

            Rectangle()
                .fill(frameColor)
                .frame(width: 4, height: mullionBottom - 32)
                .offset(x: 98, y: 32)

            Rectangle()
                .fill(frameColor)
                .frame(width: 136, height: 4)
                .offset(x: 32, y: 96)
        }
        .frame(width: Self.canvasUnit, height: Self.canvasUnit, alignment: .topLeading)
        .scaleEffect(size / Self.canvasUnit, anchor: .topLeading)
        .frame(width: size, height: size)
    }
}

private struct CatSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Direct port of the SVG `d` attribute, in 200-unit space.
        path.move(to: CGPoint(x: 50, y: 200))
        path.addLine(to: CGPoint(x: 50, y: 124))
        path.addCurve(to: CGPoint(x: 46, y: 94),
                      control1: CGPoint(x: 50, y: 116),
                      control2: CGPoint(x: 48, y: 104))
        path.addCurve(to: CGPoint(x: 56, y: 88),
                      control1: CGPoint(x: 44, y: 86),
                      control2: CGPoint(x: 50, y: 82))
        path.addCurve(to: CGPoint(x: 80, y: 116),
                      control1: CGPoint(x: 64, y: 96),
                      control2: CGPoint(x: 72, y: 106))
        path.addCurve(to: CGPoint(x: 108, y: 108),
                      control1: CGPoint(x: 90, y: 110),
                      control2: CGPoint(x: 100, y: 108))
        path.addCurve(to: CGPoint(x: 136, y: 116),
                      control1: CGPoint(x: 116, y: 108),
                      control2: CGPoint(x: 126, y: 110))
        path.addCurve(to: CGPoint(x: 160, y: 88),
                      control1: CGPoint(x: 144, y: 106),
                      control2: CGPoint(x: 152, y: 96))
        path.addCurve(to: CGPoint(x: 170, y: 94),
                      control1: CGPoint(x: 166, y: 82),
                      control2: CGPoint(x: 172, y: 86))
        path.addCurve(to: CGPoint(x: 166, y: 124),
                      control1: CGPoint(x: 168, y: 104),
                      control2: CGPoint(x: 166, y: 116))
        path.addLine(to: CGPoint(x: 166, y: 200))
        path.closeSubpath()
        return path
    }
}

private struct Eye: View {
    var scleraColor: Color
    var pupilColor: Color
    var blink: Bool
    @State private var closed: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(scleraColor)
                .frame(width: 11, height: 11)
                .scaleEffect(y: closed ? 0.1 : 1, anchor: .center)
            Circle()
                .fill(pupilColor)
                .frame(width: 4.4, height: 4.4)
                .offset(x: 3.3, y: 2.8)
                .scaleEffect(y: closed ? 0.1 : 1, anchor: .center)
        }
        .onAppear {
            guard blink else { return }
            // 4s loop: 200ms blink, ~3.8s open. Animation is best-effort in the
            // brand mark; refine when this gets used in a hero/onboarding moment.
            Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.1)) { closed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.1)) { closed = false }
                }
            }
        }
    }
}

private struct NoseTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 32) {
        CatWindowMark(size: 200)
        CatWindowMark(size: 80, showSill: false)
    }
    .padding()
    .background(Color.cream)
}
