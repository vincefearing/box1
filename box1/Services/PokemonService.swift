import Foundation
import Supabase
import SwiftData

class PokemonService {
    func fetchAllPokemon() async throws -> [Pokemon] {
        let response: [Pokemon] = try await supabase
            .from("pokemon")
            .select("""
                dex_number,
                name,
                height,
                weight,
                generation,
                description,
                cry_url,
                evolution_chain,
                origin_region,
                types:pokemon_types(
                    ...types(name, color)
                ),
                sprites(
                    form:form_name,
                    normal_url,
                    shiny_url
                ),
                locations(
                    game_id,
                    location_info
                ),
                regional_dex_numbers(
                    game_id,
                    regional_number
                )
            """)
            .order("dex_number")
            .range(from: 0, to: 1099)
            .execute()
            .value
    
        return response
    }
    
    func fetchAllGames() async throws -> [Game] {
        let response: [Game] = try await supabase
            .from("games")
            .select("id, name, generation, region, game_group")
            .order("id")
            .execute()
            .value

        return response
    }

    func saveAllGames(_ games: [Game], context: ModelContext) throws {
        for game in games {
            let cached = CachedGame(from: game)
            context.insert(cached)
        }
        try context.save()
    }

    func saveAllPokemon(_ pokemonList: [Pokemon], context: ModelContext) throws {
        for pokemon in pokemonList {
            let cached = try CachedPokemon(from: pokemon)
            context.insert(cached)
        }
        try context.save()
    }
}
