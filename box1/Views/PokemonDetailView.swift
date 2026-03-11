import SwiftUI
import SwiftData
import AVFoundation

struct PokemonDetailView: View {
    let pokemon: CachedPokemon
    let form: String

    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @Query private var userPokemon: [UserPokemon]
    @Query(sort: \CachedGame.id) private var games: [CachedGame]
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false
    @AppStorage("selectedGameGroup") private var selectedGameGroup: String = ""
    @AppStorage("dismissUncatchWarning") private var dismissUncatchWarning = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @State private var audioPlayer: AVPlayer?
    @State private var showUncatchAlert = false
    @State private var pendingUncatchAction: (() -> Void)?
    @FocusState private var focusedField: Field?
    @State private var catchFeedbackTrigger = false

    private enum Field { case nickname, notes }

    private var isPremium: Bool { storeManager.isPurchased }

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
                Text(pokemon.displayName(form: form))
                    .font(.title2)
                    .bold()
                typeSection
                if isCaught {
                    nicknameSection
                }
                statsSection
                if let description = pokemon.pokemonDescription, !description.isEmpty {
                    descriptionSection(description)
                }
                if soundEnabled {
                    crySection
                }
                actionSection
                if isCaught {
                    notesSection
                }
                locationSection
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove from Collection?", isPresented: $showUncatchAlert) {
            Button("Cancel", role: .cancel) { pendingUncatchAction = nil }
            Button("Remove", role: .destructive) {
                pendingUncatchAction?()
                pendingUncatchAction = nil
            }
            Button("Remove & Don't Warn Again", role: .destructive) {
                dismissUncatchWarning = true
                pendingUncatchAction?()
                pendingUncatchAction = nil
            }
        } message: {
            Text("The nickname and notes for this Pokemon will be deleted.")
        }
        .sensoryFeedback(.success, trigger: catchFeedbackTrigger)
    }

    // MARK: - Sprite

    private var spriteSection: some View {
        SpriteImage(dexNumber: pokemon.dexNumber, form: form, shiny: isShiny, remoteUrl: pokemon.spriteUrl(form: form, shiny: isShiny))
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
        Group {
            if isCaught && isPremium {
                TextField("Add a nickname...", text: Binding(
                    get: { entry?.nickname ?? "" },
                    set: { newValue in
                        entry?.nickname = newValue
                    }
                ))
                .focused($focusedField, equals: .nickname)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 6) {
                    if !isPremium {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(entry?.nickname.isEmpty == false ? entry!.nickname : "Add a nickname...")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 24) {
            VStack {
                Text("Height")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(pokemon.height, format: .number.precision(.fractionLength(1))) m")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            VStack {
                Text("Weight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(pokemon.weight, format: .number.precision(.fractionLength(1))) kg")
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
        Text(text.replacing("POKéMON", with: "Pokémon")
                .replacing("POKEMON", with: "Pokémon")
                .replacing("POKeMON", with: "Pokémon"))
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
                        .font(.caption)
                }
            }
            .tint(isCaught ? .green : .secondary)

            if isPremium && trackShiny {
                Button { toggleShiny() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                        Text("Shiny")
                            .font(.caption)
                    }
                }
                .tint(isShiny ? .yellow : .secondary)
            }

            if isPremium && trackOrigin {
                Button { toggleOrigin() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: isOrigin ? "globe.americas.fill" : "globe.americas")
                            .font(.title2)
                        Text("Origin")
                            .font(.caption)
                    }
                }
                .tint(isOrigin ? pokemon.primaryTypeColor : .secondary)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            if isCaught && isPremium {
                TextField("Add notes...", text: Binding(
                    get: { entry?.notes ?? "" },
                    set: { newValue in
                        entry?.notes = newValue
                    }
                ), axis: .vertical)
                .focused($focusedField, equals: .notes)
                .lineLimit(3...6)
                .font(.subheadline)
            } else {
                Text(entry?.notes.isEmpty == false ? entry!.notes : "Add notes...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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
                    ForEach(filteredLocations.enumerated(), id: \.element.gameId) { index, location in
                        HStack(alignment: .top) {
                            Text(gameNameById[location.gameId] ?? "Unknown")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 100, alignment: .leading)
                            Text(location.locationInfo ?? "Unknown")
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

    // MARK: - Actions

    private func playCry() {
        guard let url = URL(string: pokemon.cryUrl) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
    }

    private func toggleCaught() {
        let result = PokemonTracking.toggleCaught(
            entry: entry, dexNumber: pokemon.dexNumber, form: form, context: modelContext
        )
        if case .needsUncatch(let hasData, let action) = result {
            if hasData && !dismissUncatchWarning {
                pendingUncatchAction = action
                showUncatchAlert = true
            } else {
                action()
            }
        } else {
            catchFeedbackTrigger.toggle()
        }
    }

    private func toggleShiny() {
        PokemonTracking.toggleTracking(
            \.isShinyCaught, entry: entry,
            dexNumber: pokemon.dexNumber, form: form, context: modelContext
        )
    }

    private func toggleOrigin() {
        PokemonTracking.toggleTracking(
            \.isOriginCaught, entry: entry,
            dexNumber: pokemon.dexNumber, form: form, context: modelContext
        )
    }
}
