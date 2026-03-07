struct Pokemon: Codable, Sendable {
    let dexNumber: Int
    let name: String
    let generation: Int
    let originRegion: String
    let height: Double
    let weight: Double
    let description: String?
    let evolutionChain: EvolutionNode
    let cryUrl: String
    let types: [PokemonType]
    let sprites: [PokemonSprite]
    let locations: [PokemonLocation]
    let regionalDexNumbers: [RegionalDexEntry]

    enum CodingKeys: String, CodingKey {
        case dexNumber = "dex_number"
        case name
        case height
        case weight
        case generation
        case description
        case cryUrl = "cry_url"
        case evolutionChain = "evolution_chain"
        case originRegion = "origin_region"
        case types
        case sprites
        case locations
        case regionalDexNumbers = "regional_dex_numbers"
    }

    struct PokemonType: Codable, Sendable{
        let name: String
        let color: String
    }

    struct PokemonSprite: Codable, Sendable{
        let form: String
        let normalUrl: String
        let shinyUrl: String?

        enum CodingKeys: String, CodingKey {
            case form
            case normalUrl = "normal_url"
            case shinyUrl = "shiny_url"
        }
    }

    struct PokemonLocation: Codable, Sendable {
        let gameId: Int
        let locationInfo: String

        enum CodingKeys: String, CodingKey {
            case gameId = "game_id"
            case locationInfo = "location_info"
        }
    }

    struct RegionalDexEntry: Codable, Sendable {
        let gameId: Int
        let regionalNumber: Int

        enum CodingKeys: String, CodingKey {
            case gameId = "game_id"
            case regionalNumber = "regional_number"
        }
    }

    struct EvolutionNode: Codable, Sendable {
        let name: String
        let evolvesTo: [EvolutionNode]

        enum CodingKeys: String, CodingKey {
            case name
            case evolvesTo = "evolves_to"
        }
    }
}
