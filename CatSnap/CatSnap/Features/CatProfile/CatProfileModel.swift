import Foundation
import Supabase
import PostgREST

@MainActor
@Observable
final class CatProfileModel {
    enum State {
        case idle
        case loading
        case loaded(Cat, [Sighting])
        case failed(String)
    }

    var state: State = .idle
    let catId: UUID

    init(catId: UUID) {
        self.catId = catId
    }

    func load() async {
        state = .loading
        do {
            async let catResponse: [Cat] = supabase
                .from("cats")
                .select()
                .eq("id", value: catId)
                .execute()
                .value

            async let sightingsResponse: [Sighting] = supabase
                .from("sightings")
                .select()
                .eq("cat_id", value: catId)
                .order("seen_at", ascending: false)
                .execute()
                .value

            let cats = try await catResponse
            let sightings = try await sightingsResponse

            guard let cat = cats.first else {
                state = .failed("cat not found")
                return
            }
            state = .loaded(cat, sightings)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
