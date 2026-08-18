import SwiftUI

// Identifies what's being reported. The raw string matches the
// `public.report_target` enum in migration 0001.
enum ReportTarget: Identifiable, Hashable {
    case sighting(UUID)
    case profile(UUID)
    case cat(UUID)

    var id: String {
        switch self {
        case .sighting(let id): return "sighting:\(id)"
        case .profile(let id):  return "profile:\(id)"
        case .cat(let id):      return "cat:\(id)"
        }
    }

    var dbType: String {
        switch self {
        case .sighting: return "sighting"
        case .profile:  return "profile"
        case .cat:      return "cat"
        }
    }

    var dbId: UUID {
        switch self {
        case .sighting(let id), .profile(let id), .cat(let id): return id
        }
    }

    var subjectLabel: String {
        switch self {
        case .sighting: return "this sighting"
        case .profile:  return "this profile"
        case .cat:      return "this cat"
        }
    }
}

// Maps to the `public.report_reason` enum.
enum ReportReason: String, CaseIterable, Identifiable {
    case spam
    case inappropriate
    case abuse
    case copyright
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spam:          return "Spam"
        case .inappropriate: return "Inappropriate content"
        case .abuse:         return "Abuse or harassment"
        case .copyright:     return "Copyright"
        case .other:         return "Other"
        }
    }
}

struct ReportSheet: View {
    let target: ReportTarget
    var onSubmitted: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason = .inappropriate
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        intro

                        VStack(alignment: .leading, spacing: 8) {
                            Text("REASON")
                                .font(.Brand.mono(size: 10))
                                .tracking(1.2)
                                .foregroundStyle(Color.stone)
                            VStack(spacing: 0) {
                                ForEach(Array(ReportReason.allCases.enumerated()), id: \.element.id) { index, item in
                                    reasonRow(item, isLast: index == ReportReason.allCases.count - 1)
                                }
                            }
                            .background(Color.creamSoft, in: .rect(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DETAILS (OPTIONAL)")
                                .font(.Brand.mono(size: 10))
                                .tracking(1.2)
                                .foregroundStyle(Color.stone)
                            TextField("anything else we should know?", text: $details, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Color.creamSoft, in: .rect(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.stoneLight, lineWidth: 1))
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.Brand.jakarta(.regular, size: 12))
                                .foregroundStyle(Color.coralDeep)
                        }

                        submitButton
                            .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") { dismiss() }
                        .foregroundStyle(Color.ink)
                }
            }
        }
    }

    private var intro: some View {
        Text("we'll review \(target.subjectLabel) within 24 hours. thanks for keeping catsnap kind.")
            .font(.Brand.jakarta(.regular, size: 13))
            .foregroundStyle(Color.stone)
    }

    private func reasonRow(_ item: ReportReason, isLast: Bool) -> some View {
        Button { reason = item } label: {
            HStack {
                Text(item.label)
                    .font(.Brand.jakarta(.medium, size: 14))
                    .foregroundStyle(Color.ink)
                Spacer()
                if reason == item {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.coral)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.stoneLight)
                    .frame(height: 1)
                    .padding(.leading, 12)
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack {
                if isSubmitting { ProgressView().tint(Color.creamSoft) }
                Text(isSubmitting ? "sending…" : "submit report")
                    .font(.Brand.jakarta(.bold, size: 15))
            }
            .foregroundStyle(Color.creamSoft)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.coral, in: .rect(cornerRadius: 14))
        }
        .disabled(isSubmitting)
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
            try await FriendsGraph.report(
                targetType: target.dbType,
                targetId: target.dbId,
                reason: reason.rawValue,
                details: trimmed.isEmpty ? nil : trimmed
            )
            onSubmitted?()
            dismiss()
        } catch {
            errorMessage = AppError.map(error).localizedDescription
        }
    }
}
