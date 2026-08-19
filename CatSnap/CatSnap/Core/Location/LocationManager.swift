import Foundation
import CoreLocation

@Observable
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var lastLocation: CLLocation?
    private(set) var isResolving = false

    private var authContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    enum LocationError: LocalizedError {
        case denied
        case unavailable

        var errorDescription: String? {
            switch self {
            case .denied:      return "Location access is off. Enable it in Settings → CatSnap."
            case .unavailable: return "Couldn't get your location. Try again in a moment."
            }
        }
    }

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// A fix younger than this is good enough to pin a sighting, and reusing
    /// it saves a round-trip through CoreLocation.
    private static let freshFixWindow: TimeInterval = 60

    /// One-shot location fix. If authorization hasn't been decided, prompts
    /// the user and waits for the response before requesting a location.
    ///
    /// Guaranteed to return or throw within `timeout`. CoreLocation can accept
    /// `requestLocation()` and then never call back — most reproducibly when
    /// the permission alert is raised while a sheet is still dismissing — and
    /// without a deadline the caller waits on a spinner forever.
    func requestOneShot(timeout: Duration = .seconds(8)) async throws -> CLLocation {
        if let cached = lastLocation,
           Date().timeIntervalSince(cached.timestamp) < Self.freshFixWindow {
            return cached
        }

        try await ensureAuthorized()

        isResolving = true
        defer { isResolving = false }

        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask { @MainActor in try await self.awaitFix() }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw LocationError.unavailable
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else { throw LocationError.unavailable }
            return first
        }
    }

    private func awaitFix() async throws -> CLLocation {
        // Two overlapping calls are reachable (the initial capture racing the
        // "use my location" button). Without this the second overwrites the
        // first's continuation and leaks it, hanging that caller for good.
        if let stale = locationContinuation {
            locationContinuation = nil
            stale.resume(throwing: CancellationError())
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                self.locationContinuation = cont
                self.manager.requestLocation()
            }
        } onCancel: {
            // Caller's Task was cancelled. Hop to the main actor and resume the
            // pending continuation with CancellationError so it isn't leaked.
            Task { @MainActor in
                self.locationContinuation?.resume(throwing: CancellationError())
                self.locationContinuation = nil
            }
        }
    }

    private func ensureAuthorized() async throws {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return
        case .denied, .restricted:
            throw LocationError.denied
        case .notDetermined:
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                self.authContinuation = cont
                self.manager.requestWhenInUseAuthorization()
            }
        @unknown default:
            throw LocationError.denied
        }
    }

    func reverseGeocode(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return nil
        }
        let line1 = placemark.thoroughfare ?? placemark.subLocality ?? placemark.locality
        let line2 = placemark.postalCode.flatMap { $0.split(separator: " ").first.map(String.init) }
        return [line1, line2].compactMap { $0 }.joined(separator: ", ").nilIfEmpty
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            guard let cont = self.authContinuation else { return }
            self.authContinuation = nil
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                cont.resume(returning: ())
            case .denied, .restricted:
                cont.resume(throwing: LocationError.denied)
            case .notDetermined:
                // Shouldn't happen after explicit request; treat as denial.
                cont.resume(throwing: LocationError.denied)
            @unknown default:
                cont.resume(throwing: LocationError.denied)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.lastLocation = location
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: error)
            self.locationContinuation = nil
        }
    }
}

extension CLLocationCoordinate2D {
    /// Fallback pin for any surface that must show a map before a real fix
    /// lands. Central London — chosen when the app was London-only, and kept
    /// so the map is always draggable rather than absent. Never submitted
    /// without the user confirming the spot.
    static let fallback = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
