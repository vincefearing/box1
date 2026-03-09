import SwiftUI
import SwiftData
import AVFoundation

struct PokemonDetailView: View {
    let pokemon: CachedPokemon
    let form: String

    @Environment(\.modelContext) private var modelContext
    @Query private var userPokemon: [UserPokemon]
    @Query(sort: \CachedGame.id) private var games: [CachedGame]
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false
    @AppStorage("selectedGameGroup") private var selectedGameGroup: String = ""
    @State private var audioPlayer: AVPlayer?

    private var entry: UserPokemon? {
        userPokemon.first { $0.pokemonId == pokemon.dexNumber && $0.form == form }
    }

    private var isCaught: Bool { entry?.isCaught ?? false }
    private var isShiny: Bool { entry?.isShinyCaught ?? false }
    private var isOrigin: Bool { entry?.isOriginCaught ?? false }

    private var gameNameById: [Int: String] {
        Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0.name) })
    }

    private var selectedGameIds: Set<Int>? {
        guard !selectedGameGroup.isEmpty else { return nil }
        return Set(games.filter { $0.gameGroup == selectedGameGroup }.map(\.id))
    }

    private var filteredLocations: [Pokemon.PokemonLocation] {
        guard let gameIds = selectedGameIds else { return pokemon.locations }
        return pokemon.locations.filter { gameIds.contains($0.gameId) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                spriteSection
                typeSection
                nicknameSection
                statsSection
                if let description = pokemon.pokemonDescription, !description.isEmpty {
                    descriptionSection(description)
                }
                crySection
                actionSection
                notesSection
                locationSection
            }
            .padding()
        }
        .navigationTitle(pokemon.name.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sprite

    private var spriteUrl: String? {
        let sprite = pokemon.sprites.first { $0.form == form }
        if isShiny { return sprite?.shinyUrl ?? sprite?.normalUrl }
        return sprite?.normalUrl
    }

    private var spriteSection: some View {
        SpriteImage(dexNumber: pokemon.dexNumber, form: form, shiny: isShiny, remoteUrl: spriteUrl)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            if isShiny {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                    .padding(8)
            }
        }
    }

    // MARK: - Types

    private var typeSection: some View {
        HStack(spacing: 8) {
            Text(String(format: "#%03d", pokemon.dexNumber))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(pokemon.types, id: \.name) { type in
                Text(type.name.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: type.color), in: Capsule())
            }
        }
    }

    // MARK: - Nickname

    private var nicknameSection: some View {
        TextField("Add a nickname...", text: Binding(
            get: { entry?.nickname ?? "" },
            set: { newValue in
                if let existing = entry {
                    existing.nickname = newValue
                } else {
                    let newEntry = UserPokemon(pokemonId: pokemon.dexNumber, form: form)
                    newEntry.nickname = newValue
                    modelContext.insert(newEntry)
                }
            }
        ))
        .font(.title3)
        .fontWeight(.medium)
        .multilineTextAlignment(.center)
        .foregroundStyle(.primary)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 24) {
            VStack {
                Text("Height")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f m", pokemon.height))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            VStack {
                Text("Weight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f kg", pokemon.weight))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            VStack {
                Text("Generation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(pokemon.generation)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            VStack {
                Text("Region")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(pokemon.originRegion.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        Text(text.replacingOccurrences(of: "POKéMON", with: "Pokémon")
                .replacingOccurrences(of: "POKEMON", with: "Pokémon")
                .replacingOccurrences(of: "POKeMON", with: "Pokémon"))
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Cry

    private var crySection: some View {
        Button {
            playCry()
        } label: {
            Label("Play Cry", systemImage: "speaker.wave.2.fill")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemGray6), in: Capsule())
    }

    // MARK: - Actions

    private var actionSection: some View {
        HStack(spacing: 16) {
            Button { toggleCaught() } label: {
                VStack(spacing: 4) {
                    Image(systemName: isCaught ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title2)
                    Text("Caught")
                        .font(.caption2)
                }
            }
            .tint(isCaught ? .green : .secondary)

            if trackShiny {
                Button { toggleShiny() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                        Text("Shiny")
                            .font(.caption2)
                    }
                }
                .tint(isShiny ? .yellow : .secondary)
            }

            if trackOrigin {
                Button { toggleOrigin() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: isOrigin ? "globe.americas.fill" : "globe.americas")
                            .font(.title2)
                        Text("Origin")
                            .font(.caption2)
                    }
                }
                .tint(isOrigin ? typeColor : .secondary)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Add notes...", text: Binding(
                get: { entry?.notes ?? "" },
                set: { newValue in
                    if let existing = entry {
                        existing.notes = newValue
                    } else {
                        let newEntry = UserPokemon(pokemonId: pokemon.dexNumber, form: form)
                        newEntry.notes = newValue
                        modelContext.insert(newEntry)
                    }
                }
            ), axis: .vertical)
            .lineLimit(3...6)
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Locations

    private var locationSection: some View {
        DisclosureGroup("Locations") {
            if filteredLocations.isEmpty {
                Text("No location data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredLocations.enumerated()), id: \.element.gameId) { index, location in
                        HStack(alignment: .top) {
                            Text(gameNameById[location.gameId] ?? "Unknown")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 100, alignment: .leading)
                            Text(location.locationInfo)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                        if index < filteredLocations.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var typeColor: Color {
        guard let hex = pokemon.types.first?.color else { return .gray }
        return Color(hex: hex)
    }

    private func playCry() {
        guard let url = URL(string: pokemon.cryUrl) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }

    private func toggleCaught() {
        if let existing = entry {
            existing.isCaught.toggle()
        } else {
            let newEntry = UserPokemon(pokemonId: pokemon.dexNumber, form: form, isCaught: true)
            modelContext.insert(newEntry)
        }
    }

    private func toggleShiny() {
        if let existing = entry {
            existing.isShinyCaught.toggle()
            if existing.isShinyCaught { existing.isCaught = true }
        } else {
            let newEntry = UserPokemon(pokemonId: pokemon.dexNumber, form: form, isCaught: true, isShinyCaught: true)
            modelContext.insert(newEntry)
        }
    }

    private func toggleOrigin() {
        if let existing = entry {
            existing.isOriginCaught.toggle()
            if existing.isOriginCaught { existing.isCaught = true }
        } else {
            let newEntry = UserPokemon(pokemonId: pokemon.dexNumber, form: form, isCaught: true, isOriginCaught: true)
            modelContext.insert(newEntry)
        }
    }
}
