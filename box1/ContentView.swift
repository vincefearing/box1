import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CachedPokemon.dexNumber) private var cachedPokemon: [CachedPokemon]
    @Query private var cachedGames: [CachedGame]

    var body: some View {
        PokemonGridView()
        .task {
            guard cachedPokemon.isEmpty else {
                // Data exists, but check if sprites need downloading
                if !SpriteService.spriteExists(dexNumber: 1, form: "default") {
                    let spriteService = SpriteService()
                    await spriteService.downloadAllSprites(from: cachedPokemon)
                }
                return
            }
            do {
                let service = PokemonService()
                let pokemon = try await service.fetchAllPokemon()
                try service.saveAllPokemon(pokemon, context: modelContext)
                print("Saved \(pokemon.count) Pokemon to local storage")

                let games = try await service.fetchAllGames()
                try service.saveAllGames(games, context: modelContext)
                print("Saved \(games.count) games to local storage")

                // Download sprites after data is saved
                let spriteService = SpriteService()
                await spriteService.downloadAllSprites(from: cachedPokemon)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
