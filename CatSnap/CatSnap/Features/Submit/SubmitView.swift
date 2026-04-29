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
                if isOnCameraStage {
                    Color.ink.ignoresSafeArea()
                } else {
                    Color.cream.ignoresSafeArea()
                }
                content
            }
            .navigationTitle(isOnCameraStage ? "" : "snap a sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isOnCameraStage ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") { dismiss() }
                        .font(.Brand.jakarta(.medium, size: 14))
                        .foregroundStyle(Color.stone)
                }
            }
        }
    }

    private var isOnCameraStage: Bool {
        if case .pickingPhoto = model.stage { return true }
        return false
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
        ZStack {
            // Dark viewfinder placeholder. We don't run an AV preview in v1 —
            // tap-shutter hands off to UIImagePickerController which surfaces
            // the live camera UI. Source: `CatSnap App.html` lines 401–457.
            LinearGradient(
                colors: [
                    Color(red: 0.29, green: 0.26, blue: 0.23),
                    Color(red: 0.16, green: 0.14, blue: 0.13),
                    Color(red: 0.08, green: 0.07, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.coralDeep.opacity(0.25), .clear],
                center: UnitPoint(x: 0.52, y: 0.58),
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                cameraTopBar
                tipCard
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                Spacer()
                modeSelector
                    .padding(.bottom, 24)
                captureRow
                    .padding(.horizontal, 36)
                    .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
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

    private var cameraTopBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.creamSoft)
                    .frame(width: 36, height: 36)
                    .background(Color.creamSoft.opacity(0.15), in: .circle)
                    .overlay(Circle().stroke(Color.creamSoft.opacity(0.55), lineWidth: 1.5))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var tipCard: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.coral.opacity(0.18))
                CatWindowMark(size: 20, showSill: false)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("snap a sighting")
                    .font(.Brand.jakarta(.bold, size: 13))
                    .foregroundStyle(Color.ink)
                Text("photo will be tagged with your location.")
                    .font(.Brand.jakarta(.regular, size: 11))
                    .foregroundStyle(Color.stone)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.creamSoft.opacity(0.97), in: .rect(cornerRadius: 14))
        .shadow(color: Color.ink.opacity(0.4), radius: 8, y: 6)
    }

    private var modeSelector: some View {
        HStack(spacing: 18) {
            modeLabel("VIDEO", isActive: false)
            modeLabel("PHOTO", isActive: true)
            modeLabel("BURST", isActive: false)
        }
    }

    private func modeLabel(_ text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.Brand.jakarta(.bold, size: 11))
            .tracking(1.5)
            .foregroundStyle(
                isActive ? Color.streetlampYellow : Color.creamSoft.opacity(0.55)
            )
    }

    private var captureRow: some View {
        HStack {
            // UPLOAD — opens the photo library
            PhotosPicker(selection: $pickedItem, matching: .images) {
                VStack(spacing: 5) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.creamSoft.opacity(0.14))
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.creamSoft.opacity(0.55), lineWidth: 1.5)
                            )
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.creamSoft)
                    }
                    Text("UPLOAD")
                        .font(.Brand.mono(size: 9))
                        .tracking(0.8)
                        .foregroundStyle(Color.creamSoft.opacity(0.9))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // SHUTTER — opens the live camera
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                }
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.creamSoft, lineWidth: 4)
                            .frame(width: 76, height: 76)
                        Circle()
                            .fill(Color.coral)
                            .frame(width: 64, height: 64)
                    }
                    Text("SNAP")
                        .font(.Brand.mono(size: 9))
                        .tracking(0.8)
                        .foregroundStyle(Color.creamSoft.opacity(0.9))
                        .offset(y: 6)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // FLIP — visual placeholder, native picker handles the active flip
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.creamSoft.opacity(0.14))
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.creamSoft.opacity(0.55), lineWidth: 1.5)
                        )
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.creamSoft)
                }
                Color.clear.frame(height: 12) // align with UPLOAD label
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
