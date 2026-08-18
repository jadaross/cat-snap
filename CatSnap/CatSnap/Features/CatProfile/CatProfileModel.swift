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
    var isFavorite: Bool = false
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

            async let sightings: [Sighting] = SightingsReads.forCat(catId)

            async let favoriteResponse: [FavoriteRow] = supabase
                .from("favorites")
                .select("cat_id")
                .eq("cat_id", value: catId)
                .limit(1)
                .execute()
                .value

            let cats = try await catResponse
            let loadedSightings = try await sightings
            // The favorites query may fail if there's no signed-in session
            // (RLS blocks the read). Treat that as "not favorited" rather
            // than a hard error — the rest of the profile should still load.
            let favorites = (try? await favoriteResponse) ?? []

            guard let cat = cats.first else {
                state = .failed("cat not found")
                return
            }
            isFavorite = !favorites.isEmpty
            state = .loaded(cat, loadedSightings)
        } catch {
            state = .failed(AppError.map(error).localizedDescription)
        }
    }

    /// Optimistically flips `isFavorite`, then writes to Supabase. On error
    /// we revert. Cheap enough that we don't bother with a pending state.
    func toggleFavorite() async {
        let previous = isFavorite
        let target = !previous
        isFavorite = target

        do {
            let userId = try await supabase.auth.session.user.id
            if target {
                _ = try await supabase
                    .from("favorites")
                    .insert(FavoriteInsert(userId: userId, catId: catId))
                    .execute()
            } else {
                _ = try await supabase
                    .from("favorites")
                    .delete()
                    .eq("user_id", value: userId)
                    .eq("cat_id", value: catId)
                    .execute()
            }
        } catch {
            // Revert on failure — the optimistic flip lied.
            isFavorite = previous
        }
    }
}

private struct FavoriteRow: Decodable {
    let catId: UUID
    enum CodingKeys: String, CodingKey { case catId = "cat_id" }
}

private struct FavoriteInsert: Encodable {
    let userId: UUID
    let catId: UUID
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case catId  = "cat_id"
    }
}
