import SwiftUI

// Settings + App-Store-review-required surfaces:
//   - in-app account deletion (Guideline 5.1.1(v))
//   - support contact reachable in-app (Guideline 1.2)
//   - privacy policy + terms links (App Store Connect requirement)
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSession.self) private var session

    @State private var isDeleting = false
    @State private var showDeleteConfirm = false
    @State private var deleteError: String?

    // Privacy policy and terms are hosted on GitHub Pages. Both are static
    // literals, so the optional initialiser can never fail — the previous
    // `?? URL(string: "https://catsnap.app/privacy")!` fallback was
    // unreachable, force-unwrapped, and pointed at a page that does not
    // exist. `staticURL` keeps the single force-unwrap in one audited place.
    private let supportEmail = "support@catsnap.app"
    private let privacyURL = staticURL("https://jadaross.github.io/cat-snap/privacy-policy.html")
    private let termsURL = staticURL("https://jadaross.github.io/cat-snap/terms-of-service.html")

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        section(title: "SUPPORT") {
                            row(label: "Contact support", trailing: supportEmail) {
                                if let url = URL(string: "mailto:\(supportEmail)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }

                        section(title: "LEGAL") {
                            VStack(spacing: 0) {
                                row(label: "Privacy policy") { UIApplication.shared.open(privacyURL) }
                                divider
                                row(label: "Terms of service") { UIApplication.shared.open(termsURL) }
                            }
                        }

                        section(title: "ACCOUNT") {
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack {
                                    Text("Delete account")
                                        .font(.Brand.jakarta(.semibold, size: 14))
                                        .foregroundStyle(Color.coralDeep)
                                    Spacer()
                                    if isDeleting {
                                        ProgressView().tint(Color.coralDeep)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color.coralDeep.opacity(0.6))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .disabled(isDeleting)
                        }

                        if let deleteError {
                            Text(deleteError)
                                .font(.Brand.jakarta(.regular, size: 12))
                                .foregroundStyle(Color.coralDeep)
                                .padding(.horizontal, 4)
                        }

                        Text("deleting your account permanently removes your sightings, photos, follows, and profile. this can't be undone.")
                            .font(.Brand.jakarta(.regular, size: 11))
                            .foregroundStyle(Color.stone)
                            .padding(.horizontal, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("done") { dismiss() }
                        .foregroundStyle(Color.ink)
                }
            }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("this permanently removes your sightings, photos, follows, and profile. this can't be undone.")
            }
        }
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.Brand.mono(size: 10))
                .tracking(1.2)
                .foregroundStyle(Color.stone)
            content()
                .background(Color.creamSoft, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
        }
    }

    private func row(
        label: String,
        trailing: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.Brand.jakarta(.medium, size: 14))
                    .foregroundStyle(Color.ink)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.Brand.jakarta(.regular, size: 12))
                        .foregroundStyle(Color.stone)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.stone.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.stoneLight)
            .frame(height: 1)
            .padding(.leading, 14)
    }

    private func deleteAccount() async {
        isDeleting = true
        deleteError = nil
        defer { isDeleting = false }
        do {
            try await AccountDeletion.deleteCurrentAccount()
            // AuthSession's authStateChanges listener routes the app back
            // to AuthView automatically; the sheet closes with it.
        } catch {
            deleteError = AppError.map(error).localizedDescription
        }
    }
}

/// Builds a `URL` from a compile-time constant. Traps at launch — not in a
/// user's hands — if a literal is ever edited into something invalid.
private func staticURL(_ string: String) -> URL {
    guard let url = URL(string: string) else {
        preconditionFailure("Malformed static URL literal: \(string)")
    }
    return url
}
