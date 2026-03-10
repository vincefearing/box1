import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \CachedPokemon.dexNumber) private var pokemon: [CachedPokemon]
    @Query private var userPokemon: [UserPokemon]
    @AppStorage("showMegas") private var showMegas = false
    @AppStorage("showFemales") private var showFemales = false
    @AppStorage("showGigantamax") private var showGigantamax = false
    @AppStorage("showOtherForms") private var showOtherForms = false
    @AppStorage("trackShiny") private var trackShiny = false
    @AppStorage("trackOrigin") private var trackOrigin = false

    private var showForms: Bool { showMegas || showGigantamax || showOtherForms }

    private var caughtStats: StatTotals { computeStats(using: \.isCaught) }
    private var shinyStats: StatTotals { computeStats(using: \.isShinyCaught) }
    private var originStats: StatTotals { computeStats(using: \.isOriginCaught) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatSection(title: "Caught", icon: "checkmark.circle.fill", color: .green, stats: caughtStats, showForms: showForms, showFemales: showFemales)

                    if trackShiny {
                        StatSection(title: "Shiny", icon: "sparkles", color: .yellow, stats: shinyStats, showForms: showForms, showFemales: showFemales)
                    }

                    if trackOrigin {
                        StatSection(title: "Origin", icon: "globe.americas.fill", color: .blue, stats: originStats, showForms: showForms, showFemales: showFemales)
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Stat Computation

    private func computeStats(using keyPath: KeyPath<UserPokemon, Bool>) -> StatTotals {
        let trackedEntries = userPokemon.filter { $0[keyPath: keyPath] }

        // Base Pokemon (default forms only)
        let baseTotal = pokemon.count
        let baseCaughtIds = Set(trackedEntries.filter { $0.form == "default" }.map(\.pokemonId))
        let baseCaught = baseCaughtIds.count

        // Forms (non-default, non-female — respecting toggles)
        var formsTotal = 0
        var formsCaught = 0
        var femalesTotal = 0
        var femalesCaught = 0

        let trackedByKey = Dictionary(grouping: trackedEntries) { "\($0.pokemonId)_\($0.form)" }

        for p in pokemon {
            for sprite in p.sprites {
                guard let category = FormCategory.categorize(sprite.form) else { continue }

                let isEnabled: Bool
                switch category {
                case .mega: isEnabled = showMegas
                case .gigantamax: isEnabled = showGigantamax
                case .female: isEnabled = showFemales
                case .other: isEnabled = showOtherForms
                }

                guard isEnabled else { continue }

                if category == .female {
                    femalesTotal += 1
                    if trackedByKey["\(p.dexNumber)_\(sprite.form)"] != nil {
                        femalesCaught += 1
                    }
                } else {
                    formsTotal += 1
                    if trackedByKey["\(p.dexNumber)_\(sprite.form)"] != nil {
                        formsCaught += 1
                    }
                }
            }
        }

        return StatTotals(
            baseCaught: baseCaught, baseTotal: baseTotal,
            formsCaught: formsCaught, formsTotal: formsTotal,
            femalesCaught: femalesCaught, femalesTotal: femalesTotal
        )
    }
}

// MARK: - Data

private struct StatTotals {
    var baseCaught: Int
    var baseTotal: Int
    var formsCaught: Int
    var formsTotal: Int
    var femalesCaught: Int
    var femalesTotal: Int

    var totalCaught: Int { baseCaught + formsCaught + femalesCaught }
    var totalAll: Int { baseTotal + formsTotal + femalesTotal }
}

// MARK: - Section

private struct StatSection: View {
    let title: String
    let icon: String
    let color: Color
    let stats: StatTotals
    let showForms: Bool
    let showFemales: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }

            StatRow(label: "Pokemon", count: stats.baseCaught, total: stats.baseTotal, color: color)

            if showForms && stats.formsTotal > 0 {
                StatRow(label: "Forms", count: stats.formsCaught, total: stats.formsTotal, color: color)
            }

            if showFemales && stats.femalesTotal > 0 {
                StatRow(label: "Females", count: stats.femalesCaught, total: stats.femalesTotal, color: color)
            }

            Divider()

            StatRow(label: "Total", count: stats.totalCaught, total: stats.totalAll, color: color, isTotal: true)
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Row

private struct StatRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    var isTotal: Bool = false

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .fontWeight(isTotal ? .semibold : .regular)
                Spacer()
                Text("\(count)/\(total)")
                    .fontWeight(.medium)
                Text(String(format: "%.0f%%", percentage * 100))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            .font(.subheadline)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    StatsView()
}
