import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable {
    case numberAsc = "# Ascending"
    case numberDesc = "# Descending"
    case nameAsc = "Name A–Z"
    case nameDesc = "Name Z–A"
}

enum FormCategory {
    case mega, gigantamax, female, other

    static func categorize(_ form: String) -> FormCategory? {
        let lower = form.lowercased()
        if lower == "default" { return nil }
        if lower == "mega" || lower == "mega-x" || lower == "mega-y" || lower == "primal" { return .mega }
        if lower.contains("gigantamax") || lower == "eternamax" { return .gigantamax }
        if lower == "female" { return .female }
        return .other
    }
}

struct PokemonGridItem: Identifiable {
    let pokemon: CachedPokemon
    let form: String

    var id: String { "\(pokemon.dexNumber)_\(form)" }

    var displayName: String {
        if form == "default" { return pokemon.name.capitalized }
        let formLabel = form.replacingOccurrences(of: "-", with: " ").capitalized
        return "\(formLabel) \(pokemon.name.capitalized)"
    }
}

struct PokemonGridView: View {
    init() {}

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CachedPokemon.dexNumber) private var pokemon: [CachedPokemon]
    @Query(sort: \CachedGame.id) private var games: [CachedGame]
    @Query private var userPokemon: [UserPokemon]
    @State private var searchText = ""
    @State private var selectedGroup: String?
    @State private var isSelectMode = false
    @State private var selectedItems = Set<String>()
    @State private var showScrollToTop = false
    @State private var selectedTypes = Set<String>()
    @State private var selectedGeneration: Int?
    @State private var showMissingOnly = false
    @State private var showFilterSheet = false
    @State private var sortOption: SortOption = .numberAsc
    @AppStorage("showMegas") private var showMegas = false
    @AppStorage("showFemales") private var showFemales = false
    @AppStorage("showGigantamax") private var showGigantamax = false
    @AppStorage("showOtherForms") private var showOtherForms = false
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false

    private func userEntry(for dexNumber: Int, form: String) -> UserPokemon? {
        userPokemon.first { $0.pokemonId == dexNumber && $0.form == form }
    }

    private func isCaught(dexNumber: Int, form: String) -> Bool {
        userEntry(for: dexNumber, form: form)?.isCaught ?? false
    }

    private var caughtDexNumbers: Set<Int> {
        Set(userPokemon.filter(\.isCaught).map(\.pokemonId))
    }

    private var gameGroups: [(name: String, gameIds: [Int])] {
        var seen = Set<String>()
        var groups: [(name: String, gameIds: [Int])] = []
        for game in games {
            if seen.insert(game.gameGroup).inserted {
                let ids = games.filter { $0.gameGroup == game.gameGroup }.map(\.id)
                groups.append((name: game.gameGroup, gameIds: ids))
            }
        }
        return groups
    }

    private var gameIdsByGroup: [String: Set<Int>] {
        var dict: [String: Set<Int>] = [:]
        for group in gameGroups {
            dict[group.name] = Set(group.gameIds)
        }
        return dict
    }

    private var hasActiveFilters: Bool {
        !selectedTypes.isEmpty || selectedGeneration != nil || showMissingOnly
    }

    private var filteredDexNumbers: Set<Int> {
        var result = pokemon

        if let group = selectedGroup, let gameIds = gameIdsByGroup[group] {
            result = result.filter { mon in
                mon.regionalDexNumbers.contains { gameIds.contains($0.gameId) }
            }
        }

        if !selectedTypes.isEmpty {
            result = result.filter { mon in
                mon.types.contains { selectedTypes.contains($0.name.capitalized) }
            }
        }

        if let gen = selectedGeneration {
            result = result.filter { $0.generation == gen }
        }

        if showMissingOnly {
            result = result.filter { !caughtDexNumbers.contains($0.dexNumber) }
        }

        if !searchText.isEmpty {
            result = result.filter { mon in
                mon.name.localizedCaseInsensitiveContains(searchText) ||
                String(mon.dexNumber).contains(searchText)
            }
        }

        return Set(result.map(\.dexNumber))
    }

    private var selectedGameIds: Set<Int>? {
        guard let group = selectedGroup else { return nil }
        return gameIdsByGroup[group]
    }

    private func regionalNumber(for mon: CachedPokemon) -> Int? {
        guard let gameIds = selectedGameIds else { return nil }
        return mon.regionalDexNumbers.first { gameIds.contains($0.gameId) }?.regionalNumber
    }

    private var filteredPokemon: [CachedPokemon] {
        let dexNumbers = filteredDexNumbers
        var result = pokemon.filter { dexNumbers.contains($0.dexNumber) }
        if let gameIds = selectedGameIds {
            result.sort { a, b in
                let aNum = a.regionalDexNumbers.first { gameIds.contains($0.gameId) }?.regionalNumber ?? Int.max
                let bNum = b.regionalDexNumbers.first { gameIds.contains($0.gameId) }?.regionalNumber ?? Int.max
                return aNum < bNum
            }
        } else {
            switch sortOption {
            case .numberAsc:
                break // already sorted by dex number asc from @Query
            case .numberDesc:
                result.reverse()
            case .nameAsc:
                result.sort { $0.name < $1.name }
            case .nameDesc:
                result.sort { $0.name > $1.name }
            }
        }
        return result
    }

    private var gridItems: [PokemonGridItem] {
        filteredPokemon.flatMap { mon -> [PokemonGridItem] in
            var items = [PokemonGridItem(pokemon: mon, form: "default")]
            for sprite in mon.sprites where sprite.form != "default" {
                guard let category = FormCategory.categorize(sprite.form) else { continue }
                switch category {
                case .mega: if showMegas { items.append(PokemonGridItem(pokemon: mon, form: sprite.form)) }
                case .gigantamax: if showGigantamax { items.append(PokemonGridItem(pokemon: mon, form: sprite.form)) }
                case .female: if showFemales { items.append(PokemonGridItem(pokemon: mon, form: sprite.form)) }
                case .other: if showOtherForms { items.append(PokemonGridItem(pokemon: mon, form: sprite.form)) }
                }
            }
            return items
        }
    }

    private var caughtCount: Int {
        filteredDexNumbers.intersection(caughtDexNumbers).count
    }

    private var progressValue: Double {
        guard !filteredDexNumbers.isEmpty else { return 0 }
        return Double(caughtCount) / Double(filteredDexNumbers.count)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    pokemonGrid
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .id("top")
                }
                .onScrollGeometryChange(for: Bool.self) { geo in
                    geo.contentOffset.y > 200
                } action: { _, scrolledDown in
                    showScrollToTop = scrolledDown
                }
                .overlay(alignment: .bottomTrailing) {
                    if showScrollToTop {
                        Button {
                            withAnimation {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.body.weight(.semibold))
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular, in: .circle)
                        }
                        .tint(.primary)
                        .padding(.trailing, 32)
                        .padding(.bottom, 24)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: showScrollToTop)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                filterHeader
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Pokedex")
                        .font(.title.bold())
                        .foregroundStyle(Color.accentColor)
                        .fixedSize()
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                    }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    if isSelectMode {
                        Button("Done") {
                            isSelectMode = false
                            selectedItems.removeAll()
                        }
                    } else {
                        Button("Select") {
                            isSelectMode = true
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isSelectMode {
                    HStack(spacing: 12) {
                        Text("\(selectedItems.count) selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.bar, in: Capsule())

                        Spacer()

                        if allSelectedAreCaught {
                            Button {
                                markSelectedAsUncaught()
                                isSelectMode = false
                                selectedItems.removeAll()
                            } label: {
                                Label("Remove", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.bar, in: Capsule())
                            .disabled(selectedItems.isEmpty)
                        } else {
                            Button {
                                markSelectedAsCaught()
                                isSelectMode = false
                                selectedItems.removeAll()
                            } label: {
                                Label("Catch", systemImage: "checkmark.circle")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.bar, in: Capsule())
                            .disabled(selectedItems.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isSelectMode)
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(
                    selectedTypes: $selectedTypes,
                    selectedGeneration: $selectedGeneration,
                    showMissingOnly: $showMissingOnly
                )
            }
        }
    }

    private var filterHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Game")
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button("National Pokedex") { selectedGroup = nil }
                    ForEach(gameGroups, id: \.name) { group in
                        Button(group.name) { selectedGroup = group.name }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedGroup ?? "National Pokedex")
                            .fontWeight(.medium)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
            }
            .font(.subheadline)

            VStack(spacing: 4) {
                HStack {
                    Text("Caught")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(caughtCount)/\(filteredPokemon.count)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray4))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * progressValue)
                    }
                }
                .frame(height: 8)
            }

        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var pokemonGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(gridItems) { item in
                cardView(for: item)
            }
        }
        .id(selectedGroup)
    }

    @ViewBuilder
    private func cardView(for item: PokemonGridItem) -> some View {
        let entry = userEntry(for: item.pokemon.dexNumber, form: item.form)
        let caught = entry?.isCaught ?? false
        let shiny = entry?.isShinyCaught ?? false
        let origin = entry?.isOriginCaught ?? false
        let regNumber = regionalNumber(for: item.pokemon)
        if isSelectMode {
            PokemonCard(pokemon: item.pokemon, isCaught: caught, isShiny: shiny, isOrigin: origin, displayDexNumber: regNumber, form: item.form)
                .overlay(alignment: .topLeading) {
                    Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedItems.contains(item.id) ? Color.accentColor : .secondary)
                        .font(.title3)
                        .padding(6)
                }
                .onTapGesture {
                    if selectedItems.contains(item.id) {
                        selectedItems.remove(item.id)
                    } else {
                        selectedItems.insert(item.id)
                    }
                }
        } else {
            PokemonCard(pokemon: item.pokemon, isCaught: caught, isShiny: shiny, isOrigin: origin, displayDexNumber: regNumber, form: item.form)
                .contextMenu {
                    Button {
                        toggleCaught(dexNumber: item.pokemon.dexNumber, form: item.form)
                    } label: {
                        Label(
                            caught ? "Remove from Collection" : "Mark as Caught",
                            systemImage: caught ? "xmark.circle" : "checkmark.circle"
                        )
                    }
                    if trackShiny {
                        Button {
                            toggleShiny(dexNumber: item.pokemon.dexNumber, form: item.form)
                        } label: {
                            Label(
                                entry?.isShinyCaught == true ? "Remove Shiny" : "Mark as Shiny",
                                systemImage: entry?.isShinyCaught == true ? "sparkles" : "sparkles"
                            )
                        }
                    }
                    if trackOrigin {
                        Button {
                            toggleOrigin(dexNumber: item.pokemon.dexNumber, form: item.form)
                        } label: {
                            Label(
                                entry?.isOriginCaught == true ? "Remove Origin" : "Mark as Origin",
                                systemImage: entry?.isOriginCaught == true ? "globe.americas.fill" : "globe.americas"
                            )
                        }
                    }
                }
        }
    }

    private var allSelectedAreCaught: Bool {
        !selectedItems.isEmpty && selectedItems.allSatisfy { id in
            let parts = id.split(separator: "_", maxSplits: 1)
            guard let dexNumber = Int(parts[0]) else { return false }
            let form = String(parts[1])
            return isCaught(dexNumber: dexNumber, form: form)
        }
    }

    private func markSelectedAsUncaught() {
        for id in selectedItems {
            let parts = id.split(separator: "_", maxSplits: 1)
            guard let dexNumber = Int(parts[0]) else { continue }
            let form = String(parts[1])
            if let existing = userEntry(for: dexNumber, form: form) {
                existing.isCaught = false
            }
        }
    }

    private func markSelectedAsCaught() {
        for id in selectedItems {
            let parts = id.split(separator: "_", maxSplits: 1)
            guard let dexNumber = Int(parts[0]) else { continue }
            let form = String(parts[1])
            if let existing = userEntry(for: dexNumber, form: form) {
                existing.isCaught = true
            } else {
                let entry = UserPokemon(pokemonId: dexNumber, form: form, isCaught: true)
                modelContext.insert(entry)
            }
        }
    }

    private func toggleCaught(dexNumber: Int, form: String) {
        if let existing = userEntry(for: dexNumber, form: form) {
            existing.isCaught.toggle()
        } else {
            let entry = UserPokemon(pokemonId: dexNumber, form: form, isCaught: true)
            modelContext.insert(entry)
        }
    }

    private func toggleShiny(dexNumber: Int, form: String) {
        if let existing = userEntry(for: dexNumber, form: form) {
            existing.isShinyCaught.toggle()
            if existing.isShinyCaught { existing.isCaught = true }
        } else {
            let entry = UserPokemon(pokemonId: dexNumber, form: form, isCaught: true, isShinyCaught: true)
            modelContext.insert(entry)
        }
    }

    private func toggleOrigin(dexNumber: Int, form: String) {
        if let existing = userEntry(for: dexNumber, form: form) {
            existing.isOriginCaught.toggle()
            if existing.isOriginCaught { existing.isCaught = true }
        } else {
            let entry = UserPokemon(pokemonId: dexNumber, form: form, isCaught: true, isOriginCaught: true)
            modelContext.insert(entry)
        }
    }
}
#Preview {
    PokemonGridView()
}
