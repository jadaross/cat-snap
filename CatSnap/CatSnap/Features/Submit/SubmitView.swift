import SwiftUI
import PhotosUI
import UIKit

struct SubmitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: SubmitModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var showCamera = false

    init(prefilledCatId: UUID? = nil) {
        _model = State(initialValue: SubmitModel(prefilledCatId: prefilledCatId))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                content
            }
            .navigationTitle("snap a sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") { dismiss() }
                        .font(.Brand.jakarta(.medium, size: 14))
                        .foregroundStyle(Color.stone)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.stage {
        case .pickingPhoto:
            photoSourceView
        case .capturingLocation:
            locationCapturingView
        case .editing, .submitting, .error:
            editorView
        case .done:
            successView
        }
    }

    // MARK: - Photo source

    private var photoSourceView: some View {
        VStack(spacing: 28) {
            Spacer()
            CatWindowMark(size: 120)
            Text("snap a cat")
                .font(.Brand.jakarta(.semibold, size: 18))
                .foregroundStyle(Color.ink)
            Spacer()

            VStack(spacing: 12) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button { showCamera = true } label: {
                        primaryLabel("take photo")
                    }
                }
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    secondaryLabel("from library")
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                Task { await model.acceptPhoto(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await model.acceptPhoto(image)
                }
            }
        }
    }

    private var locationCapturingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Color.coral)
            Text("getting your location…")
                .font(.Brand.jakarta(.medium, size: 14))
                .foregroundStyle(Color.stone)
        }
    }

    // MARK: - Editor

    private var editorView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = model.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal, 16)
                }

                if let label = model.locationLabel {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color.coral)
                        Text(label)
                            .font(.Brand.jakarta(.medium, size: 13))
                            .foregroundStyle(Color.stone)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("name")
                        .font(.Brand.jakarta(.semibold, size: 13))
                        .foregroundStyle(Color.ink)
                    TextField("optional — Marmalade, etc.", text: $model.catName)
                        .font(.Brand.jakarta(.regular, size: 16))
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(Color.creamSoft, in: .rect(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stoneLight, lineWidth: 1))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("tags")
                        .font(.Brand.jakarta(.semibold, size: 13))
                        .foregroundStyle(Color.ink)
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 80), spacing: 6, alignment: .leading)],
                        alignment: .leading,
                        spacing: 6
                    ) {
                        ForEach(TagChip.presets, id: \.self) { tag in
                            TagChip(
                                tag: tag,
                                isActive: model.tags.contains(tag),
                                onTap: { model.toggleTag(tag) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)

                if case .error(let msg) = model.stage {
                    Text(msg)
                        .font(.Brand.jakarta(.medium, size: 13))
                        .foregroundStyle(Color.coralDeep)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Button {
                    Task { await model.submit() }
                } label: {
                    primaryLabel(model.stage == .submitting ? "submitting…" : "submit")
                }
                .disabled(model.stage == .submitting)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.sage)
            Text("submitted")
                .font(.Brand.jakarta(.semibold, size: 22))
                .foregroundStyle(Color.ink)
            Text("you spotted a cat.")
                .font(.Brand.jakarta(.regular, size: 14))
                .foregroundStyle(Color.stone)

            Button { dismiss() } label: {
                primaryLabel("back to map")
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
    }

    // MARK: - Buttons

    private func primaryLabel(_ text: String) -> some View {
        Text(text)
            .font(.Brand.jakarta(.semibold, size: 16))
            .foregroundStyle(Color.creamSoft)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.coral, in: .rect(cornerRadius: 10))
    }

    private func secondaryLabel(_ text: String) -> some View {
        Text(text)
            .font(.Brand.jakarta(.semibold, size: 16))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.creamSoft, in: .rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.stoneLight, lineWidth: 1))
    }
}

// MARK: - Camera wrapper

private struct CameraPicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPick(image)
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
