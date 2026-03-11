import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(StoreManager.self) private var storeManager
    @Query(sort: \CachedPokemon.dexNumber) private var pokemon: [CachedPokemon]
    @Query private var userPokemon: [UserPokemon]
    @AppStorage("showMegas") private var showMegas = false
    @AppStorage("showFemales") private var showFemales = false
    @AppStorage("showGigantamax") private var showGigantamax = false
    @AppStorage("showOtherForms") private var showOtherForms = false
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false

    private var isPremium: Bool { storeManager.isPurchased }

    private var emptyStats: StatTotals {
        StatTotals(baseCaught: 0, baseTotal: pokemon.count)
    }

    private var activeFormCategories: [FormCategory] {
        var categories: [FormCategory] = []
        if showMegas { categories.append(.mega) }
        if showGigantamax { categories.append(.gigantamax) }
        if showFemales { categories.append(.female) }
        if showOtherForms { categories.append(.other) }
        return categories
    }

    private var allStats: (caught: StatTotals, shiny: StatTotals, origin: StatTotals) {
        computeAllStats()
    }

    var body: some View {
        let stats = allStats
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatSection(
                        title: "Caught", icon: "checkmark.circle.fill", color: .green,
                        stats: stats.caught, formCategories: activeFormCategories
                    )

                    StatSection(
                        title: "Shiny", icon: "sparkles", color: .yellow,
                        stats: trackShiny ? stats.shiny : emptyStats,
                        formCategories: activeFormCategories,
                        enabled: trackShiny,
                        lockedMessage: isPremium ? nil : "Premium"
                    )

                    StatSection(
                        title: "Origin", icon: "globe.americas.fill", color: .blue,
                        stats: trackOrigin ? stats.origin : emptyStats,
                        formCategories: activeFormCategories,
                        enabled: trackOrigin,
                        lockedMessage: isPremium ? nil : "Premium"
                    )
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Single-Pass Stat Computation

    private func computeAllStats() -> (caught: StatTotals, shiny: StatTotals, origin: StatTotals) {
        let caughtByKey = Dictionary(grouping: userPokemon.filter(\.isCaught)) { "\($0.pokemonId)_\($0.form)" }
        let shinyByKey = Dictionary(grouping: userPokemon.filter(\.isShinyCaught)) { "\($0.pokemonId)_\($0.form)" }
        let originByKey = Dictionary(grouping: userPokemon.filter(\.isOriginCaught)) { "\($0.pokemonId)_\($0.form)" }

        let baseTotal = pokemon.count
        var caughtBase = 0, shinyBase = 0, originBase = 0
        var caughtForms: [FormCategory: (caught: Int, total: Int)] = [:]
        var shinyForms: [FormCategory: (caught: Int, total: Int)] = [:]
        var originForms: [FormCategory: (caught: Int, total: Int)] = [:]

        for p in pokemon {
            let defaultKey = "\(p.dexNumber)_default"
            if caughtByKey[defaultKey] != nil { caughtBase += 1 }
            if shinyByKey[defaultKey] != nil { shinyBase += 1 }
            if originByKey[defaultKey] != nil { originBase += 1 }

            for sprite in p.sprites {
                guard let category = FormCategory.categorize(sprite.form) else { continue }
                let shouldCount: Bool
                switch category {
                case .mega: shouldCount = showMegas
                case .gigantamax: shouldCount = showGigantamax
                case .female: shouldCount = showFemales
                case .other: shouldCount = showOtherForms
                }
                guard shouldCount else { continue }

                let key = "\(p.dexNumber)_\(sprite.form)"
                let isCaught = caughtByKey[key] != nil
                let isShiny = shinyByKey[key] != nil
                let isOrigin = originByKey[key] != nil

                caughtForms[category, default: (0, 0)].total += 1
                if isCaught { caughtForms[category, default: (0, 0)].caught += 1 }
                shinyForms[category, default: (0, 0)].total += 1
                if isShiny { shinyForms[category, default: (0, 0)].caught += 1 }
                originForms[category, default: (0, 0)].total += 1
                if isOrigin { originForms[category, default: (0, 0)].caught += 1 }
            }
        }

        return (
            caught: StatTotals(baseCaught: caughtBase, baseTotal: baseTotal, formStats: caughtForms),
            shiny: StatTotals(baseCaught: shinyBase, baseTotal: baseTotal, formStats: shinyForms),
            origin: StatTotals(baseCaught: originBase, baseTotal: baseTotal, formStats: originForms)
        )
    }
}

// MARK: - Data

private struct StatTotals {
    var baseCaught: Int
    var baseTotal: Int
    var formStats: [FormCategory: (caught: Int, total: Int)] = [:]

    var totalCaught: Int { baseCaught + formStats.values.reduce(0) { $0 + $1.caught } }
    var totalAll: Int { baseTotal + formStats.values.reduce(0) { $0 + $1.total } }
}

// MARK: - Section

private struct StatSection: View {
    let title: String
    let icon: String
    let color: Color
    let stats: StatTotals
    let formCategories: [FormCategory]
    var enabled: Bool = true
    var lockedMessage: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(enabled ? color : .secondary)
                Text(title)
                    .font(.headline)
                Spacer()
                if let lockedMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text(lockedMessage)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else if !enabled {
                    Text("Enable in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            StatRow(label: "Pokemon", count: stats.baseCaught, total: stats.baseTotal, color: color)

            ForEach(formCategories, id: \.label) { category in
                if let stat = stats.formStats[category], stat.total > 0 {
                    StatRow(label: category.label, count: stat.caught, total: stat.total, color: color, isSubrow: true)
                }
            }

            Divider()

            StatRow(label: "Total", count: stats.totalCaught, total: stats.totalAll, color: color, isTotal: true)
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .opacity(enabled ? 1 : 0.4)
    }
}

// MARK: - Row

private struct StatRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    var isTotal: Bool = false
    var isSubrow: Bool = false

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .fontWeight(isTotal ? .semibold : .regular)
                    .font(isSubrow ? .caption : .subheadline)
                Spacer()
                Text("\(count)/\(total)")
                    .fontWeight(.medium)
                Text(percentage, format: .percent.precision(.fractionLength(0)))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            .font(isSubrow ? .caption : .subheadline)
            .padding(.leading, isSubrow ? 16 : 0)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: isSubrow ? 6 : 8)
            .padding(.leading, isSubrow ? 16 : 0)
        }
    }
}

#Preview {
    StatsView()
}
