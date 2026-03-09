struct Game: Codable {
    let id: Int
    let name: String
    let generation: Int
    let region: String
    let gameGroup: String

    enum CodingKeys: String, CodingKey {
        case id, name, generation, region
        case gameGroup = "game_group"
    }
}