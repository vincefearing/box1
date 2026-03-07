import SwiftData
import Foundation

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
}
