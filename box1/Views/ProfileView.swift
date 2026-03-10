import SwiftUI

struct ProfileView: View {
    @AppStorage("showMegas") private var showMegas = false
    @AppStorage("showFemales") private var showFemales = false
    @AppStorage("showGigantamax") private var showGigantamax = false
    @AppStorage("showOtherForms") private var showOtherForms = false
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false
    @AppStorage("dismissUncatchWarning") private var dismissUncatchWarning = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pokedex") {
                    Toggle("Forms", isOn: $showOtherForms)
                    Toggle("Female Variants", isOn: $showFemales)
                    Toggle("Mega Evolutions", isOn: $showMegas)
                    Toggle("Gigantamax", isOn: $showGigantamax)
                }

                Section("Tracking") {
                    Toggle("Shiny", isOn: $trackShiny)
                    Toggle("Origin Game", isOn: $trackOrigin)
                }

                Section("Warnings") {
                    Toggle("Suppress Uncatch Warning", isOn: $dismissUncatchWarning)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
