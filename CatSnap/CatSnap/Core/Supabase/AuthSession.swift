import Foundation
import Supabase

@Observable
@MainActor
final class AuthSession {
    enum State {
        case loading
        case signedOut
        case signedIn(User)
    }

    private(set) var state: State = .loading

    init() {
        Task { await listen() }
    }

    private func listen() async {
        // First emission yields the restored session (or nil) immediately.
        for await (_, session) in supabase.auth.authStateChanges {
            state = session.flatMap { .signedIn($0.user) } ?? .signedOut
        }
    }

    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await supabase.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }
}
