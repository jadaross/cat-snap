import SwiftUI
import AVFoundation

// 04 · Camera — dark viewfinder mock, coral camera button, "Allow camera" CTA.
struct CameraPermissionStep: View {
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            // Subtle viewfinder frame + coral corner reticles.
            GeometryReader { geo in
                let inset: CGFloat = 60
                let bottomInset: CGFloat = 200
                let cornerSize: CGFloat = 24
                let weight: CGFloat = 2

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.creamSoft.opacity(0.15), lineWidth: 2)
                    .padding(.horizontal, inset)
                    .padding(.top, inset)
                    .padding(.bottom, bottomInset)

                // Top-left corner.
                cornerMark(width: cornerSize, weight: weight, edges: [.top, .leading])
                    .offset(x: inset, y: inset)
                // Top-right corner.
                cornerMark(width: cornerSize, weight: weight, edges: [.top, .trailing])
                    .offset(x: geo.size.width - inset - cornerSize, y: inset)
                // Bottom-left.
                cornerMark(width: cornerSize, weight: weight, edges: [.bottom, .leading])
                    .offset(x: inset, y: geo.size.height - bottomInset - cornerSize)
                // Bottom-right.
                cornerMark(width: cornerSize, weight: weight, edges: [.bottom, .trailing])
                    .offset(x: geo.size.width - inset - cornerSize, y: geo.size.height - bottomInset - cornerSize)
            }

            VStack(spacing: 0) {
                Spacer()

                // Camera glyph.
                ZStack {
                    Circle()
                        .fill(Color.coral)
                        .frame(width: 110, height: 110)
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 8)
                        .overlay(
                            Circle().stroke(Color.creamSoft.opacity(0.10), lineWidth: 6)
                        )

                    Image(systemName: "camera")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundStyle(Color.creamSoft)
                }

                Text("aim, snap,\nspot.")
                    .font(.Brand.frauncesBlackItalic(size: 36))
                    .foregroundStyle(Color.creamSoft)
                    .tracking(-1.4)
                    .multilineTextAlignment(.center)
                    .padding(.top, 36)

                Text("We need camera access so you can take that first cat photo. Photos stay yours.")
                    .font(.Brand.jakarta(.regular, size: 15))
                    .foregroundStyle(Color(hex: 0xA8A29E))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 14)
                    .padding(.horizontal, 32)
                    .frame(maxWidth: 320)

                Spacer()

                VStack(spacing: 12) {
                    OnboardingDots(
                        activeIndex: 3,
                        count: 9,
                        activeColor: .creamSoft,
                        inactiveColor: Color.creamSoft.opacity(0.25)
                    )
                    OnboardingPrimaryButton(title: "Allow camera", palette: .coral) {
                        AVCaptureDevice.requestAccess(for: .video) { _ in }
                        onAdvance()
                    }
                    OnboardingTextButton(
                        title: "Use photo library instead",
                        color: Color(hex: 0xA8A29E),
                        action: onAdvance
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder
    private func cornerMark(width: CGFloat, weight: CGFloat, edges: Edge.Set) -> some View {
        ZStack(alignment: .topLeading) {
            // top edge
            if edges.contains(.top) {
                Rectangle()
                    .fill(Color.coral)
                    .frame(width: width, height: weight)
                    .offset(x: 0, y: 0)
            }
            // bottom edge
            if edges.contains(.bottom) {
                Rectangle()
                    .fill(Color.coral)
                    .frame(width: width, height: weight)
                    .offset(x: 0, y: width - weight)
            }
            // leading edge
            if edges.contains(.leading) {
                Rectangle()
                    .fill(Color.coral)
                    .frame(width: weight, height: width)
                    .offset(x: 0, y: 0)
            }
            // trailing edge
            if edges.contains(.trailing) {
                Rectangle()
                    .fill(Color.coral)
                    .frame(width: weight, height: width)
                    .offset(x: width - weight, y: 0)
            }
        }
        .frame(width: width, height: width, alignment: .topLeading)
    }
}

#Preview {
    CameraPermissionStep(onAdvance: {})
}
