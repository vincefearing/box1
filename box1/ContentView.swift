import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \CachedPokemon.dexNumber) private var cachedPokemon: [CachedPokemon]
    @Query private var cachedGames: [CachedGame]

    var body: some View {
        TabView {
            Tab("Pokedex", systemImage: "square.grid.2x2") {
                PokemonGridView()
            }
            Tab("Stats", systemImage: "chart.bar.fill") {
                StatsView()
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack {
                    ProfileView()
                }
            }
            Tab(role: .search) {
                PokemonGridView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .fullScreenCover(isPresented: .constant(!authManager.isSignedIn)) {
            SignInView()
        }
        .task {
            guard cachedPokemon.isEmpty else { return }
            do {
                let service = PokemonService()
                let pokemon = try await service.fetchAllPokemon()
                try service.saveAllPokemon(pokemon, context: modelContext)
                print("Saved \(pokemon.count) Pokemon to local storage")

                let games = try await service.fetchAllGames()
                try service.saveAllGames(games, context: modelContext)
                print("Saved \(games.count) games to local storage")
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
