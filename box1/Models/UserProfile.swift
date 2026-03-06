import Foundation

struct UserProfile: Codable {
    var userId: UUID
    var displayName: String
    var userTag: String
    var nintendoId: String?
    var profilePictureUrl: String?
    var totalCaught: Int
    var createdAt: Date
    var badges: [Badge]
    var team: [TeamMember]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case userTag = "user_tag"
        case nintendoId = "nintendo_id"
        case profilePictureUrl = "profile_picture_url"
        case totalCaught = "total_caught"
        case createdAt = "created_at"
        case badges
        case team
    }

    struct TeamMember: Codable {
        var pokemonId: Int
        var form: String

        enum CodingKeys: String, CodingKey {
            case pokemonId = "pokemon_id"
            case form
        }
    }

    struct Badge: Codable {
        var name: String
        var tier: Int
    }
}