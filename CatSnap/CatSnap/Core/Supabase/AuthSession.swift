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

    /// App-lifetime task subscribed to auth state changes. Held so the
    /// intent ("singleton, never cancelled") is explicit rather than the
    /// task hanging implicitly off init.
    private var listener: Task<Void, Never>?

    init() {
        listener = Task { [weak self] in
            // First emission yields the restored session (or nil) immediately.
            // weak self lets the loop exit naturally when AuthSession is released.
            for await (_, session) in supabase.auth.authStateChanges {
                guard let self else { return }
                self.state = session.flatMap { .signedIn($0.user) } ?? .signedOut
            }
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
