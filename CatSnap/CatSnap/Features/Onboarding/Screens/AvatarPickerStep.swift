import SwiftUI

// 06 · Avatar picker — 6 colored window-cats in a 3-col grid. The selection
// is bound back to the parent so it can render the user's pin on S9 and
// upload the chosen avatar after S9 advances.
struct AvatarPickerStep: View {
    @Binding var selection: AvatarChoice
    let onAdvance: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR AVATAR")
                        .font(.Brand.mono(size: 11))
                        .foregroundStyle(Color.stone)
                        .tracking(1.4)
                    Text("pick your\nwindow cat.")
                        .font(.Brand.frauncesBlackItalic(size: 36))
                        .foregroundStyle(Color.ink)
                        .tracking(-1.4)
                    Text("You'll appear as this cat across CatSnap. Change anytime.")
                        .font(.Brand.jakarta(.regular, size: 14))
                        .foregroundStyle(Color.stone)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 24)

                Spacer(minLength: 0)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AvatarChoice.all) { choice in
                        Button {
                            selection = choice
                        } label: {
                            VStack(spacing: 4) {
                                CatWindowMark(
                                    size: 72,
                                    showSill: false,
                                    catColor: choice.color
                                )
                                Text(choice.name.uppercased())
                                    .font(.Brand.mono(size: 10))
                                    .foregroundStyle(selection == choice ? Color.ink : Color.stone)
                                    .tracking(0.6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                selection == choice ? Color.creamSoft : Color.clear,
                                in: .rect(cornerRadius: 14)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selection == choice ? Color.coral : Color.stoneLight, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    OnboardingDots(activeIndex: 5, count: 9)
                    OnboardingPrimaryButton(title: "Next →", action: onAdvance)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .padding(.top, 12)
            }
        }
    }
}

#Preview {
    StatefulPreviewWrapper(AvatarChoice.default) { binding in
        AvatarPickerStep(selection: binding, onAdvance: {})
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content
    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }
    var body: some View { content($value) }
}
