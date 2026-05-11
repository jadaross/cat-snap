import Foundation

// Locally-computed user achievements. The real `badges` table is deferred
// to v2 — until then, awards are derived from the user's sightings, cat
// count, and current streak (see AwardCatalog.swift).
struct Award: Identifiable, Hashable, Sendable {
    let id: String          // stable identifier — survives renders, used as Hashable key
    let emoji: String
    let label: String
    let description: String // shown in AwardDetailSheet
    let criteria: String    // user-facing "how to earn" line
    let rare: Bool
    let earned: Bool
}
