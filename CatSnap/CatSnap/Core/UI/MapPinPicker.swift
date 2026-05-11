import SwiftUI
import MapKit

// Reusable map preview with a pin pinned to the visual centre. Pan the map
// to reposition the pin; the binding updates as the camera settles. The
// "centre on me" button drops the pin on the user's current location.
//
// Used by:
//   - SubmitView (override the photo's EXIF / device location before submit)
//   - SpotConfirmSheet (no-photo "I spotted them" check-in confirmation)
struct MapPinPicker: View {
    @Binding var coordinate: CLLocationCoordinate2D
    var height: CGFloat = 180
    /// Optional callback fired when the user taps the recentre button.
    /// The picker drops the pin on the returned coordinate (typically the
    /// user's current device location).
    var onRecentre: (() async -> CLLocationCoordinate2D?)? = nil

    @State private var cameraPosition: MapCameraPosition

    init(
        coordinate: Binding<CLLocationCoordinate2D>,
        height: CGFloat = 180,
        onRecentre: (() async -> CLLocationCoordinate2D?)? = nil
    ) {
        self._coordinate = coordinate
        self.height = height
        self.onRecentre = onRecentre
        let initial = coordinate.wrappedValue
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: initial,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        ))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition)
                .mapStyle(.standard(elevation: .flat))
                .onMapCameraChange(frequency: .onEnd) { context in
                    coordinate = context.region.center
                }

            // Fixed pin overlay that "drops" onto the map's centre.
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.coral)
                .shadow(color: Color.ink.opacity(0.35), radius: 4, y: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            if onRecentre != nil {
                Button {
                    Task {
                        if let next = await onRecentre?() {
                            coordinate = next
                            withAnimation {
                                cameraPosition = .region(
                                    MKCoordinateRegion(
                                        center: next,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    )
                                )
                            }
                        }
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.coral)
                        .frame(width: 36, height: 36)
                        .background(Color.creamSoft, in: .circle)
                        .shadow(color: Color.ink.opacity(0.18), radius: 4, y: 2)
                }
                .accessibilityLabel("centre on my location")
                .padding(8)
            }
        }
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
    }
}
