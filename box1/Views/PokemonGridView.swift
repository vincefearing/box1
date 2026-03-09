import SwiftUI
import SwiftData

struct PokemonGridView: View {
    @Query(sort: \CachedPokemon.dexNumber) private var pokemon: [CachedPokemon]
    @State private var searchText = ""

    private var filteredPokemon: [CachedPokemon] {
        if searchText.isEmpty {
            return pokemon
        }
        return pokemon.filter { mon in
            mon.name.localizedCaseInsensitiveContains(searchText) ||
            String(mon.dexNumber).contains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Game filter pills
                    // Stats bar
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(filteredPokemon, id: \.dexNumber) { mon in
                            PokemonCard(pokemon: mon)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .searchable(text: $searchText, prompt: "Search Pokemon")
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
