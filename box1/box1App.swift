import SwiftUI
import SwiftData

@main
struct box1App: App {
    @State private var authManager = AuthManager()
    @State private var storeManager = StoreManager()
    @AppStorage("appearance") private var appearance = 0

    private var preferredColorScheme: ColorScheme? {
        [nil, .light, .dark][appearance]
    }

    init() {
        UserDefaults.standard.register(defaults: ["soundEnabled": true])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(storeManager)
                .preferredColorScheme(preferredColorScheme)
                .task {
                    await authManager.restoreSession()
                    await storeManager.start()
                }
        }
        .modelContainer(for: [CachedPokemon.self, CachedGame.self, UserPokemon.self])
    }
}
