import SwiftUI
import SwiftData

struct PokemonGridView: View {
    @Query(sort: \CachedPokemon.dexNumber) private var pokemon: [CachedPokemon]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Game filter pills
                    // Stats bar
                    // Search bar
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(pokemon, id: \.dexNumber) {
                            mon in PokemonCard(pokemon: mon)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Pokedex")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}
#Preview {
    PokemonGridView()
}
