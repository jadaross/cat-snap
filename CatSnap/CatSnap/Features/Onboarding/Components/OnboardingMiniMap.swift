import SwiftUI

// Decorative map background — port of the JSX `MiniMap` component in
// CatSnap Onboarding.html (lines 88–104). 400×600 unit space, drawn via
// Canvas and scaled to fill (cover) the container, anchored top-left.
//
// Pin overlays are NOT a child of this view — the parent stacks pins over
// the map using a ZStack + GeometryReader percentages.
struct OnboardingMiniMap: View {
    var body: some View {
        ZStack {
            Color.cream
            Canvas { context, size in
                let unitW: CGFloat = 400
                let unitH: CGFloat = 600
                let scale = max(size.width / unitW, size.height / unitH)
                context.scaleBy(x: scale, y: scale)

                // Park blob (top-left).
                var parkA = Path()
                parkA.move(to: CGPoint(x: 30, y: 80))
                parkA.addQuadCurve(to: CGPoint(x: 160, y: 90), control: CGPoint(x: 100, y: 60))
                parkA.addLine(to: CGPoint(x: 170, y: 160))
                parkA.addQuadCurve(to: CGPoint(x: 40, y: 150), control: CGPoint(x: 100, y: 180))
                parkA.closeSubpath()
                context.fill(parkA, with: .color(Color(hex: 0xDEE6DC).opacity(0.7)))

                // Park blob (right, circular).
                let parkB = Path(ellipseIn: CGRect(x: 270, y: 130, width: 100, height: 100))
                context.fill(parkB, with: .color(Color(hex: 0xDEE6DC).opacity(0.7)))

                // River band across the middle.
                let h: CGFloat = 600
                var river = Path()
                river.move(to: CGPoint(x: 0, y: h * 0.55))
                river.addQuadCurve(to: CGPoint(x: 240, y: h * 0.58), control: CGPoint(x: 120, y: h * 0.50))
                river.addQuadCurve(to: CGPoint(x: 400, y: h * 0.60), control: CGPoint(x: 320, y: h * 0.62))
                river.addLine(to: CGPoint(x: 400, y: h * 0.65))
                river.addQuadCurve(to: CGPoint(x: 240, y: h * 0.62), control: CGPoint(x: 320, y: h * 0.67))
                river.addQuadCurve(to: CGPoint(x: 0, y: h * 0.60), control: CGPoint(x: 120, y: h * 0.55))
                river.closeSubpath()
                context.fill(river, with: .color(Color(hex: 0xCFD9E0).opacity(0.6)))

                // Faint road grid.
                let roadColor = Color.stone.opacity(0.3)

                var rh1 = Path()
                rh1.move(to: CGPoint(x: 0, y: h * 0.37))
                rh1.addLine(to: CGPoint(x: 400, y: h * 0.40))
                context.stroke(rh1, with: .color(roadColor), lineWidth: 2.5)

                var rh2 = Path()
                rh2.move(to: CGPoint(x: 0, y: h * 0.77))
                rh2.addLine(to: CGPoint(x: 400, y: h * 0.73))
                context.stroke(rh2, with: .color(roadColor), lineWidth: 2.5)

                var rv1 = Path()
                rv1.move(to: CGPoint(x: 140, y: 0))
                rv1.addLine(to: CGPoint(x: 160, y: 600))
                context.stroke(rv1, with: .color(roadColor), lineWidth: 2.5)

                var rv2 = Path()
                rv2.move(to: CGPoint(x: 300, y: 0))
                rv2.addLine(to: CGPoint(x: 320, y: 600))
                context.stroke(rv2, with: .color(roadColor), lineWidth: 2.5)
            }
        }
        .clipped()
    }
}
