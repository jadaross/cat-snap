import SwiftUI
import Supabase
import PostgREST

@MainActor
@Observable
final class SightingsListModel {
    enum State {
        case idle
        case loading
        case loaded([NearbySighting])
        case failed(String)
    }

    var state: State = .idle

    func load() async {
        state = .loading
        do {
            // Default to central London until we wire CoreLocation. The RPC
            // returns the most recent sightings within `p_radius` metres, so
            // a wide radius behaves like "latest sightings" for a small dataset.
            let response: [NearbySighting] = try await supabase
                .rpc("sightings_near", params: [
                    "p_lat": 51.5074,
                    "p_lng": -0.1278,
                    "p_radius": 50_000,
                    "p_limit": 50,
                ])
                .execute()
                .value
            state = .loaded(response)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

struct SightingsListView: View {
    @Environment(AuthSession.self) private var session
    @State private var model = SightingsListModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                content
            }
            .navigationTitle("sightings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("sign out") {
                        Task { try? await session.signOut() }
                    }
                    .font(.Brand.jakarta(.medium, size: 14))
                    .foregroundStyle(Color.stone)
                }
            }
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            ProgressView().tint(Color.coral)
        case .failed(let message):
            VStack(spacing: 12) {
                Text("couldn't load sightings")
                    .font(.Brand.jakarta(.semibold, size: 16))
                    .foregroundStyle(Color.ink)
                Text(message)
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.stone)
                    .multilineTextAlignment(.center)
                Button("retry") { Task { await model.load() } }
                    .font(.Brand.jakarta(.medium, size: 14))
                    .foregroundStyle(Color.coral)
            }
            .padding(32)
        case .loaded(let sightings) where sightings.isEmpty:
            VStack(spacing: 12) {
                CatWindowMark(size: 96)
                Text("no sightings yet")
                    .font(.Brand.jakarta(.semibold, size: 16))
                    .foregroundStyle(Color.ink)
                Text("submit one and it'll show here.")
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.stone)
            }
        case .loaded(let sightings):
            List(sightings) { sighting in
                SightingRow(sighting: sighting)
                    .listRowBackground(Color.creamSoft)
                    .listRowSeparatorTint(Color.stoneLight)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

private struct SightingRow: View {
    let sighting: NearbySighting

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: sighting.photoUrl) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.creamDeep
            }
            .frame(width: 64, height: 64)
            .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(sighting.catName ?? "unnamed cat")
                    .font(.Brand.jakarta(.semibold, size: 15))
                    .foregroundStyle(Color.ink)
                Text("@\(sighting.username)")
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.stone)
                if let label = sighting.locationLabel {
                    Text(label)
                        .font(.Brand.jakarta(.regular, size: 12))
                        .foregroundStyle(Color.stone)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
