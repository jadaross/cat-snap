import Foundation
import UIKit
import CoreLocation
import Supabase
import PostgREST
import Auth

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

    let prefilledCatId: UUID?
    private let locationManager = LocationManager()

    init(prefilledCatId: UUID? = nil) {
        self.prefilledCatId = prefilledCatId
    }

    func acceptPhoto(_ image: UIImage) async {
        self.image = image
        stage = .capturingLocation
        await captureLocation()
    }

    private func captureLocation() async {
        do {
            let loc = try await locationManager.requestOneShot()
            location = loc
            locationLabel = await locationManager.reverseGeocode(loc)
            stage = .editing
        } catch {
            stage = .error(error.localizedDescription)
        }
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
            let photoUrl = try await PhotoUpload.uploadSightingPhoto(image)

            let trimmedName = catName.trimmingCharacters(in: .whitespacesAndNewlines)
            let payload = CreateSightingPayload(
                catName: prefilledCatId == nil ? (trimmedName.isEmpty ? nil : trimmedName) : nil,
                existingCatId: prefilledCatId,
                photoUrl: photoUrl.absoluteString,
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude,
                locationLabel: locationLabel,
                seenAt: Date(),
                tags: tags.sorted()
            )

            _ = try await supabase
                .rpc("create_sighting_with_cat", params: payload)
                .execute()

            stage = .done
            NotificationCenter.default.post(name: .sightingSubmitted, object: nil)
        } catch {
            stage = .error(error.localizedDescription)
        }
    }
}

private struct CreateSightingPayload: Encodable {
    let catName: String?
    let existingCatId: UUID?
    let photoUrl: String
    let lat: Double
    let lng: Double
    let locationLabel: String?
    let seenAt: Date
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case catName        = "p_cat_name"
        case existingCatId  = "p_existing_cat_id"
        case photoUrl       = "p_photo_url"
        case lat            = "p_lat"
        case lng            = "p_lng"
        case locationLabel  = "p_location_label"
        case seenAt         = "p_seen_at"
        case tags           = "p_tags"
    }
}
