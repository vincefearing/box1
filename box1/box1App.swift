import SwiftUI
import SwiftData

@main
struct box1App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CachedPokemon.self, UserPokemon.self])
    }
}
