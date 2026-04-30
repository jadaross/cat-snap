import Foundation
import Supabase
import PostgREST

@MainActor
@Observable
final class GuideModel {
    var cats: [Cat] = []
    var spottedCatIds: Set<UUID> = []
    /// Cat IDs the current user has at least one sighting for *today* (in the
    /// device's calendar). Drives the `Today` filter chip.
    var spottedTodayCatIds: Set<UUID> = []
    /// Most recent sighting photo URL per cat — used as a fallback when
    /// cats.primary_photo_url is null (the RPC never writes it back).
    var catIdToPhotoUrl: [UUID: URL] = [:]
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let catsResp: [Cat] = supabase
                .from("cats")
                .select()
                .order("name")
                .execute()
                .value

            let userId = try await supabase.auth.session.user.id
            async let sightingsResp: [Sighting] = supabase
                .from("sightings")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            let allCats = try await catsResp
            let mySightings = try await sightingsResp

            cats = allCats
            spottedCatIds = Set(mySightings.compactMap { $0.catId })

            var photoMap: [UUID: URL] = [:]
            for sighting in mySightings.sorted(by: { $0.seenAt > $1.seenAt }) {
                if let catId = sighting.catId, photoMap[catId] == nil {
                    photoMap[catId] = sighting.photoUrl
                }
            }
            catIdToPhotoUrl = photoMap

            let calendar = Calendar.current
            let now = Date()
            spottedTodayCatIds = Set(
                mySightings
                    .filter { calendar.isDate($0.seenAt, inSameDayAs: now) }
                    .compactMap { $0.catId }
            )
            error = nil
        } catch {
            // No active session yet — show the catalogue with no spots marked.
            do {
                cats = try await supabase
                    .from("cats")
                    .select()
                    .order("name")
                    .execute()
                    .value
                spottedCatIds = []
                spottedTodayCatIds = []
                self.error = nil
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
