import Foundation
import UIKit
import CoreLocation

@Observable
@MainActor
final class SubmitModel {
    enum Stage: Equatable {
        case pickingPhoto
        case editing
        case submitting
        case error(String)
        case done
    }

    /// Shown under the map whenever we couldn't pin the user automatically.
    /// Deliberately an instruction, not an apology — the map is right there.
    static let manualPinNotice = String(
        localized: "couldn't pin you automatically — drag the map to set the spot."
    )

    var stage: Stage = .pickingPhoto
    var image: UIImage?
    /// Non-optional so the editor's map always has something to render. Starts
    /// on a fallback pin that is *not* submittable — `isLocationConfirmed`
    /// gates that — so a photo can never be filed at a placeholder coordinate.
    var location = CLLocation(
        latitude: CLLocationCoordinate2D.fallback.latitude,
        longitude: CLLocationCoordinate2D.fallback.longitude
    )
    var locationLabel: String?
    /// True once the pin means something: an EXIF coordinate, a device fix, or
    /// a deliberate drag by the user. Submission is blocked until then.
    var isLocationConfirmed = false
    /// A device fix is in flight; the map shows a spinner but stays draggable.
    var isResolvingLocation = false
    /// Non-fatal location trouble. Never promoted to `.error`, because that
    /// would take the map — the only way to recover — off screen.
    var locationNotice: String?
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
    private var locationTask: Task<Void, Never>?

    init(prefilledCatId: UUID? = nil) {
        self.prefilledCatId = prefilledCatId
    }

    /// Ready to file: a photo, and a pin the user or their device stands behind.
    var canSubmit: Bool { image != nil && isLocationConfirmed }

    func acceptPhoto(_ image: UIImage) async {
        self.image = image
        isFromCameraRoll = false
        exifSeenAt = nil
        // Straight to the editor. The map lives there and is always visible,
        // so a slow or failed fix refines a pin the user can already see and
        // drag, rather than stranding them behind a spinner.
        stage = .editing
        refineLocationFromDevice()
    }

    /// Accepts a photo picked from the library. EXIF date + location are
    /// pre-filled when present so we skip the live-location capture step.
    func acceptUploadedPhoto(_ image: UIImage, exif: ExifMetadata.Extracted) async {
        self.image = image
        isFromCameraRoll = true
        exifSeenAt = exif.creationDate
        stage = .editing

        if let exifLoc = exif.location {
            exifLocation = exifLoc
            location = exifLoc
            isLocationConfirmed = true
            locationNotice = nil
            locationLabel = await locationManager.reverseGeocode(exifLoc)
        } else {
            // PHPicker strips GPS from delivered image data unless the app
            // holds full-library access, so this is the common path.
            refineLocationFromDevice()
        }
    }

    /// Ask the device where we are and move the pin there, unless the user has
    /// already placed it themselves. Never fails loudly.
    private func refineLocationFromDevice() {
        locationTask?.cancel()
        locationNotice = nil
        isResolvingLocation = true

        locationTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isResolvingLocation = false }
            do {
                let loc = try await self.locationManager.requestOneShot()
                if Task.isCancelled { return }
                self.deviceLocation = loc
                // Don't stomp a pin the user has already committed to.
                guard !self.isLocationConfirmed else { return }
                self.location = loc
                self.isLocationConfirmed = true
                self.locationLabel = await self.locationManager.reverseGeocode(loc)
            } catch {
                if Task.isCancelled { return }
                self.locationNotice = Self.manualPinNotice
            }
        }
    }

    /// Move the pin. Debounces a reverse-geocode so panning around the map
    /// doesn't fire a request on every camera frame.
    func updatePin(to coordinate: CLLocationCoordinate2D) {
        let updated = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        location = updated
        // A deliberate drag is as good a confirmation as a device fix.
        isLocationConfirmed = true
        locationNotice = nil
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
        isResolvingLocation = true
        defer { isResolvingLocation = false }
        do {
            let loc = try await locationManager.requestOneShot()
            deviceLocation = loc
            location = loc
            isLocationConfirmed = true
            locationNotice = nil
            locationLabel = await locationManager.reverseGeocode(loc)
        } catch {
            locationNotice = Self.manualPinNotice
        }
    }

    /// Recentre handler for `MapPinPicker`, which drives its own camera from
    /// the returned coordinate.
    func recentreOnDevice() async -> CLLocationCoordinate2D? {
        await usePinFromDeviceLocation()
        return isLocationConfirmed ? location.coordinate : nil
    }

    /// Reset the pin back to the photo's original EXIF location, when one
    /// is available. No-op otherwise.
    func usePinFromExif() async {
        guard let exifLoc = exifLocation else { return }
        location = exifLoc
        isLocationConfirmed = true
        locationNotice = nil
        locationLabel = await locationManager.reverseGeocode(exifLoc)
    }

    func toggleTag(_ tag: String) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }

    func submit() async {
        switch stage {
        case .pickingPhoto, .submitting, .done:
            return
        case .editing, .error:
            break
        }

        guard let image else {
            stage = .error(String(localized: "missing photo"))
            return
        }

        // Surface the nudge next to the map rather than tearing down the
        // editor — the fix is one drag away.
        guard isLocationConfirmed else {
            locationNotice = Self.manualPinNotice
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
