import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable {
    case numberAsc = "# Ascending"
    case numberDesc = "# Descending"
    case nameAsc = "Name A–Z"
    case nameDesc = "Name Z–A"
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
    @State private var selectedDexNumbers = Set<Int>()
    @State private var showScrollToTop = false
    @State private var selectedTypes = Set<String>()
    @State private var selectedGeneration: Int?
    @State private var showMissingOnly = false
    @State private var showFilterSheet = false
    @State private var sortOption: SortOption = .numberAsc

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
                            selectedDexNumbers.removeAll()
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
                        Text("\(selectedDexNumbers.count) selected")
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
                                selectedDexNumbers.removeAll()
                            } label: {
                                Label("Remove", systemImage: "xmark.circle")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.bar, in: Capsule())
                            .disabled(selectedDexNumbers.isEmpty)
                        } else {
                            Button {
                                markSelectedAsCaught()
                                isSelectMode = false
                                selectedDexNumbers.removeAll()
                            } label: {
                                Label("Catch", systemImage: "checkmark.circle")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.bar, in: Capsule())
                            .disabled(selectedDexNumbers.isEmpty)
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
            ForEach(filteredPokemon, id: \.dexNumber) { mon in
                cardView(for: mon)
            }
        }
        .id(selectedGroup)
    }

    @ViewBuilder
    private func cardView(for mon: CachedPokemon) -> some View {
        let caught = caughtDexNumbers.contains(mon.dexNumber)
        let regNumber = regionalNumber(for: mon)
        if isSelectMode {
            PokemonCard(pokemon: mon, isCaught: caught, displayDexNumber: regNumber)
                .overlay(alignment: .topLeading) {
                    Image(systemName: selectedDexNumbers.contains(mon.dexNumber) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedDexNumbers.contains(mon.dexNumber) ? Color.accentColor : .secondary)
                        .font(.title3)
                        .padding(6)
                }
                .onTapGesture {
                    if selectedDexNumbers.contains(mon.dexNumber) {
                        selectedDexNumbers.remove(mon.dexNumber)
                    } else {
                        selectedDexNumbers.insert(mon.dexNumber)
                    }
                }
        } else {
            PokemonCard(pokemon: mon, isCaught: caught, displayDexNumber: regNumber)
                .onLongPressGesture {
                    toggleCaught(dexNumber: mon.dexNumber)
                }
        }
    }

    private var allSelectedAreCaught: Bool {
        !selectedDexNumbers.isEmpty && selectedDexNumbers.allSatisfy { caughtDexNumbers.contains($0) }
    }

    private func markSelectedAsUncaught() {
        for dexNumber in selectedDexNumbers {
            if let existing = userPokemon.first(where: { $0.pokemonId == dexNumber && $0.form == "default" }) {
                existing.isCaught = false
            }
        }
    }

    private func markSelectedAsCaught() {
        for dexNumber in selectedDexNumbers {
            if let existing = userPokemon.first(where: { $0.pokemonId == dexNumber && $0.form == "default" }) {
                existing.isCaught = true
            } else {
                let entry = UserPokemon(pokemonId: dexNumber, form: "default", isCaught: true)
                modelContext.insert(entry)
            }
        }
    }

    private func toggleCaught(dexNumber: Int) {
        if let existing = userPokemon.first(where: { $0.pokemonId == dexNumber && $0.form == "default" }) {
            existing.isCaught.toggle()
        } else {
            let entry = UserPokemon(pokemonId: dexNumber, form: "default", isCaught: true)
            modelContext.insert(entry)
        }
    }
}
#Preview {
    PokemonGridView()
}
