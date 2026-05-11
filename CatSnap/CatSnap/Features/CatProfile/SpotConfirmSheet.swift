import SwiftUI
import CoreLocation
import Supabase
import PostgREST

// "I spotted them" — no-photo check-in confirmation. Drops a pin at the
// user's current location (or last-known) and lets them adjust before
// posting. On confirm, hits the record_spot RPC and posts the
// .sightingSubmitted notification so the map refreshes.
struct SpotConfirmSheet: View {
    let catId: UUID
    let catName: String?
    var onConfirmed: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var locationManager = LocationManager()
    @State private var coordinate: CLLocationCoordinate2D = .init(latitude: 51.5074, longitude: -0.1278)
    @State private var locationLabel: String?
    @State private var stage: Stage = .acquiringLocation
    @State private var errorMessage: String?

    enum Stage: Equatable {
        case acquiringLocation
        case ready
        case submitting
        case error(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            grabber
                .padding(.top, 10)

            Text("did you spot \(displayName)?")
                .font(.Brand.frauncesBlackItalic(size: 26))
                .tracking(-0.6)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 18)

            Text("we'll log a sighting with no photo at this location.")
                .font(.Brand.jakarta(.regular, size: 13))
                .foregroundStyle(Color.stone)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 6)

            mapBody
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if let label = locationLabel, !label.isEmpty {
                Text(label.uppercased())
                    .font(.Brand.mono(size: 10))
                    .tracking(0.8)
                    .foregroundStyle(Color.stone)
                    .padding(.top, 8)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.Brand.jakarta(.medium, size: 13))
                    .foregroundStyle(Color.coralDeep)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
            }

            Spacer(minLength: 0)

            confirmButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color.cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .task { await acquireLocation() }
        .onChange(of: coordinate.latitude) { _, _ in scheduleReverseGeocode() }
        .onChange(of: coordinate.longitude) { _, _ in scheduleReverseGeocode() }
    }

    @ViewBuilder
    private var mapBody: some View {
        switch stage {
        case .acquiringLocation:
            ZStack {
                Color.creamSoft
                ProgressView().tint(Color.coral)
            }
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stoneLight, lineWidth: 1))
        case .ready, .submitting, .error:
            MapPinPicker(
                coordinate: $coordinate,
                height: 200,
                onRecentre: {
                    let next = try? await locationManager.requestOneShot()
                    return next?.coordinate
                }
            )
        }
    }

    private var confirmButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Text(buttonLabel)
                .font(.Brand.jakarta(.bold, size: 16))
                .foregroundStyle(Color.creamSoft)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.coral, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(stage == .submitting || stage == .acquiringLocation)
        .opacity((stage == .submitting || stage == .acquiringLocation) ? 0.6 : 1)
    }

    private var buttonLabel: String {
        switch stage {
        case .submitting:        return "logging spot…"
        case .acquiringLocation: return "getting your location…"
        default:                 return "confirm spot"
        }
    }

    private var displayName: String {
        let trimmed = (catName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "this cat" : trimmed.lowercased()
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.stoneLight)
            .frame(width: 36, height: 4)
    }

    // MARK: - Behaviour

    private func acquireLocation() async {
        do {
            let location = try await locationManager.requestOneShot()
            coordinate = location.coordinate
            locationLabel = await locationManager.reverseGeocode(location)
            stage = .ready
        } catch {
            // Fallback: keep the default centre so the user can still drop a pin.
            stage = .ready
            errorMessage = "couldn't read your location — drop a pin manually."
        }
    }

    @State private var reverseGeocodeTask: Task<Void, Never>?

    private func scheduleReverseGeocode() {
        reverseGeocodeTask?.cancel()
        let target = coordinate
        reverseGeocodeTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            let label = await locationManager.reverseGeocode(
                CLLocation(latitude: target.latitude, longitude: target.longitude)
            )
            if Task.isCancelled { return }
            await MainActor.run { self.locationLabel = label }
        }
    }

    private func submit() async {
        stage = .submitting
        errorMessage = nil

        let payload = RecordSpotPayload(
            catId: catId,
            lat: coordinate.latitude,
            lng: coordinate.longitude,
            locationLabel: locationLabel,
            seenAt: Date()
        )

        do {
            _ = try await supabase
                .rpc("record_spot", params: payload)
                .execute()
            NotificationCenter.default.post(name: .sightingSubmitted, object: nil)
            onConfirmed()
            dismiss()
        } catch {
            stage = .error(error.localizedDescription)
            errorMessage = "couldn't log spot — please try again."
        }
    }
}

private struct RecordSpotPayload: Encodable {
    let catId: UUID
    let lat: Double
    let lng: Double
    let locationLabel: String?
    let seenAt: Date

    enum CodingKeys: String, CodingKey {
        case catId          = "p_cat_id"
        case lat            = "p_lat"
        case lng            = "p_lng"
        case locationLabel  = "p_location_label"
        case seenAt         = "p_seen_at"
    }
}
