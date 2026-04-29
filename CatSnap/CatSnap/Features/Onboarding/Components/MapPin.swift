import SwiftUI

// Teardrop map pin with a cat face inset behind a circular "glass" — direct port
// of the JSX `Pin` component in CatSnap Onboarding.html (lines 64–86). Drawn in
// a 100×128 unit space, then uniformly scaled to `size`.
//
// `pulse` adds a 2s scale+fade ring, `ringColor` adds a stroke around the body,
// `showStar` drops a black ★ near the tip (used for legendary).
struct MapPin: View {
    var size: CGFloat = 56
    var bgColor: Color = .coral
    var catColor: Color = .ink
    var glassColor: Color = .creamSoft
    var ringColor: Color? = nil
    var pulse: Bool = false
    var showStar: Bool = false

    private static let unitW: CGFloat = 100
    private static let unitH: CGFloat = 128

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Pulse ring centered over the face (cx≈50, cy≈50 in unit space).
            if pulse {
                PinPulseRing(color: bgColor)
                    .frame(width: 85, height: 85)
                    .offset(x: 7.5, y: 7.5)
            }

            // Teardrop body with shadow.
            TeardropShape()
                .fill(bgColor)
                .frame(width: Self.unitW, height: Self.unitH)
                .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 3)

            // Optional ring stroke.
            if let ringColor {
                TeardropShape()
                    .stroke(ringColor, lineWidth: 3)
                    .frame(width: Self.unitW, height: Self.unitH)
            }

            // Glass face.
            Circle()
                .fill(glassColor)
                .frame(width: 60, height: 60)
                .offset(x: 20, y: 16)

            // Cat silhouette + eyes + nose, clipped to the glass.
            ZStack(alignment: .topLeading) {
                PinCatSilhouette()
                    .fill(catColor)
                    .frame(width: Self.unitW, height: Self.unitH)

                Circle().fill(Color.creamSoft).frame(width: 6, height: 6).offset(x: 37, y: 45)
                Circle().fill(Color.creamSoft).frame(width: 6, height: 6).offset(x: 57, y: 45)
                Circle().fill(catColor).frame(width: 2.6, height: 2.6).offset(x: 39.2, y: 46.2)
                Circle().fill(catColor).frame(width: 2.6, height: 2.6).offset(x: 59.2, y: 46.2)

                PinNoseTriangle()
                    .fill(Color.coralDeep)
                    .frame(width: 8, height: 4)
                    .offset(x: 46, y: 56)
            }
            .frame(width: Self.unitW, height: Self.unitH, alignment: .topLeading)
            .clipShape(GlassFaceClip())

            // Star at the pin's tip.
            if showStar {
                Text("★")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color.ink)
                    .frame(width: 20, height: 14, alignment: .center)
                    .offset(x: 40, y: 92)
            }
        }
        .frame(width: Self.unitW, height: Self.unitH, alignment: .topLeading)
        .scaleEffect(size / Self.unitW, anchor: .topLeading)
        // Pin the scaled content to the top-left of the visual box so it
        // doesn't drift up-left when laid out at a smaller size.
        .frame(width: size, height: size * 1.28, alignment: .topLeading)
    }
}

private struct TeardropShape: Shape {
    // Source path: M 50 4 C 25 4 6 23 6 48 C 6 78 50 124 50 124 C 50 124 94 78 94 48 C 94 23 75 4 50 4 Z
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 50, y: 4))
        p.addCurve(to: CGPoint(x: 6, y: 48),
                   control1: CGPoint(x: 25, y: 4),
                   control2: CGPoint(x: 6, y: 23))
        p.addCurve(to: CGPoint(x: 50, y: 124),
                   control1: CGPoint(x: 6, y: 78),
                   control2: CGPoint(x: 50, y: 124))
        p.addCurve(to: CGPoint(x: 94, y: 48),
                   control1: CGPoint(x: 50, y: 124),
                   control2: CGPoint(x: 94, y: 78))
        p.addCurve(to: CGPoint(x: 50, y: 4),
                   control1: CGPoint(x: 94, y: 23),
                   control2: CGPoint(x: 75, y: 4))
        p.closeSubpath()
        return p
    }
}

private struct PinCatSilhouette: Shape {
    // Source: M 26 88 L 26 64 C 26 58 24 52 22 46 C 21 42 25 40 28 44 C 33 50 39 56 44 60
    //         C 47 58 50 58 53 58 C 56 58 59 58 62 60 C 67 56 73 50 78 44 C 81 40 85 42 84 46
    //         C 82 52 80 58 80 64 L 80 88 Z
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 26, y: 88))
        p.addLine(to: CGPoint(x: 26, y: 64))
        p.addCurve(to: CGPoint(x: 22, y: 46), control1: CGPoint(x: 26, y: 58), control2: CGPoint(x: 24, y: 52))
        p.addCurve(to: CGPoint(x: 28, y: 44), control1: CGPoint(x: 21, y: 42), control2: CGPoint(x: 25, y: 40))
        p.addCurve(to: CGPoint(x: 44, y: 60), control1: CGPoint(x: 33, y: 50), control2: CGPoint(x: 39, y: 56))
        p.addCurve(to: CGPoint(x: 53, y: 58), control1: CGPoint(x: 47, y: 58), control2: CGPoint(x: 50, y: 58))
        p.addCurve(to: CGPoint(x: 62, y: 60), control1: CGPoint(x: 56, y: 58), control2: CGPoint(x: 59, y: 58))
        p.addCurve(to: CGPoint(x: 78, y: 44), control1: CGPoint(x: 67, y: 56), control2: CGPoint(x: 73, y: 50))
        p.addCurve(to: CGPoint(x: 84, y: 46), control1: CGPoint(x: 81, y: 40), control2: CGPoint(x: 85, y: 42))
        p.addCurve(to: CGPoint(x: 80, y: 64), control1: CGPoint(x: 82, y: 52), control2: CGPoint(x: 80, y: 58))
        p.addLine(to: CGPoint(x: 80, y: 88))
        p.closeSubpath()
        return p
    }
}

private struct PinNoseTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        p.closeSubpath()
        return p
    }
}

private struct GlassFaceClip: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(x: 20, y: 16, width: 60, height: 60))
    }
}

private struct PinPulseRing: View {
    var color: Color
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color)
            .opacity(animate ? 0 : 0.6)
            .scaleEffect(animate ? 2.2 : 1)
            .animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: animate)
            .onAppear { animate = true }
    }
}

#Preview {
    HStack(spacing: 24) {
        MapPin(size: 56)
        MapPin(size: 56, bgColor: .streetlampYellow, catColor: .ink, ringColor: .ink, showStar: true)
        MapPin(size: 56, bgColor: .sage, catColor: .creamSoft, glassColor: .sage, pulse: true)
    }
    .padding()
    .background(Color.cream)
}
