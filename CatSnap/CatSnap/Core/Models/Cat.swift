import Foundation

struct Cat: Codable, Identifiable, Hashable {
    let id: UUID
    var createdBy: UUID?
    var name: String?
    var description: String?
    var primaryPhotoUrl: URL?
    var rarity: Rarity
    let createdAt: Date
    let updatedAt: Date

    enum Rarity: String, Codable, CaseIterable, Hashable {
        case common, uncommon, rare, legendary
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdBy        = "created_by"
        case name
        case description
        case primaryPhotoUrl  = "primary_photo_url"
        case rarity
        case createdAt        = "created_at"
        case updatedAt        = "updated_at"
    }
}
