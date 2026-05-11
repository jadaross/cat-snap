import SwiftUI

// Teardrop map pin matching the PhotoPin in the design handoff
// (`CatSnap App.html` lines 196–233). A coral teardrop with a circular
// photo frame on top and a tail pointing down at the geographic anchor.
struct CatPin: View {
    let photoUrl: URL?
    var isSelected: Bool = false
    var size: CGFloat = 84

    var body: some View {
        let outerSize = isSelected ? size * 1.13 : size
        let height = outerSize * Self.heightRatio

        ZStack {
            TeardropPinShape()
                .fill(isSelected ? Color.streetlampYellow : Color.coral)

            // Inner photo circle: cream backdrop + clipped photo
            Circle()
                .fill(Color.creamSoft)
                .frame(width: outerSize * Self.photoRatio, height: outerSize * Self.photoRatio)
                .offset(y: photoYOffset(height: height))

            AsyncCatImage(url: photoUrl)
                .frame(width: outerSize * Self.photoRatio, height: outerSize * Self.photoRatio)
                .clipShape(Circle())
                .offset(y: photoYOffset(height: height))
        }
        .frame(width: outerSize, height: height)
        .shadow(color: Color.ink.opacity(0.25), radius: 4, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // Derived from the design's 100x132 viewBox (`CatSnap App.html:198`).
    private static let heightRatio: CGFloat = 1.32     // 132 / 100
    private static let photoRatio: CGFloat = 0.72      // photo r=36 → d=72 of 100

    private func photoYOffset(height: CGFloat) -> CGFloat {
        // Photo centre is at y=46 in a 132-tall canvas; the frame centre is at
        // y=66, so the photo sits 20 units above centre.
        -((66.0 - 46.0) / 132.0) * height
    }
}

struct TeardropPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 100
        let scaleY = rect.height / 132

        var path = Path()

        // Teardrop tail: M 50 80 L 38 100 L 50 124 L 62 100 Z
        path.move(to: CGPoint(x: 50, y: 80))
        path.addLine(to: CGPoint(x: 38, y: 100))
        path.addLine(to: CGPoint(x: 50, y: 124))
        path.addLine(to: CGPoint(x: 62, y: 100))
        path.closeSubpath()

        // Outer photo ring: circle cx=50 cy=46 r=42
        path.addEllipse(in: CGRect(x: 8, y: 4, width: 84, height: 84))

        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

#Preview {
    HStack(spacing: 16) {
        CatPin(photoUrl: nil)
        CatPin(photoUrl: nil, isSelected: true)
    }
    .padding()
    .background(Color.cream)
}
