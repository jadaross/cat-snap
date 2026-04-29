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
            let userId = try await supabase.auth.session.user.id

            let photoUrl = try await PhotoUpload.uploadSightingPhoto(image)

            let resolvedCatId = try await resolveCatId()

            let payload = SightingInsert(
                userId: userId,
                catId: resolvedCatId,
                photoUrl: photoUrl,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationLabel: locationLabel,
                notes: nil,
                seenAt: Date()
            )

            let inserted: [Sighting] = try await supabase
                .from("sightings")
                .insert(payload)
                .select()
                .execute()
                .value

            if let sighting = inserted.first, !tags.isEmpty {
                let tagPayloads = tags.sorted().map {
                    SightingTagInsert(sightingId: sighting.id, tag: $0)
                }
                try await supabase
                    .from("sighting_tags")
                    .insert(tagPayloads)
                    .execute()
            }

            stage = .done
            NotificationCenter.default.post(name: .sightingSubmitted, object: nil)
        } catch {
            stage = .error(error.localizedDescription)
        }
    }

    private func resolveCatId() async throws -> UUID? {
        if let prefilledCatId { return prefilledCatId }
        let trimmed = catName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let resolved: UUID? = try await supabase
            .rpc("find_or_create_cat", params: ["p_name": trimmed])
            .execute()
            .value
        return resolved
    }
}
