import SwiftUI

struct ProfileView: View {
    @AppStorage("showMegas") private var showMegas = false
    @AppStorage("showFemales") private var showFemales = false
    @AppStorage("showGigantamax") private var showGigantamax = false
    @AppStorage("showOtherForms") private var showOtherForms = false
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pokedex") {
                    Toggle("Mega Evolutions", isOn: $showMegas)
                    Toggle("Female Variants", isOn: $showFemales)
                    Toggle("Gigantamax", isOn: $showGigantamax)
                    Toggle("Other Forms", isOn: $showOtherForms)
                }

                Section("Tracking") {
                    Toggle("Shiny", isOn: $trackShiny)
                    Toggle("Origin Game", isOn: $trackOrigin)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
