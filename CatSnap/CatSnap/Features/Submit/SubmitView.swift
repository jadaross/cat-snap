import SwiftUI
import PhotosUI
import UIKit
import CoreLocation

struct SubmitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: SubmitModel
    @State private var pickedItem: PhotosPickerItem?
    @State private var camera = CameraController()

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
            // Attached to the root, not to photoSourceView: that view is torn
            // down the instant the stage changes, taking any handler on it —
            // and any in-flight presentation — with it.
            .onChange(of: pickedItem) { _, newItem in
                guard let newItem else { return }
                // Clear immediately so re-picking the same asset still fires;
                // PhotosPickerItem equality is by asset identity.
                pickedItem = nil
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        let exif = ExifMetadata.extract(from: data)
                        await model.acceptUploadedPhoto(image, exif: exif)
                    }
                }
            }
            .navigationTitle(isOnCameraStage ? "" : String(localized: "snap a sighting"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isOnCameraStage ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "cancel")) { dismiss() }
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
        case .editing, .submitting, .error:
            editorView
        case .done:
            successView
        }
    }

    // MARK: - Photo source

    // The live viewfinder. This was a dark gradient standing in for a camera,
    // with the shutter merely presenting UIImagePickerController — so the real
    // camera only appeared once the user believed they'd already taken the
    // photo. The session now runs behind the same branded chrome, and the
    // gradient survives as the backdrop for the states with nothing to show.
    // Source: `CatSnap App.html` lines 401–457.
    private var photoSourceView: some View {
        ZStack {
            if camera.status == .running {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else {
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
            }

            VStack(spacing: 0) {
                cameraTopBar
                Spacer()
                cameraFallbackNotice
                captureRow
                    .padding(.horizontal, 36)
                    .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
        // Scoped to this view only — a viewfinder is the one dark surface the
        // light-only brand allows.
        .task { await camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: model.stage) { _, stage in
            // Don't leave the session burning battery behind the editor.
            if stage != .pickingPhoto { camera.stop() }
        }
    }

    /// Explains a viewfinder that isn't running. Replaces the old silent
    /// no-op, where a tap on the shutter with no camera present did nothing
    /// at all and said nothing about why.
    @ViewBuilder
    private var cameraFallbackNotice: some View {
        switch camera.status {
        case .running, .idle:
            EmptyView()
        case .unavailable:
            VStack(spacing: 6) {
                Text(String(localized: "no camera on this device"))
                    .font(.Brand.jakarta(.bold, size: 15))
                    .foregroundStyle(Color.creamSoft)
                Text(String(localized: "upload a photo instead"))
                    .font(.Brand.jakarta(.regular, size: 13))
                    .foregroundStyle(Color.creamSoft.opacity(0.75))
            }
            .padding(.bottom, 28)
        case .denied:
            VStack(spacing: 10) {
                Text(String(localized: "camera access is off"))
                    .font(.Brand.jakarta(.bold, size: 15))
                    .foregroundStyle(Color.creamSoft)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(String(localized: "open Settings"))
                        .font(.Brand.jakarta(.bold, size: 13))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.creamSoft, in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 28)
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

            // SHUTTER — captures from the live session
            Button {
                Task {
                    guard let image = await camera.capture() else { return }
                    await model.acceptPhoto(image)
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
            .disabled(camera.status != .running || camera.isCapturing)
            .opacity(camera.status == .running ? 1 : 0.35)

            Spacer()

            // FLIP — real now that we own the session
            Button { camera.flip() } label: {
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
            .buttonStyle(.plain)
            .disabled(!camera.canFlip || camera.status != .running)
            .opacity(camera.canFlip && camera.status == .running ? 1 : 0.35)
            .accessibilityLabel(String(localized: "flip camera"))
        }
    }

    // MARK: - Editor

    private var editorView: some View {
        VStack(spacing: 0) {
            // "NEW SIGHTING" stamp header — replaces the SwiftUI nav title in
            // editing stage so the styling matches `CatSnap App.html` line 735.
            HStack {
                Spacer()
                Text(String(localized: "NEW SIGHTING"))
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
                    nameSuggestions
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

    // Unconditional by design. This used to be gated on a non-nil location,
    // so any failed or slow device fix rendered no map at all — leaving the
    // user with no way to say where they were. The pin now always exists;
    // `model.isLocationConfirmed` is what decides whether it may be filed.
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            MapPinPicker(
                coordinate: Binding(
                    get: { model.location.coordinate },
                    set: { model.updatePin(to: $0) }
                ),
                height: 160,
                onRecentre: { await model.recentreOnDevice() }
            )
            .overlay(alignment: .topTrailing) {
                if model.isResolvingLocation {
                    ProgressView()
                        .tint(Color.coral)
                        .padding(6)
                        .background(Color.creamSoft, in: .capsule)
                        .padding(8)
                }
            }

            if let notice = model.locationNotice {
                Text(notice)
                    .font(.Brand.jakarta(.medium, size: 12))
                    .foregroundStyle(Color.coralDeep)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let label = model.locationLabel, !label.isEmpty {
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
                        Text(String(localized: "use my location"))
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
                            Text(String(localized: "use photo location"))
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

    private var nameField: some View {
        TextField(String(localized: "Marmalade, Biscuit…"), text: $model.catName)
            .font(.Brand.jakarta(.bold, size: 16))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.creamSoft, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .onChange(of: model.catName) { _, _ in model.nameChanged() }
    }

    // Type-ahead over existing cats. Without it every sighting filed from the
    // tab-bar Snap minted a brand-new cat, so a cat spotted five times became
    // five cats. Selection is sticky rather than a plain text autocomplete —
    // attaching to an existing cat and creating a new one look identical once
    // the text matches, so the choice has to stay visible.
    @ViewBuilder
    private var nameSuggestions: some View {
        if let selected = model.selectedCat {
            selectedCatRow(selected)
        } else if !model.isCatPrefilled {
            VStack(spacing: 6) {
                ForEach(model.suggestions.prefix(5)) { suggestion in
                    Button { model.selectSuggestion(suggestion) } label: {
                        suggestionRow(suggestion)
                    }
                    .buttonStyle(.plain)
                }

                // Keeps deliberate duplicates possible — two different cats
                // called Marmalade in two cities is a normal thing.
                if !model.suggestions.isEmpty {
                    Button { model.clearSelection() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text(String(localized: "new cat named \"\(trimmedCatName)\""))
                                .font(.Brand.jakarta(.bold, size: 13))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(Color.stone)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(Color.cream, in: .rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.stoneLight, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var trimmedCatName: String {
        model.catName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func suggestionRow(_ suggestion: CatSuggestion) -> some View {
        HStack(spacing: 10) {
            AsyncCatImage(url: suggestion.primaryPhotoUrl ?? suggestion.lastPhotoUrl)
                .frame(width: 36, height: 36)
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.catName ?? String(localized: "unnamed"))
                    .font(.Brand.jakarta(.bold, size: 14))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                Text(suggestionDetail(suggestion))
                    .font(.Brand.mono(size: 10))
                    .tracking(0.6)
                    .foregroundStyle(Color.stone)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let rarity = suggestion.rarity {
                RarityBadge(rarity: rarity, size: .small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.creamSoft, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
    }

    private func selectedCatRow(_ suggestion: CatSuggestion) -> some View {
        HStack(spacing: 10) {
            AsyncCatImage(url: suggestion.primaryPhotoUrl ?? suggestion.lastPhotoUrl)
                .frame(width: 36, height: 36)
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "logging under \(suggestion.catName ?? "this cat")"))
                    .font(.Brand.jakarta(.bold, size: 14))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                Text(suggestionDetail(suggestion))
                    .font(.Brand.mono(size: 10))
                    .tracking(0.6)
                    .foregroundStyle(Color.stone)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button { model.clearSelection() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.stone)
                    .frame(width: 28, height: 28)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "file under a new cat instead"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.creamSoft, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.coral, lineWidth: 1.5))
    }

    private func suggestionDetail(_ suggestion: CatSuggestion) -> String {
        var parts: [String] = []
        parts.append(suggestion.sightingCount == 1
                     ? String(localized: "1 SIGHTING")
                     : String(localized: "\(suggestion.sightingCount) SIGHTINGS"))
        if let last = suggestion.lastSeenAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            parts.append(formatter.localizedString(for: last, relativeTo: Date()).uppercased())
        }
        return parts.joined(separator: " · ")
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
                    .background(
                        model.canSubmit ? Color.coral : Color.stoneLight,
                        in: .rect(cornerRadius: 14)
                    )
            }
            .disabled(model.stage == .submitting || !model.canSubmit)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(Color.creamSoft)
    }

    private var submitButtonLabel: String {
        if model.stage == .submitting { return String(localized: "submitting…") }
        // Filing at the fallback pin would put the cat somewhere it has never
        // been, with no in-app way to correct it. Say what's missing instead.
        if !model.isLocationConfirmed { return String(localized: "set the spot first") }
        let trimmed = model.catName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // TODO: Use format string for v2: String(localized: "Pin %@ on the map  →", arguments: [trimmed])
            return "Pin \(trimmed) on the map  →"
        }
        return String(localized: "Pin on the map  →")
    }

    // MARK: - Success

    private var successView: some View {
        // Source: `CatSnap App.html` lines 904–941 (SpottedConfirm).
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 6) {
                spottedHero
                    .padding(.bottom, 20)

                Text(String(localized: "+1 SIGHTING"))
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
                    Text(String(localized: "See on the map"))
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
