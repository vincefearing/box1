import SwiftData
import SwiftUI

@Model
class CachedPokemon {
    @Attribute(.unique) var dexNumber: Int
    var name: String
    var generation: Int
    var originRegion: String
    var height: Double
    var weight: Double
    var pokemonDescription: String?
    var cryUrl: String
    var types: [Pokemon.PokemonType]
    var sprites: [Pokemon.PokemonSprite]
    var locations: [Pokemon.PokemonLocation]
    var regionalDexNumbers: [Pokemon.RegionalDexEntry]
    var evolutionChainData: Data

    init(from pokemon: Pokemon) throws {
        self.dexNumber = pokemon.dexNumber
        self.name = pokemon.name
        self.generation = pokemon.generation
        self.originRegion = pokemon.originRegion
        self.height = pokemon.height
        self.weight = pokemon.weight
        self.pokemonDescription = pokemon.description
        self.cryUrl = pokemon.cryUrl
        self.types = pokemon.types
        self.sprites = pokemon.sprites
        self.locations = pokemon.locations
        self.regionalDexNumbers = pokemon.regionalDexNumbers
        self.evolutionChainData = try JSONEncoder().encode(pokemon.evolutionChain)
    }

    var evolutionChain: Pokemon.EvolutionNode? {
        try? JSONDecoder().decode(Pokemon.EvolutionNode.self, from: evolutionChainData)
    }

    func spriteUrl(form: String, shiny: Bool) -> String? {
        let sprite = sprites.first { $0.form == form }
        if shiny { return sprite?.shinyUrl ?? sprite?.normalUrl }
        return sprite?.normalUrl
    }

    var primaryTypeColor: Color {
        guard let hex = types.first?.color else { return .gray }
        return Color(hex: hex)
    }

    func displayName(form: String) -> String {
        if form == "default" { return name.capitalized }
        let formLabel = form.replacing("-", with: " ").capitalized
        return "\(formLabel) \(name.capitalized)"
    }
}
