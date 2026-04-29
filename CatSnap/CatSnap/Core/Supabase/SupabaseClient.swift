import Foundation
import Supabase

// Module-level singleton, initialized lazily at first access.
// URL and anon key come from Info.plist, populated via CatSnap.xcconfig.
let supabase: SupabaseClient = {
    let bundle = Bundle.main

    guard
        let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
        let url = URL(string: urlString),
        url.scheme == "https"
    else {
        fatalError(
            "SUPABASE_URL missing or invalid in Info.plist. Check that CatSnap.xcconfig is " +
            "wired to both Debug and Release configurations and that the Info tab has a " +
            "SUPABASE_URL key referencing $(SUPABASE_URL)."
        )
    }

    guard
        let key = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
        !key.isEmpty,
        key != "PASTE_PUBLISHABLE_KEY_HERE",
        key != "your-publishable-key-here"
    else {
        fatalError(
            "SUPABASE_ANON_KEY missing or still set to a placeholder. Open CatSnap.xcconfig " +
            "and paste the publishable key from your password manager."
        )
    }

    return SupabaseClient(supabaseURL: url, supabaseKey: key)
}()
