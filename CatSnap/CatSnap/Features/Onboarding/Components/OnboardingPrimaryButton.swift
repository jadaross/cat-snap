import SwiftUI

// The pill button used across onboarding. Three palettes cover every screen:
// - .ink   → cream-on-ink (the default "Next →" / "Get started →")
// - .coral → cream-on-coral (camera permission, S8 "Pin it on the map")
// - .cream → ink-on-cream (rare; not currently used but kept for symmetry)
struct OnboardingPrimaryButton: View {
    enum Palette { case ink, coral, cream }

    let title: String
    var palette: Palette = .ink
    var isWorking: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.Brand.jakarta(.bold, size: 16))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(background, in: .rect(cornerRadius: 14))
                .opacity(isWorking ? 0.6 : 1)
        }
        .disabled(isWorking)
    }

    private var background: Color {
        switch palette {
        case .ink: return .ink
        case .coral: return .coral
        case .cream: return .creamSoft
        }
    }

    private var foreground: Color {
        switch palette {
        case .ink, .coral: return .creamSoft
        case .cream: return .ink
        }
    }
}

// "Maybe later" / "Not now" / "I already have an account" — same shape across screens.
struct OnboardingTextButton: View {
    let title: String
    var color: Color = .stone
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.Brand.jakarta(.semibold, size: 14))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
    }
}
