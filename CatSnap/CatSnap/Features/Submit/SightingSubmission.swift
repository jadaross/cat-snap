import Foundation
import UIKit
import CoreLocation
import Supabase
import PostgREST

// Server-facing submit step: upload the photo, then call
// `create_sighting_with_cat` to insert the sighting (and, when no
// `existingCatId` is provided, create a brand-new cat in the same
// transaction). UI state, EXIF capture, and location-picking ceremony
// live in `SubmitModel`; this module only knows about the network shape.
enum SightingSubmission {
    static func submit(
        image: UIImage,
        location: CLLocation,
        locationLabel: String?,
        seenAt: Date,
        catName: String?,
        existingCatId: UUID?,
        tags: [String]
    ) async throws {
        let photoUrl = try await PhotoUpload.uploadSightingPhoto(image)
        let payload = CreateSightingPayload(
            catName: existingCatId == nil ? catName : nil,
            existingCatId: existingCatId,
            photoUrl: photoUrl.absoluteString,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            locationLabel: locationLabel,
            seenAt: seenAt,
            tags: tags
        )
        _ = try await supabase
            .rpc("create_sighting_with_cat", params: payload)
            .execute()
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
