import Foundation

struct UserProfile: Codable {
    var id: UUID
    var displayName: String
    var isPremium: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case isPremium = "is_premium"
        case createdAt = "created_at"
    }
}
