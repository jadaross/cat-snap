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
