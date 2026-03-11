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
    private var caughtStats: StatTotals { computeStats(using: \.isCaught) }
    private var shinyStats: StatTotals { computeStats(using: \.isShinyCaught) }
    private var originStats: StatTotals { computeStats(using: \.isOriginCaught) }

    private var activeFormToggles: [FormToggle] {
        var toggles: [FormToggle] = []
        if showMegas { toggles.append(.mega) }
        if showGigantamax { toggles.append(.gigantamax) }
        if showFemales { toggles.append(.female) }
        if showOtherForms { toggles.append(.other) }
        return toggles
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatSection(
                        title: "Caught", icon: "checkmark.circle.fill", color: .green,
                        stats: caughtStats, formToggles: activeFormToggles
                    )

                    StatSection(
                        title: "Shiny", icon: "sparkles", color: .yellow,
                        stats: trackShiny ? shinyStats : emptyStats,
                        formToggles: activeFormToggles,
                        enabled: trackShiny,
                        lockedMessage: isPremium ? nil : "Premium"
                    )

                    StatSection(
                        title: "Origin", icon: "globe.americas.fill", color: .blue,
                        stats: trackOrigin ? originStats : emptyStats,
                        formToggles: activeFormToggles,
                        enabled: trackOrigin,
                        lockedMessage: isPremium ? nil : "Premium"
                    )
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Stat Computation

    private func computeStats(using keyPath: KeyPath<UserPokemon, Bool>) -> StatTotals {
        let trackedEntries = userPokemon.filter { $0[keyPath: keyPath] }

        let baseTotal = pokemon.count
        let baseCaughtIds = Set(trackedEntries.filter { $0.form == "default" }.map(\.pokemonId))
        let baseCaught = baseCaughtIds.count

        var megaCaught = 0, megaTotal = 0
        var gmaxCaught = 0, gmaxTotal = 0
        var femaleCaught = 0, femaleTotal = 0
        var otherCaught = 0, otherTotal = 0

        let trackedByKey = Dictionary(grouping: trackedEntries) { "\($0.pokemonId)_\($0.form)" }

        for p in pokemon {
            for sprite in p.sprites {
                guard let category = FormCategory.categorize(sprite.form) else { continue }
                let isTracked = trackedByKey["\(p.dexNumber)_\(sprite.form)"] != nil

                switch category {
                case .mega:
                    if showMegas { megaTotal += 1; if isTracked { megaCaught += 1 } }
                case .gigantamax:
                    if showGigantamax { gmaxTotal += 1; if isTracked { gmaxCaught += 1 } }
                case .female:
                    if showFemales { femaleTotal += 1; if isTracked { femaleCaught += 1 } }
                case .other:
                    if showOtherForms { otherTotal += 1; if isTracked { otherCaught += 1 } }
                }
            }
        }

        return StatTotals(
            baseCaught: baseCaught, baseTotal: baseTotal,
            megaCaught: megaCaught, megaTotal: megaTotal,
            gmaxCaught: gmaxCaught, gmaxTotal: gmaxTotal,
            femaleCaught: femaleCaught, femaleTotal: femaleTotal,
            otherCaught: otherCaught, otherTotal: otherTotal
        )
    }
}

// MARK: - Data

private enum FormToggle {
    case mega, gigantamax, female, other

    var label: String {
        switch self {
        case .mega: "Mega"
        case .gigantamax: "Gigantamax"
        case .female: "Female"
        case .other: "Other"
        }
    }
}

private struct StatTotals {
    var baseCaught: Int
    var baseTotal: Int
    var megaCaught: Int = 0
    var megaTotal: Int = 0
    var gmaxCaught: Int = 0
    var gmaxTotal: Int = 0
    var femaleCaught: Int = 0
    var femaleTotal: Int = 0
    var otherCaught: Int = 0
    var otherTotal: Int = 0

    var totalCaught: Int { baseCaught + megaCaught + gmaxCaught + femaleCaught + otherCaught }
    var totalAll: Int { baseTotal + megaTotal + gmaxTotal + femaleTotal + otherTotal }

    func caught(for toggle: FormToggle) -> Int {
        switch toggle {
        case .mega: megaCaught
        case .gigantamax: gmaxCaught
        case .female: femaleCaught
        case .other: otherCaught
        }
    }

    func total(for toggle: FormToggle) -> Int {
        switch toggle {
        case .mega: megaTotal
        case .gigantamax: gmaxTotal
        case .female: femaleTotal
        case .other: otherTotal
        }
    }
}

// MARK: - Section

private struct StatSection: View {
    let title: String
    let icon: String
    let color: Color
    let stats: StatTotals
    let formToggles: [FormToggle]
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
                            .font(.caption2)
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

            ForEach(formToggles, id: \.label) { toggle in
                let total = stats.total(for: toggle)
                if total > 0 {
                    StatRow(label: toggle.label, count: stats.caught(for: toggle), total: total, color: color, isSubrow: true)
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
                Text(String(format: "%.0f%%", percentage * 100))
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
