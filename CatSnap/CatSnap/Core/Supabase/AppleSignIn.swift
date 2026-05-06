import AuthenticationServices
import CryptoKit
import Foundation
import PostgREST
import Supabase

// Native Sign in with Apple flow. Apple delivers the ID token + nonce in
// the device credential; we hand the token to Supabase via signInWithIdToken
// and Supabase verifies the JWT signature against Apple's public JWKs — so
// no Service ID, no .p8, no client secret are needed for sign-in.
//
// Apple revocation on account deletion (App Store Review 5.1.1(v)) is
// deferred — see launch-checklist.md §5 A3.
@MainActor
enum AppleSignIn {
    /// 32 random bytes, base64url-encoded. The raw value is what Supabase
    /// compares against the `nonce` claim in Apple's JWT; the SHA-256 of
    /// this value is what we send to Apple.
    static func makeNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            fatalError("SecRandomCopyBytes failed: \(status)")
        }
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func sha256Hex(_ raw: String) -> String {
        SHA256.hash(data: Data(raw.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func exchange(authorization: ASAuthorization, rawNonce: String) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AppleSignInError.malformedCredential
        }

        // Apple delivers fullName ONLY on the first authorization for this
        // App ID, and ONLY in the device credential — never in the JWT.
        // Capture it synchronously before any await so we don't lose it.
        let displayName = formattedName(from: credential.fullName)

        guard
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AppleSignInError.missingIdentityToken
        }

        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: rawNonce)
        )

        if let displayName {
            try? await backfillDisplayNameIfMissing(displayName)
        }
    }

    // The handle_new_user trigger reads display_name from
    // raw_user_meta_data.full_name, but Apple's ID token doesn't carry it.
    // Without this backfill, Apple users land with display_name = null and
    // would have to set it manually via EditProfileSheet. Best-effort: if
    // it fails we silently fall through to the manual path.
    private static func backfillDisplayNameIfMissing(_ displayName: String) async throws {
        let user = try await supabase.auth.user()

        struct ProfileRow: Decodable {
            let display_name: String?
        }
        let row: ProfileRow = try await supabase
            .from("profiles")
            .select("display_name")
            .eq("id", value: user.id)
            .single()
            .execute()
            .value

        guard row.display_name == nil else { return }

        try await supabase
            .from("profiles")
            .update(["display_name": displayName])
            .eq("id", value: user.id)
            .execute()
    }

    private static func formattedName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let name = formatter
            .string(from: components)
            .trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
}

enum AppleSignInError: LocalizedError {
    case malformedCredential
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .malformedCredential:
            return "Couldn't read your Apple credential. Please try again."
        case .missingIdentityToken:
            return "Apple didn't return a token. Please try again."
        }
    }
}
