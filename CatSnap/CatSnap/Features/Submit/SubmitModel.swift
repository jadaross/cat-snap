import Foundation
import UIKit
import CoreLocation

@Observable
@MainActor
final class SubmitModel {
    enum Stage: Equatable {
        case pickingPhoto
        case capturingLocation
        case editing
        case submitting
        case error(String)
        case done
    }

    var stage: Stage = .pickingPhoto
    var image: UIImage?
    var location: CLLocation?
    var locationLabel: String?
    var catName: String = ""
    var tags: Set<String> = []
    /// When set, overrides `Date()` in the submit payload — used when an
    /// uploaded photo carries an EXIF DateTimeOriginal so the sighting is
    /// timestamped to when it was taken, not when it was logged.
    var exifSeenAt: Date?
    /// True if the current photo came from the camera roll (not a live snap).
    /// Surfaces "from camera roll" affordances in the editor.
    var isFromCameraRoll: Bool = false
    /// EXIF-derived location preserved so the user can revert after dragging
    /// the pin. Nil for camera-snap photos and uploads without GPS metadata.
    var exifLocation: CLLocation?
    /// Most recent device-fix location, preserved so the user can snap the
    /// pin back to "where I am" without re-prompting permissions.
    var deviceLocation: CLLocation?

    let prefilledCatId: UUID?
    private let locationManager = LocationManager()
    private var reverseGeocodeTask: Task<Void, Never>?

    init(prefilledCatId: UUID? = nil) {
        self.prefilledCatId = prefilledCatId
    }

    func acceptPhoto(_ image: UIImage) async {
        self.image = image
        isFromCameraRoll = false
        exifSeenAt = nil
        stage = .capturingLocation
        await captureLocation()
    }

    /// Accepts a photo picked from the library. EXIF date + location are
    /// pre-filled when present so we skip the live-location capture step.
    func acceptUploadedPhoto(_ image: UIImage, exif: ExifMetadata.Extracted) async {
        self.image = image
        isFromCameraRoll = true
        exifSeenAt = exif.creationDate

        if let exifLoc = exif.location {
            exifLocation = exifLoc
            location = exifLoc
            locationLabel = await locationManager.reverseGeocode(exifLoc)
            stage = .editing
        } else {
            stage = .capturingLocation
            await captureLocation()
        }
    }

    private func captureLocation() async {
        do {
            let loc = try await locationManager.requestOneShot()
            deviceLocation = loc
            location = loc
            locationLabel = await locationManager.reverseGeocode(loc)
            stage = .editing
        } catch {
            stage = .error(AppError.map(error).localizedDescription)
        }
    }

    /// Move the pin. Debounces a reverse-geocode so panning around the map
    /// doesn't fire a request on every camera frame.
    func updatePin(to coordinate: CLLocationCoordinate2D) {
        let updated = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        location = updated
        reverseGeocodeTask?.cancel()
        reverseGeocodeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            let label = await self?.locationManager.reverseGeocode(updated)
            if Task.isCancelled { return }
            await MainActor.run { self?.locationLabel = label }
        }
    }

    /// Reset the pin to the user's current device location (one-shot).
    func usePinFromDeviceLocation() async {
        do {
            let loc = try await locationManager.requestOneShot()
            deviceLocation = loc
            location = loc
            locationLabel = await locationManager.reverseGeocode(loc)
        } catch {
            // Silent failure — user can pan manually.
        }
    }

    /// Reset the pin back to the photo's original EXIF location, when one
    /// is available. No-op otherwise.
    func usePinFromExif() async {
        guard let exifLoc = exifLocation else { return }
        location = exifLoc
        locationLabel = await locationManager.reverseGeocode(exifLoc)
    }

    func toggleTag(_ tag: String) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }

    func submit() async {
        switch stage {
        case .pickingPhoto, .capturingLocation, .submitting, .done:
            return
        case .editing, .error:
            break
        }

        guard let image, let location else {
            stage = .error("missing photo or location")
            return
        }

        stage = .submitting

        do {
            let trimmedName = catName.trimmingCharacters(in: .whitespacesAndNewlines)
            try await SightingSubmission.submit(
                image: image,
                location: location,
                locationLabel: locationLabel,
                seenAt: exifSeenAt ?? Date(),
                catName: trimmedName.isEmpty ? nil : trimmedName,
                existingCatId: prefilledCatId,
                tags: tags.sorted()
            )
            stage = .done
            NotificationCenter.default.post(name: .sightingSubmitted, object: nil)
        } catch {
            stage = .error(AppError.map(error).localizedDescription)
        }
    }
}
