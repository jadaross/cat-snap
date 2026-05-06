import Foundation
import Supabase

// Apple App Store Review Guideline 5.1.1(v) requires in-app account
// deletion. The heavy lifting (storage cleanup + auth.admin.deleteUser)
// happens in the `delete-account` edge function; this just invokes it
// and clears the local session so AuthSession routes back to AuthView.
//
// TODO: extend the `delete-account` edge function to call Apple's
// `https://appleid.apple.com/auth/revoke` endpoint when a SIWA user
// deletes their account. Requires a Service ID + .p8 stored as a Supabase
// secret. Tracked in docs/launch-checklist.md §5 A3.
@MainActor
enum AccountDeletion {
    static func deleteCurrentAccount() async throws {
        try await supabase.functions.invoke("delete-account")
        try? await supabase.auth.signOut(scope: .local)
    }
}
