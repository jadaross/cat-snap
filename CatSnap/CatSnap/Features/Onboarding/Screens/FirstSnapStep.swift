import SwiftUI

// 07 · First snap — illustrative camera UI. Tapping the shutter advances.
// No real capture happens here — the real submit flow lives in the Submit tab.
struct FirstSnapStep: View {
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            // Faux viewfinder gradient + warm hint.
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x3A3530), location: 0),
                    .init(color: Color(hex: 0x1C1917), location: 0.6),
                    .init(color: Color(hex: 0x0D0A08), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Warm radial hint of a cat shape.
            RadialGradient(
                colors: [Color.coralDeep.opacity(0.19), .clear],
                center: UnitPoint(x: 0.5, y: 0.6),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            // Corner reticles.
            GeometryReader { geo in
                ZStack {
                    reticleCorner(rotation: 0)
                        .position(x: 38, y: 94)
                    reticleCorner(rotation: 90)
                        .position(x: geo.size.width - 38, y: 94)
                    reticleCorner(rotation: 270)
                        .position(x: 38, y: geo.size.height - 214)
                    reticleCorner(rotation: 180)
                        .position(x: geo.size.width - 38, y: geo.size.height - 214)
                }
            }

            VStack(spacing: 0) {
                // Top tip card.
                HStack(spacing: 10) {
                    Text("1")
                        .font(.Brand.frauncesBlackItalic(size: 18))
                        .foregroundStyle(Color.creamSoft)
                        .frame(width: 36, height: 36)
                        .background(Color.coral, in: .circle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("your first snap")
                            .font(.Brand.jakarta(.bold, size: 14))
                            .foregroundStyle(Color.ink)
                        Text("Frame the cat. Doesn't need to be perfect — they don't pose.")
                            .font(.Brand.jakarta(.regular, size: 12))
                            .foregroundStyle(Color.stone)
                            .lineSpacing(2)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.creamSoft.opacity(0.95), in: .rect(cornerRadius: 14))
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 24)

                Spacer()

                // Shutter row.
                HStack {
                    Spacer()

                    Button {} label: {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.creamSoft)
                            .frame(width: 44, height: 44)
                            .background(Color.creamSoft.opacity(0.12), in: .circle)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Shutter — advances to S8.
                    Button(action: onAdvance) {
                        Circle()
                            .fill(Color.creamSoft)
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(Color.creamSoft, lineWidth: 2).padding(-6))
                            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {} label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.creamSoft)
                            .frame(width: 44, height: 44)
                            .background(Color.creamSoft.opacity(0.12), in: .circle)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
    }

    private func reticleCorner(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 1, y: 14))
            path.addLine(to: CGPoint(x: 1, y: 1))
            path.addLine(to: CGPoint(x: 14, y: 1))
        }
        .stroke(Color.creamSoft, lineWidth: 2)
        .frame(width: 28, height: 28)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    FirstSnapStep(onAdvance: {})
}
