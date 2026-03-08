import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CachedPokemon.dexNumber) private var cachedPokemon: [CachedPokemon]
    
    var body: some View {
        PokemonGridView()
        .task {
            guard cachedPokemon.isEmpty else { return }
            do {
                let service = PokemonService()
                let pokemon = try await service.fetchAllPokemon()
                try service.saveAllPokemon(pokemon, context: modelContext)
                print("Fetched \(pokemon.count) Pokemon")
                print("Saved \(pokemon.count) Pokemon to local storage")
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
