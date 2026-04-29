import SwiftUI
import PhotosUI

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    let profile: Profile
    let onSave: (UserProfileModel.Update) async throws -> Void

    @State private var displayName: String = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedAvatar: UIImage?
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        avatarSection
                        nameField
                        if let error {
                            Text(error)
                                .font(.Brand.jakarta(.medium, size: 13))
                                .foregroundStyle(Color.coralDeep)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") { dismiss() }
                        .foregroundStyle(Color.stone)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("save") { Task { await save() } }
                        .foregroundStyle(Color.coral)
                        .disabled(isSaving)
                }
            }
        }
        .onAppear {
            displayName = profile.displayName ?? ""
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedAvatar = image
                }
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Color.creamDeep
                    .frame(width: 96, height: 96)
                    .clipShape(.circle)
                    .overlay {
                        if let pickedAvatar {
                            Image(uiImage: pickedAvatar)
                                .resizable()
                                .scaledToFill()
                        } else if let url = profile.avatarUrl {
                            AsyncCatImage(url: url)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.stone)
                        }
                    }
                    .clipShape(.circle)
                    .overlay(Circle().stroke(Color.stoneLight, lineWidth: 1))
            }

            PhotosPicker(selection: $pickedItem, matching: .images) {
                Text("change photo")
                    .font(.Brand.jakarta(.medium, size: 14))
                    .foregroundStyle(Color.coral)
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("display name")
                .font(.Brand.jakarta(.semibold, size: 13))
                .foregroundStyle(Color.ink)
            TextField("how should we display you?", text: $displayName)
                .font(.Brand.jakarta(.regular, size: 16))
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color.creamSoft, in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stoneLight, lineWidth: 1))
                .textInputAutocapitalization(.words)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        error = nil
        do {
            try await onSave(.init(displayName: displayName, avatar: pickedAvatar))
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

extension UserProfileModel {
    struct Update {
        let displayName: String
        let avatar: UIImage?
    }
}
