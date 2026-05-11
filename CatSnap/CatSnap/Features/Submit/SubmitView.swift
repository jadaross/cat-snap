import SwiftUI
import PhotosUI
import UIKit
import CoreLocation

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
                    let exif = ExifMetadata.extract(from: data)
                    await model.acceptUploadedPhoto(image, exif: exif)
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
        VStack(spacing: 0) {
            // "NEW SIGHTING" stamp header — replaces the SwiftUI nav title in
            // editing stage so the styling matches `CatSnap App.html` line 735.
            HStack {
                Spacer()
                Text("NEW SIGHTING")
                    .font(.Brand.mono(size: 11))
                    .tracking(1.4)
                    .foregroundStyle(Color.stone)
                Spacer()
            }
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    photoCard
                    sectionLabel("LOCATION")
                    locationCard
                    sectionLabel("NAME")
                    nameField
                    sectionLabel("TAGS")
                    tagChips
                    if case .error(let msg) = model.stage {
                        Text(msg)
                            .font(.Brand.jakarta(.medium, size: 13))
                            .foregroundStyle(Color.coralDeep)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            stickyCTA
        }
    }

    private var photoCard: some View {
        ZStack(alignment: .topLeading) {
            if let image = model.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }

            Text(photoBadgeText)
                .font(.Brand.jakarta(.bold, size: 10))
                .tracking(0.4)
                .foregroundStyle(Color.creamSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.coral, in: .capsule)
                .padding(12)
        }
        .frame(height: 220)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.stoneLight, lineWidth: 1))
        .shadow(color: Color.ink.opacity(0.08), radius: 12, y: 8)
    }

    private var photoBadgeText: String {
        var prefix = "JUST NOW"
        if model.isFromCameraRoll {
            if let exifDate = model.exifSeenAt {
                let f = DateFormatter()
                f.dateFormat = "EEE · HH:mm"
                prefix = f.string(from: exifDate).uppercased()
            } else {
                prefix = "FROM CAMERA ROLL"
            }
        }
        if let label = model.locationLabel, !label.isEmpty {
            return "\(prefix) · \(label.uppercased())"
        }
        return prefix
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.Brand.mono(size: 10))
            .tracking(1.2)
            .foregroundStyle(Color.stone)
    }

    @ViewBuilder
    private var locationCard: some View {
        if let location = model.location {
            VStack(alignment: .leading, spacing: 8) {
                MapPinPicker(
                    coordinate: Binding(
                        get: { location.coordinate },
                        set: { model.updatePin(to: $0) }
                    ),
                    height: 160,
                    onRecentre: nil
                )

                if let label = model.locationLabel, !label.isEmpty {
                    Text(label.uppercased())
                        .font(.Brand.mono(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(Color.stone)
                }

                HStack(spacing: 8) {
                    Button { Task { await model.usePinFromDeviceLocation() } } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("use my location")
                                .font(.Brand.jakarta(.bold, size: 12))
                        }
                        .foregroundStyle(Color.coral)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.creamSoft, in: .capsule)
                        .overlay(Capsule().stroke(Color.stoneLight, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    if model.exifLocation != nil {
                        Button { Task { await model.usePinFromExif() } } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("use photo location")
                                    .font(.Brand.jakarta(.bold, size: 12))
                            }
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.creamSoft, in: .capsule)
                            .overlay(Capsule().stroke(Color.stoneLight, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var nameField: some View {
        TextField("Marmalade, Biscuit…", text: $model.catName)
            .font(.Brand.jakarta(.bold, size: 16))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.creamSoft, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
    }

    private var tagChips: some View {
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

    private var stickyCTA: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.stoneLight).frame(height: 1)
            Button {
                Task { await model.submit() }
            } label: {
                Text(submitButtonLabel)
                    .font(.Brand.jakarta(.bold, size: 16))
                    .foregroundStyle(Color.creamSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.coral, in: .rect(cornerRadius: 14))
            }
            .disabled(model.stage == .submitting)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(Color.creamSoft)
    }

    private var submitButtonLabel: String {
        if model.stage == .submitting { return "submitting…" }
        let trimmed = model.catName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return "Pin \(trimmed) on the map  →"
        }
        return "Pin on the map  →"
    }

    // MARK: - Success

    private var successView: some View {
        // Source: `CatSnap App.html` lines 904–941 (SpottedConfirm).
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 6) {
                spottedHero
                    .padding(.bottom, 20)

                Text("+1 SIGHTING")
                    .font(.Brand.mono(size: 11))
                    .tracking(1.6)
                    .foregroundStyle(Color.coral)
                    .padding(.top, 6)

                Text(spottedTitle)
                    .font(.Brand.frauncesBlackItalic(size: 44))
                    .tracking(-1.6)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-6)
                    .foregroundStyle(Color.ink)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button { dismiss() } label: {
                    Text("See on the map")
                        .font(.Brand.jakarta(.bold, size: 16))
                        .foregroundStyle(Color.creamSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.ink, in: .rect(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var spottedHero: some View {
        ZStack {
            // Sage pulse halo
            Circle()
                .fill(Color.sage.opacity(0.18))
                .frame(width: 200, height: 200)
                .modifier(SpottedPulseModifier())

            CatWindowMark(size: 140, showSill: false, frameColor: .coral, blink: true)

            // Sage check badge bottom-right of the window mark
            Image(systemName: "checkmark")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.creamSoft)
                .frame(width: 56, height: 56)
                .background(Color.sage, in: .circle)
                .overlay(Circle().stroke(Color.cream, lineWidth: 4))
                .shadow(color: Color.sage.opacity(0.4), radius: 8, y: 6)
                .offset(x: 60, y: 56)
        }
        .frame(height: 200)
    }

    private var spottedTitle: String {
        let trimmed = model.catName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return "\(trimmed.lowercased())\nspotted!"
        }
        return "spotted!"
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

// MARK: - Pulse ring (Spotted! hero)

private struct SpottedPulseModifier: ViewModifier {
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0.5

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                    scale = 2.4
                    opacity = 0
                }
            }
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
