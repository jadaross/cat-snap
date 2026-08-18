import SwiftUI
import CoreLocation

// Multi-axis filter for the guide grid: status / rarity / tags / time / area /
// favourites. Edits a draft `GuideFilterCriteria`; commits via `onApply` on
// "Apply" tap so partial selections don't trigger refetches.
struct GuideFilterSheet: View {
    let initial: GuideFilterCriteria
    var onApply: (GuideFilterCriteria) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: GuideFilterCriteria
    @State private var locationManager = LocationManager()
    @State private var areaEnabled: Bool = false
    @State private var areaCoordinate: CLLocationCoordinate2D = .init(latitude: 51.5074, longitude: -0.1278)
    @State private var areaRadiusKm: Double = 2.0
    @State private var seenAfterEnabled: Bool = false
    @State private var seenBeforeEnabled: Bool = false
    @State private var seenAfter: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var seenBefore: Date = Date()

    init(initial: GuideFilterCriteria, onApply: @escaping (GuideFilterCriteria) -> Void) {
        self.initial = initial
        self.onApply = onApply
        _draft = State(initialValue: initial)
        _areaEnabled = State(initialValue: initial.nearLat != nil)
        if let lat = initial.nearLat, let lng = initial.nearLng {
            _areaCoordinate = State(initialValue: .init(latitude: lat, longitude: lng))
        }
        if let r = initial.nearRadiusM {
            _areaRadiusKm = State(initialValue: Double(r) / 1000.0)
        }
        _seenAfterEnabled = State(initialValue: initial.seenAfter != nil)
        _seenBeforeEnabled = State(initialValue: initial.seenBefore != nil)
        if let after = initial.seenAfter   { _seenAfter  = State(initialValue: after) }
        if let before = initial.seenBefore { _seenBefore = State(initialValue: before) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    statusSection
                    raritySection
                    tagsSection
                    timeSection
                    areaSection
                    favouritesSection
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color.cream.ignoresSafeArea())
            .navigationTitle("filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("reset") { reset() }
                        .font(.Brand.jakarta(.medium, size: 14))
                        .foregroundStyle(Color.stone)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { commit() }
                        .font(.Brand.jakarta(.bold, size: 14))
                        .foregroundStyle(Color.coral)
                }
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("STATUS")
            HStack(spacing: 6) {
                statusChip("all", isActive: draft.status == .all) { draft.status = .all }
                statusChip("spotted", isActive: draft.status == .spotted) { draft.status = .spotted }
            }
        }
    }

    private var raritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("RARITY")
            FlowingChips(items: Cat.Rarity.allCases.map { $0.rawValue }) { rawValue in
                guard let r = Cat.Rarity(rawValue: rawValue) else { return AnyView(EmptyView()) }
                let active = (draft.rarities ?? []).contains(r)
                return AnyView(
                    chip(rawValue, isActive: active) {
                        var current = Set(draft.rarities ?? [])
                        if active { current.remove(r) } else { current.insert(r) }
                        draft.rarities = current.isEmpty ? nil : Array(current).sorted { $0.rawValue < $1.rawValue }
                    }
                )
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TAGS")
            FlowingChips(items: TagChip.presets) { tag in
                let active = (draft.tags ?? []).contains(tag)
                return AnyView(
                    chip(tag, isActive: active) {
                        var current = Set(draft.tags ?? [])
                        if active { current.remove(tag) } else { current.insert(tag) }
                        draft.tags = current.isEmpty ? nil : Array(current).sorted()
                    }
                )
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TIME")
            Toggle("seen after a date", isOn: $seenAfterEnabled)
                .font(.Brand.jakarta(.medium, size: 14))
                .tint(Color.coral)
            if seenAfterEnabled {
                DatePicker("after", selection: $seenAfter, displayedComponents: .date)
                    .font(.Brand.jakarta(.regular, size: 13))
                    .tint(Color.coral)
            }
            Toggle("seen before a date", isOn: $seenBeforeEnabled)
                .font(.Brand.jakarta(.medium, size: 14))
                .tint(Color.coral)
            if seenBeforeEnabled {
                DatePicker("before", selection: $seenBefore, displayedComponents: .date)
                    .font(.Brand.jakarta(.regular, size: 13))
                    .tint(Color.coral)
            }
        }
    }

    private var areaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("AREA")
            Toggle("filter by area", isOn: $areaEnabled)
                .font(.Brand.jakarta(.medium, size: 14))
                .tint(Color.coral)

            if areaEnabled {
                MapPinPicker(
                    coordinate: $areaCoordinate,
                    height: 180,
                    onRecentre: {
                        let next = try? await locationManager.requestOneShot()
                        return next?.coordinate
                    }
                )

                HStack {
                    Text("RADIUS")
                        .font(.Brand.mono(size: 10))
                        .tracking(0.8)
                        .foregroundStyle(Color.stone)
                    Spacer()
                    Text(String(format: "%.1f km", areaRadiusKm))
                        .font(.Brand.mono(size: 11))
                        .foregroundStyle(Color.ink)
                }
                Slider(value: $areaRadiusKm, in: 0.2...20, step: 0.1)
                    .tint(Color.coral)
            }
        }
    }

    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("FAVOURITES")
            Toggle("favourites only", isOn: $draft.favoritesOnly)
                .font(.Brand.jakarta(.medium, size: 14))
                .tint(Color.coral)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.Brand.mono(size: 10))
            .tracking(1.2)
            .foregroundStyle(Color.stone)
    }

    private func statusChip(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.Brand.jakarta(.bold, size: 12))
                .foregroundStyle(isActive ? Color.creamSoft : Color.stone)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? Color.ink : Color.creamSoft, in: .capsule)
                .overlay(Capsule().stroke(isActive ? Color.clear : Color.stoneLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func chip(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.Brand.jakarta(.medium, size: 12))
                .foregroundStyle(isActive ? Color.coralDeep : Color.stone)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isActive ? Color.creamSoft : Color.stoneLight.opacity(0.5), in: .capsule)
                .overlay(Capsule().stroke(isActive ? Color.coral : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func reset() {
        draft = GuideFilterCriteria()
        areaEnabled = false
        areaRadiusKm = 2.0
        seenAfterEnabled = false
        seenBeforeEnabled = false
    }

    private func commit() {
        var final = draft
        final.seenAfter  = seenAfterEnabled  ? seenAfter  : nil
        final.seenBefore = seenBeforeEnabled ? seenBefore : nil
        if areaEnabled {
            final.nearLat = areaCoordinate.latitude
            final.nearLng = areaCoordinate.longitude
            final.nearRadiusM = Int(areaRadiusKm * 1000)
        } else {
            final.nearLat = nil
            final.nearLng = nil
            final.nearRadiusM = nil
        }
        onApply(final)
        dismiss()
    }
}

/// Lightweight wrap-around chip row built on LazyVGrid with adaptive columns,
/// reused by rarity and tags sections. AnyView is a small price for keeping
/// the per-chip closure flexible.
private struct FlowingChips: View {
    let items: [String]
    let chip: (String) -> AnyView

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80), spacing: 6, alignment: .leading)],
            alignment: .leading,
            spacing: 6
        ) {
            ForEach(items, id: \.self) { item in
                chip(item)
            }
        }
    }
}
