import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @Query private var userPokemon: [UserPokemon]
    @AppStorage("showMegas") private var showMegas = false
    @AppStorage("showFemales") private var showFemales = false
    @AppStorage("showGigantamax") private var showGigantamax = false
    @AppStorage("showOtherForms") private var showOtherForms = false
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false
    @AppStorage("dismissUncatchWarning") private var dismissUncatchWarning = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("appearance") private var appearance = 0
    @State private var showUpgrade = false
    @State private var showResetConfirmation = false

    private var isPremium: Bool { storeManager.isPurchased }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.displayName.isEmpty ? "Trainer" : authManager.displayName)
                            .font(.headline)
                        if isPremium {
                            Text("Premium")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.tint, in: Capsule())
                        } else {
                            Text("Free")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }

            Section("Appearance") {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section("Audio") {
                Toggle("Sound Effects", isOn: $soundEnabled)
            }

            Section("Pokedex") {
                premiumToggle("Forms", isOn: $showOtherForms)
                premiumToggle("Female Variants", isOn: $showFemales)
                premiumToggle("Mega Evolutions", isOn: $showMegas)
                premiumToggle("Gigantamax", isOn: $showGigantamax)
            }

            Section("Tracking") {
                premiumToggle("Shiny", isOn: $trackShiny)
                premiumToggle("Origin Game", isOn: $trackOrigin)
            }

            Section("Warnings") {
                Toggle("Suppress Uncatch Warning", isOn: $dismissUncatchWarning)
            }

            if !isPremium {
                Section {
                    Button {
                        showUpgrade = true
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Upgrade to Premium")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await storeManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Button("Reset Pokedex", role: .destructive) {
                    showResetConfirmation = true
                }
                .confirmationDialog("Reset Pokedex?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                    Button("Reset All Data", role: .destructive, action: resetPokedex)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will delete all caught Pokemon, nicknames, notes, and tracking data. This cannot be undone.")
                }

                Button("Sign Out", role: .destructive) {
                    Task { try? await authManager.signOut() }
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showUpgrade) {
            PremiumUpgradeView()
        }
    }

    private func resetPokedex() {
        for entry in userPokemon {
            modelContext.delete(entry)
        }
    }

    @ViewBuilder
    private func premiumToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        if isPremium {
            Toggle(title, isOn: isOn)
        } else {
            Button {
                showUpgrade = true
            } label: {
                HStack {
                    Text(title)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
