import SwiftUI

// The 6 preset window-cat colors offered on the avatar picker (S6).
// Source: catsnap-onboarding.jsx S6 cats array. The `eye` field on the source
// JSX is unused by the Window component itself, so we only carry the body color.
struct AvatarChoice: Identifiable, Hashable {
    let id: Int
    let name: String
    let color: Color
}

extension AvatarChoice {
    static let all: [AvatarChoice] = [
        .init(id: 0, name: "Black",  color: .ink),
        .init(id: 1, name: "Ginger", color: Color(hex: 0xC97F3F)),
        .init(id: 2, name: "Grey",   color: Color(hex: 0x8A8580)),
        .init(id: 3, name: "Tabby",  color: Color(hex: 0x3A2A1C)),
        .init(id: 4, name: "White",  color: Color(hex: 0xD8CFC1)),
        .init(id: 5, name: "Calico", color: Color(hex: 0x5E3A1F)),
    ]

    // S6 ships with index 1 (Ginger) preselected, matching the design's `sel` default.
    static let `default`: AvatarChoice = all[1]
}
