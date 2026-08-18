import Foundation
import UIKit
import Supabase
import PostgREST
import Auth

@MainActor
@Observable
final class UserProfileModel {
    enum State {
        case idle
        case loading
        case loaded(Profile, [Sighting], catCount: Int)
        case failed(String)
    }

    var state: State = .idle

    func load() async {
        state = .loading
        do {
            let userId = try await supabase.auth.session.user.id

            async let profileResponse: [Profile] = supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value

            async let sightingsResponse: [Sighting] = SightingsReads.forUser(userId)

            async let catCountResponse: PostgrestResponse<[Cat]> = supabase
                .from("cats")
                .select(count: .exact)
                .eq("created_by", value: userId)
                .execute()

            let profiles = try await profileResponse
            let sightings = try await sightingsResponse
            let catResp = try await catCountResponse

            guard let profile = profiles.first else {
                state = .failed("profile missing")
                return
            }
            state = .loaded(profile, sightings, catCount: catResp.count ?? 0)
        } catch {
            state = .failed(AppError.map(error).localizedDescription)
        }
    }

    func updateDisplayName(_ name: String) async throws {
        let userId = try await supabase.auth.session.user.id
        struct DisplayNameUpdate: Encodable {
            let display_name: String?
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = DisplayNameUpdate(display_name: trimmed.isEmpty ? nil : trimmed)
        try await supabase
            .from("profiles")
            .update(payload)
            .eq("id", value: userId)
            .execute()
        await load()
    }

    func uploadAvatar(_ image: UIImage) async throws {
        _ = try await AvatarUpload.uploadAndSetAvatar(image)
        await load()
    }
}
