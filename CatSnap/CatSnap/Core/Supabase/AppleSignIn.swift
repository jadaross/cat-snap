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
//
// One instance owns the per-attempt raw nonce that bridges
// `SignInWithAppleButton`'s request closure → completion closure, so the
// caller doesn't have to thread that state through the view layer.
@MainActor
final class AppleSignIn {
    enum Outcome {
        case signedIn
        case userCanceled
    }

    private var pendingRawNonce: String?

    /// Wires nonce + scopes onto Apple's request. Call from
    /// `SignInWithAppleButton`'s request closure.
    func configure(_ request: ASAuthorizationAppleIDRequest) {
        let raw = Self.makeNonce()
        pendingRawNonce = raw
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256Hex(raw)
    }

    /// Consumes the button's completion result. Returns `.userCanceled`
    /// when the user dismissed the sheet (a normal abort, not an error);
    /// throws for malformed credentials, missing tokens, or transport
    /// failures. On success, the user is signed in to Supabase.
    func complete(_ result: Result<ASAuthorization, Error>) async throws -> Outcome {
        let raw = pendingRawNonce
        pendingRawNonce = nil

        switch result {
        case .failure(let err):
            if let asError = err as? ASAuthorizationError, asError.code == .canceled {
                return .userCanceled
            }
            throw err
        case .success(let authorization):
            guard let raw else { throw AppleSignInError.missingNonce }
            try await Self.exchange(authorization: authorization, rawNonce: raw)
            return .signedIn
        }
    }

    // MARK: - Internals

    /// 32 random bytes, base64url-encoded. The raw value is what Supabase
    /// compares against the `nonce` claim in Apple's JWT; the SHA-256 of
    /// this value is what we send to Apple.
    private static func makeNonce() -> String {
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

    private static func sha256Hex(_ raw: String) -> String {
        SHA256.hash(data: Data(raw.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func exchange(authorization: ASAuthorization, rawNonce: String) async throws {
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
    case missingNonce

    var errorDescription: String? {
        switch self {
        case .malformedCredential:
            return "Couldn't read your Apple credential. Please try again."
        case .missingIdentityToken:
            return "Apple didn't return a token. Please try again."
        case .missingNonce:
            return "Sign in with Apple: missing nonce. Please try again."
        }
    }
}
