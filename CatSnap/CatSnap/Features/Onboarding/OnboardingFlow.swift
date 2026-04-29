import SwiftUI

// Two flags drive onboarding routing in ContentView. We use two because sign-up
// can require email confirmation — so the user moves through the pre-auth steps,
// then leaves the app to confirm, then returns. We don't want to re-show 1–5.
enum OnboardingFlags {
    static let preAuthDoneKey = "onboardingPreAuthDone"
    static let postAuthDoneKey = "onboardingPostAuthDone"
}

// Pre-auth onboarding (steps 1–5). When the user finishes the permissions
// screens (or taps "I already have an account" on S1) we mark pre-auth done
// and present AuthView via fullScreenCover. Tapping the sign-in shortcut also
// marks post-auth done so existing users go straight to MainTabView after
// signing in.
struct PreAuthOnboardingView: View {
    @AppStorage(OnboardingFlags.preAuthDoneKey) private var preAuthDone: Bool = false
    @AppStorage(OnboardingFlags.postAuthDoneKey) private var postAuthDone: Bool = false

    @State private var step: Int = 0
    @State private var showAuth: Bool = false

    var body: some View {
        ZStack {
            switch step {
            case 0:
                WelcomeStep(
                    onAdvance: { advance() },
                    onAlreadyHaveAccount: {
                        // Existing user — skip the rest of onboarding entirely.
                        preAuthDone = true
                        postAuthDone = true
                        showAuth = true
                    }
                )
            case 1:
                HowItWorksStep(onAdvance: advance)
            case 2:
                LocationPermissionStep(onAdvance: advance)
            case 3:
                CameraPermissionStep(onAdvance: advance)
            case 4:
                NotificationsStep(onAdvance: finishPreAuth)
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .fullScreenCover(isPresented: $showAuth) {
            AuthView()
        }
    }

    private func advance() {
        step = min(step + 1, 4)
    }

    private func finishPreAuth() {
        preAuthDone = true
        showAuth = true
    }
}

// Post-auth onboarding (steps 6–9). Runs after a successful sign-up; on S9 we
// upload the chosen avatar and set the post-auth flag, returning the user to
// MainTabView via ContentView's routing.
struct PostAuthOnboardingView: View {
    @AppStorage(OnboardingFlags.postAuthDoneKey) private var postAuthDone: Bool = false

    @State private var step: Int = 0
    @State private var avatar: AvatarChoice = .default
    @State private var isUploading: Bool = false
    @State private var uploadError: String?

    var body: some View {
        ZStack {
            switch step {
            case 0:
                AvatarPickerStep(selection: $avatar, onAdvance: advance)
            case 1:
                FirstSnapStep(onAdvance: advance)
            case 2:
                SpottedStep(onAdvance: advance)
            case 3:
                OnTheMapStep(
                    avatar: avatar,
                    isWorking: isUploading,
                    onAdvance: completeOnboarding
                )
            default:
                EmptyView()
            }

            if let uploadError {
                VStack {
                    Spacer()
                    Text(uploadError)
                        .font(.Brand.jakarta(.medium, size: 13))
                        .foregroundStyle(Color.coralDeep)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.creamSoft, in: .capsule)
                        .padding(.bottom, 100)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private func advance() {
        step = min(step + 1, 3)
    }

    private func completeOnboarding() {
        guard !isUploading else { return }
        isUploading = true
        uploadError = nil

        Task {
            do {
                let image = try await renderAvatarImage(for: avatar)
                _ = try await AvatarUpload.uploadAndSetAvatar(image)
                postAuthDone = true
            } catch {
                // Don't block onboarding completion on a transient upload error;
                // the user can change their avatar later from the profile tab.
                uploadError = "Couldn't save avatar — you can change it from your profile."
                postAuthDone = true
            }
            isUploading = false
        }
    }

    @MainActor
    private func renderAvatarImage(for choice: AvatarChoice) async throws -> UIImage {
        let view = CatWindowMark(
            size: 200,
            showSill: false,
            catColor: choice.color
        )
        .padding(28)
        .background(Color.creamSoft)
        .frame(width: 256, height: 256)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.uiImage else {
            throw RenderError.failed
        }
        return image
    }

    private enum RenderError: Error { case failed }
}
