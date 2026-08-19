import Foundation
import Supabase
import PostgREST

// Reads against the `cats` table that aren't a single-row fetch.
enum CatReads {
    /// Minimum query length. Mirrors the same guard inside `search_cats` —
    /// keeping it client-side too means the first keystroke costs no round-trip.
    static let minimumQueryLength = 2

    /// Type-ahead for the Submit form's name field.
    static func search(query: String, limit: Int = 8) async throws -> [CatSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minimumQueryLength else { return [] }

        return try await supabase
            .rpc("search_cats", params: SearchCatsParams(query: trimmed, limit: limit))
            .execute()
            .value
    }
}

private struct SearchCatsParams: Encodable {
    let query: String
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case query = "p_query"
        case limit = "p_limit"
    }
}
