import Foundation
import Supabase

// Apple App Store Review Guideline 5.1.1(v) requires in-app account
// deletion. The heavy lifting (storage cleanup + auth.admin.deleteUser)
// happens in the `delete-account` edge function; this just invokes it
// and clears the local session so AuthSession routes back to AuthView.
@MainActor
enum AccountDeletion {
    static func deleteCurrentAccount() async throws {
        try await supabase.functions.invoke("delete-account")
        try? await supabase.auth.signOut(scope: .local)
    }
}
