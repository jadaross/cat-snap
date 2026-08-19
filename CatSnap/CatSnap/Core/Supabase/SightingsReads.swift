import Foundation
import CoreLocation
import Supabase
import PostgREST

// All ways the app reads sightings: the geo `sightings_near` RPC for the
// map + nearby feed, and direct table queries scoped by cat_id / user_id
// for profile pages. Centralised so the RPC param shape (`p_lat`, `p_lng`,
// `p_radius`, `p_limit`, `p_favorites_only`) lives in one place — callers
// previously diverged between a typed Encodable struct and a `[String:
// Double]` dict that couldn't carry the favorites bool.
enum SightingsReads {
    static func nearby(
        centre: CLLocationCoordinate2D,
        radiusMeters: Double,
        limit: Int = 200,
        favoritesOnly: Bool = false
    ) async throws -> [NearbySighting] {
        let params = SightingsNearParams(
            lat: centre.latitude,
            lng: centre.longitude,
            radius: radiusMeters,
            limit: limit,
            favoritesOnly: favoritesOnly
        )
        return try await supabase
            .rpc("sightings_near", params: params)
            .execute()
            .value
    }

    /// Goes through an RPC rather than a table select because the cat profile
    /// needs coordinates, and PostgREST returns the geography column as WKB
    /// hex. The RPC also applies the symmetric blocks filter that a direct
    /// select can't — RLS on `sightings` is `using (true)`.
    static func forCat(_ catId: UUID, limit: Int = 500) async throws -> [CatSighting] {
        try await supabase
            .rpc("sightings_for_cat", params: SightingsForCatParams(catId: catId, limit: limit))
            .execute()
            .value
    }

    static func forUser(_ userId: UUID) async throws -> [Sighting] {
        try await supabase
            .from("sightings")
            .select()
            .eq("user_id", value: userId)
            .order("seen_at", ascending: false)
            .execute()
            .value
    }
}

// Mixed-type RPC params can't be expressed as `[String: Double]` once the
// favorites-only bool joins the list, so we encode through a typed struct.
private struct SightingsNearParams: Encodable {
    let lat: Double
    let lng: Double
    let radius: Double
    let limit: Int
    let favoritesOnly: Bool

    enum CodingKeys: String, CodingKey {
        case lat            = "p_lat"
        case lng            = "p_lng"
        case radius         = "p_radius"
        case limit          = "p_limit"
        case favoritesOnly  = "p_favorites_only"
    }
}

private struct SightingsForCatParams: Encodable {
    let catId: UUID
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case catId = "p_cat_id"
        case limit = "p_limit"
    }
}
