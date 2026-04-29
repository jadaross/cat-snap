import SwiftUI

// Custom-stroke glyphs for the bottom tab bar. Paths are authored in a 24x24
// coordinate space (matching the JSX SVGs in the design handoff) and scaled
// to fit whatever frame the Shape is rendered in.

struct ExploreGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        var path = Path()

        // Folded map outline
        path.move(to: CGPoint(x: 9, y: 4))
        path.addLine(to: CGPoint(x: 3, y: 6))
        path.addLine(to: CGPoint(x: 3, y: 20))
        path.addLine(to: CGPoint(x: 9, y: 18))
        path.addLine(to: CGPoint(x: 15, y: 20))
        path.addLine(to: CGPoint(x: 21, y: 18))
        path.addLine(to: CGPoint(x: 21, y: 4))
        path.addLine(to: CGPoint(x: 15, y: 6))
        path.addLine(to: CGPoint(x: 9, y: 4))
        path.closeSubpath()

        // Creases
        path.move(to: CGPoint(x: 9, y: 4))
        path.addLine(to: CGPoint(x: 9, y: 18))
        path.move(to: CGPoint(x: 15, y: 6))
        path.addLine(to: CGPoint(x: 15, y: 20))

        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

struct ProfileGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        var path = Path()

        // Head
        path.addEllipse(in: CGRect(x: 8, y: 4, width: 8, height: 8))

        // Shoulders / body curve: M4 21c0-4 4-7 8-7s8 3 8 7
        path.move(to: CGPoint(x: 4, y: 21))
        path.addCurve(
            to: CGPoint(x: 12, y: 14),
            control1: CGPoint(x: 4, y: 17),
            control2: CGPoint(x: 8, y: 14)
        )
        path.addCurve(
            to: CGPoint(x: 20, y: 21),
            control1: CGPoint(x: 16, y: 14),
            control2: CGPoint(x: 20, y: 17)
        )

        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// Bookmark/journal-corner icon used by the Explore tab's "Guide" toggle button
// (`CatSnap App.html:248`). Squared shape with a single rounded corner top-right
// and a fold curving in from the bottom-left.
struct GuideGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        var path = Path()

        // Outline: M4 4 h12 a4 4 0 014 4 v12 H8 a4 4 0 01-4-4 V4 z
        path.move(to: CGPoint(x: 4, y: 4))
        path.addLine(to: CGPoint(x: 16, y: 4))
        path.addArc(
            center: CGPoint(x: 16, y: 8), radius: 4,
            startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addLine(to: CGPoint(x: 8, y: 20))
        path.addArc(
            center: CGPoint(x: 8, y: 16), radius: 4,
            startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        path.addLine(to: CGPoint(x: 4, y: 4))
        path.closeSubpath()

        // Inner fold: M4 16 a4 4 0 014-4 h12
        path.move(to: CGPoint(x: 4, y: 16))
        path.addArc(
            center: CGPoint(x: 8, y: 16), radius: 4,
            startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.addLine(to: CGPoint(x: 20, y: 12))

        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

struct CameraGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        var path = Path()

        // Body — rounded rectangle with a prism cutout on top, radius 2
        path.move(to: CGPoint(x: 5, y: 6))
        path.addLine(to: CGPoint(x: 7.5, y: 6))
        path.addLine(to: CGPoint(x: 9, y: 4))
        path.addLine(to: CGPoint(x: 15, y: 4))
        path.addLine(to: CGPoint(x: 16.5, y: 6))
        path.addLine(to: CGPoint(x: 19, y: 6))
        // Top-right corner
        path.addArc(
            center: CGPoint(x: 19, y: 8),
            radius: 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 21, y: 18))
        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: 19, y: 18),
            radius: 2,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 5, y: 20))
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: 5, y: 18),
            radius: 2,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 3, y: 8))
        // Top-left corner
        path.addArc(
            center: CGPoint(x: 5, y: 8),
            radius: 2,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()

        // Lens
        path.addEllipse(in: CGRect(x: 8, y: 9, width: 8, height: 8))

        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}
