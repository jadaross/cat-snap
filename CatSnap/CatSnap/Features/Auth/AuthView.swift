import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @Environment(AuthSession.self) private var session

    @State private var email = ""
    @State private var password = ""
    @State private var mode: Mode = .signIn
    @State private var isWorking = false
    @State private var error: String?
    @State private var info: String?
    @State private var currentNonce: String?

    enum Mode { case signIn, signUp }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                CatWindowMark(size: 96)
                Wordmark(size: 44)

                SignInWithAppleButton(.signIn) { request in
                    let raw = AppleSignIn.makeNonce()
                    currentNonce = raw
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = AppleSignIn.sha256Hex(raw)
                } onCompletion: { result in
                    handleApple(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 32)
                .disabled(isWorking)

                HStack(spacing: 12) {
                    Rectangle().fill(Color.stoneLight).frame(height: 1)
                    Text("or")
                        .font(.Brand.jakarta(.medium, size: 12))
                        .foregroundStyle(Color.stone)
                    Rectangle().fill(Color.stoneLight).frame(height: 1)
                }
                .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    field("email", text: $email, keyboard: .emailAddress, secure: false)
                    field("password", text: $password, keyboard: .default, secure: true)

                    if let error {
                        Text(error)
                            .font(.Brand.jakarta(.medium, size: 13))
                            .foregroundStyle(Color.coralDeep)
                            .multilineTextAlignment(.center)
                    } else if let info {
                        Text(info)
                            .font(.Brand.jakarta(.medium, size: 13))
                            .foregroundStyle(Color.stone)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: submit) {
                        Text(mode == .signIn ? "sign in" : "sign up")
                            .font(.Brand.jakarta(.semibold, size: 16))
                            .foregroundStyle(Color.creamSoft)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.coral, in: .rect(cornerRadius: 10))
                            .opacity(isWorking ? 0.6 : 1)
                    }
                    .disabled(isWorking || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 32)

                Button {
                    mode = mode == .signIn ? .signUp : .signIn
                    error = nil
                    info = nil
                } label: {
                    Text(mode == .signIn ? "no account? sign up" : "have an account? sign in")
                        .font(.Brand.jakarta(.medium, size: 14))
                        .foregroundStyle(Color.stone)
                }

                Spacer()
            }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType, secure: Bool) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .font(.Brand.jakarta(.regular, size: 16))
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.creamSoft, in: .rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Color.stoneLight, lineWidth: 1)
        )
    }

    private func submit() {
        error = nil
        info = nil
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                switch mode {
                case .signIn:
                    try await session.signIn(email: email, password: password)
                case .signUp:
                    try await session.signUp(email: email, password: password)
                    info = "check your email to confirm, then sign in."
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        error = nil
        info = nil
        switch result {
        case .failure(let err):
            // User-cancelled is a normal abort, not an error. Other failures
            // (network, malformed credential, no iCloud account on simulator)
            // surface to the user.
            if let asError = err as? ASAuthorizationError, asError.code == .canceled {
                currentNonce = nil
                return
            }
            currentNonce = nil
            self.error = err.localizedDescription
        case .success(let authorization):
            guard let raw = currentNonce else {
                self.error = "Sign in with Apple: missing nonce. Please try again."
                return
            }
            isWorking = true
            Task {
                defer {
                    isWorking = false
                    currentNonce = nil
                }
                do {
                    try await AppleSignIn.exchange(authorization: authorization, rawNonce: raw)
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
