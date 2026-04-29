import Foundation
import CoreLocation

@Observable
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var lastLocation: CLLocation?
    private(set) var isResolving = false

    private var continuation: CheckedContinuation<CLLocation, Error>?

    enum LocationError: LocalizedError {
        case denied
        case timeout

        var errorDescription: String? {
            switch self {
            case .denied:  return "Location access is off. Enable it in Settings → Cat-Snap."
            case .timeout: return "Couldn't get your location. Try again outside or near a window."
            }
        }
    }

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// One-shot location fix. Awaits authorization if not yet decided.
    func requestOneShot() async throws -> CLLocation {
        switch authorizationStatus {
        case .notDetermined:
            requestAuthorization()
        case .denied, .restricted:
            throw LocationError.denied
        default:
            break
        }

        isResolving = true
        defer { isResolving = false }

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            self.manager.requestLocation()
        }
    }

    func reverseGeocode(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return nil
        }
        // "Brick Lane, E1" — thoroughfare or sublocality, plus postal code prefix.
        let line1 = placemark.thoroughfare ?? placemark.subLocality ?? placemark.locality
        let line2 = placemark.postalCode.flatMap { $0.split(separator: " ").first.map(String.init) }
        return [line1, line2].compactMap { $0 }.joined(separator: ", ").nilIfEmpty
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .denied || status == .restricted {
                continuation?.resume(throwing: LocationError.denied)
                continuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.lastLocation = location
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
