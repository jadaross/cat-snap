import SwiftUI

// Coral floating chip on the map view that surfaces the most recent
// sighting nearby. Source: `CatSnap App.html` lines 360–365 (live ticker
// inside Spots map view).
struct LiveTickerChip: View {
    let title: String
    let timestamp: String
    var onTap: (() -> Void)? = nil

    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 0.5

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                pulseDot

                Text(title)
                    .font(.Brand.jakarta(.bold, size: 12))
                    .tracking(0.2)
                    .foregroundStyle(Color.creamSoft)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(timestamp)
                    .font(.Brand.mono(size: 10))
                    .foregroundStyle(Color.creamSoft.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.coral, in: .rect(cornerRadius: 12))
            .shadow(color: Color.coral.opacity(0.35), radius: 7, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var pulseDot: some View {
        ZStack {
            Circle()
                .fill(Color.creamSoft)
                .frame(width: 6, height: 6)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
            Circle()
                .fill(Color.creamSoft)
                .frame(width: 6, height: 6)
        }
        .frame(width: 14, height: 14)
        .onAppear {
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                pulseScale = 2.4
                pulseOpacity = 0
            }
        }
    }
}

#Preview {
    LiveTickerChip(
        title: "Marmalade just spotted · 60m away",
        timestamp: "2m"
    )
    .padding()
    .background(Color.cream)
}
