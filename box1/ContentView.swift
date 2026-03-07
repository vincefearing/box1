import SwiftUI

struct ContentView: View {
    @State private var pokemon: [Pokemon] = []
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("\(pokemon.count) Pokemon loaded")
        }
        .padding()
        .task {
            do {
                let service = PokemonService()
                pokemon = try await service.fetchAllPokemon()
                print("Fetched \(pokemon.count) Pokemon")
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
