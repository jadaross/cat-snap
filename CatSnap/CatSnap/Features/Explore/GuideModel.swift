import Foundation
import Supabase
import PostgREST

@MainActor
@Observable
final class GuideModel {
    var rows: [GuideRow] = []
    var criteria = GuideFilterCriteria()
    var isLoading = false
    var error: String?

    /// Drives the inline three-chip quick-filter row. Mutually exclusive,
    /// distinct from the multi-select sheet criteria. The default `.all`
    /// shows every cat — there's no "not yet spotted" framing; the only
    /// opt-in narrowing is `.spotted` ("cats I've seen").
    enum QuickFilter: Hashable {
        case all
        case favorites
        case spotted
    }

    var quickFilter: QuickFilter = .all {
        didSet {
            if oldValue == quickFilter { return }
            switch quickFilter {
            case .all:
                criteria.favoritesOnly = false
                criteria.status = .all
            case .favorites:
                criteria.favoritesOnly = true
                criteria.status = .all
            case .spotted:
                criteria.favoritesOnly = false
                criteria.status = .spotted
            }
        }
    }

    var spottedCount: Int {
        rows.lazy.filter(\.isSpotted).count
    }

    var totalCount: Int {
        rows.count
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [GuideRow] = try await supabase
                .rpc("guide_list", params: criteria)
                .execute()
                .value
            rows = response
            error = nil
        } catch {
            self.error = AppError.map(error).localizedDescription
        }
    }

    /// Apply a new criteria value (typically from the filter sheet) and
    /// re-fetch. Idempotent — bails when the criteria hasn't changed.
    func apply(_ next: GuideFilterCriteria) async {
        if next == criteria { return }
        criteria = next
        await load()
    }
}
