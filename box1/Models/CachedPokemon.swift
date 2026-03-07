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
    var typesData: Data
    var spritesData: Data
    var locationsData: Data
    var regionalDexNumbersData: Data
    var evolutionChainData: Data
    
    @MainActor init(from pokemon: Pokemon) throws {
        let encoder = JSONEncoder()
        self.dexNumber = pokemon.dexNumber
        self.name = pokemon.name
        self.generation = pokemon.generation
        self.originRegion = pokemon.originRegion
        self.height = pokemon.height
        self.weight = pokemon.weight
        self.pokemonDescription = pokemon.description
        self.cryUrl = pokemon.cryUrl
        self.typesData = try encoder.encode(pokemon.types)
        self.spritesData = try encoder.encode(pokemon.sprites)
        self.locationsData = try encoder.encode(pokemon.locations)
        self.regionalDexNumbersData = try encoder.encode(pokemon.regionalDexNumbers)
        self.evolutionChainData = try encoder.encode(pokemon.evolutionChain)
    }
}
