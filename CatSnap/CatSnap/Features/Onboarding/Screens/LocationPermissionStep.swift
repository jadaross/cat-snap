import SwiftUI
import CoreLocation

// 03 · Location — sample pins on a faded mini-map, then the permission ask.
// Tapping "Enable location" fires the OS prompt; the screen advances
// regardless of grant/deny. "Maybe later" advances silently.
struct LocationPermissionStep: View {
    let onAdvance: () -> Void

    @State private var locationManager = CLLocationManager()

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    ZStack(alignment: .topLeading) {
                        OnboardingMiniMap()

                        MapPin(size: 42, bgColor: .coral, catColor: .ink, pulse: true)
                            .offset(x: w * 0.20, y: h * 0.20)

                        MapPin(size: 42, bgColor: .coral, catColor: Color(hex: 0xC97F3F))
                            .offset(x: w * 0.60, y: h * 0.30)

                        MapPin(size: 48, bgColor: .streetlampYellow, catColor: .ink, ringColor: .ink, showStar: true)
                            .offset(x: w * 0.40, y: h * 0.50)

                        MapPin(size: 38, bgColor: .coral, catColor: Color(hex: 0x3A2A1C))
                            .offset(x: w * 0.15, y: h * 0.62)

                        MapPin(size: 42, bgColor: .sage, catColor: .creamSoft, glassColor: .sage)
                            .offset(x: w * 0.70, y: h * 0.68)

                        // User dot ("you are here") — soft halo + solid pin.
                        ZStack {
                            Circle().fill(Color(hex: 0x3A7BD5).opacity(0.18))
                                .frame(width: 80, height: 80)
                            Circle().fill(Color(hex: 0x3A7BD5))
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.creamSoft, lineWidth: 3))
                                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                        }
                        .position(x: w * 0.50, y: h * 0.70)

                        // Soft fade into the cream below.
                        LinearGradient(
                            colors: [.clear, .cream],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .frame(height: 280)

                VStack(alignment: .leading, spacing: 14) {
                    Text("PERMISSIONS")
                        .font(.Brand.mono(size: 11))
                        .foregroundStyle(Color.stone)
                        .tracking(1.4)
                    Text("show me cats\nnearby.")
                        .font(.Brand.frauncesBlackItalic(size: 36))
                        .foregroundStyle(Color.ink)
                        .tracking(-1.4)
                    Text("We use your location only to show pins around you and pin new sightings. Always private.")
                        .font(.Brand.jakarta(.regular, size: 15))
                        .foregroundStyle(Color.stone)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 12) {
                    OnboardingDots(activeIndex: 2, count: 9)
                    OnboardingPrimaryButton(title: "Enable location") {
                        locationManager.requestWhenInUseAuthorization()
                        onAdvance()
                    }
                    OnboardingTextButton(title: "Maybe later", action: onAdvance)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    LocationPermissionStep(onAdvance: {})
}
