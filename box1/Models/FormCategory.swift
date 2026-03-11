import SwiftUI

enum FormCategory: Hashable {
    case mega, gigantamax, female, other

    var label: String {
        switch self {
        case .mega: "Mega"
        case .gigantamax: "Gigantamax"
        case .female: "Female"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .mega: "mega"
        case .gigantamax: "gmax"
        case .female: "female"
        case .other: "other-form"
        }
    }

    var iconColor: Color {
        switch self {
        case .mega: .purple
        case .gigantamax: .red
        case .female: .pink
        case .other: .orange
        }
    }

    static func categorize(_ form: String) -> FormCategory? {
        let lower = form.lowercased()
        if lower == "default" { return nil }
        if lower == "mega" || lower == "mega-x" || lower == "mega-y" || lower == "primal" { return .mega }
        if lower.contains("gigantamax") || lower == "eternamax" { return .gigantamax }
        if lower == "female" { return .female }
        return .other
    }

    // MARK: - Per-Generation Game Sets

    private static let gen1Games: Set<String> = ["Red & Blue", "Yellow"]
    private static let gen2Games: Set<String> = ["Gold & Silver", "Crystal"]
    private static let gen3Games: Set<String> = ["Ruby & Sapphire", "Emerald", "FireRed & LeafGreen"]
    private static let gen4Games: Set<String> = ["Diamond & Pearl", "Platinum", "HeartGold & SoulSilver"]
    private static let gen5Games: Set<String> = ["Black & White", "Black 2 & White 2"]
    private static let gen6Games: Set<String> = ["X & Y", "Omega Ruby & Alpha Sapphire"]
    private static let gen7Games: Set<String> = ["Sun & Moon", "Ultra Sun & Ultra Moon", "Let's Go Pikachu & Eevee"]
    private static let gen8Games: Set<String> = ["Sword & Shield", "Brilliant Diamond & Shining Pearl", "Legends: Arceus"]
    private static let gen9Games: Set<String> = ["Scarlet & Violet", "Legends: Z-A"]

    // MARK: - Cumulative Game Sets

    private static let gen7PlusGameGroups = gen7Games.union(gen8Games).union(gen9Games)
    private static let gen4PlusGameGroups = gen4Games.union(gen5Games).union(gen6Games).union(gen7PlusGameGroups)
    private static let gen3PlusGameGroups = gen3Games.union(gen4PlusGameGroups)
    private static let gen2PlusGameGroups = gen2Games.union(gen3PlusGameGroups)

    // MARK: - Category-Specific Game Sets

    private static let megaGameGroups: Set<String> = [
        "X & Y", "Omega Ruby & Alpha Sapphire",
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee", "Legends: Z-A"
    ]

    private static let gmaxGameGroups: Set<String> = ["Sword & Shield"]

    private static let preGenderDiffGroups = gen1Games.union(gen2Games).union(gen3Games)

    private static let alolanGameGroups: Set<String> = [
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee",
        "Sword & Shield",
        "Brilliant Diamond & Shining Pearl",
        "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let galarianGameGroups: Set<String> = ["Sword & Shield"]

    private static let hisuianGameGroups: Set<String> = [
        "Legends: Arceus", "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let paldeanGameGroups: Set<String> = ["Scarlet & Violet", "Legends: Z-A"]

    // MARK: - Availability Check

    static func isFormAvailable(_ form: String, forGameGroup group: String) -> Bool {
        if group.isEmpty { return true }

        guard let category = categorize(form) else { return true }

        switch category {
        case .mega: return megaGameGroups.contains(group)
        case .gigantamax: return gmaxGameGroups.contains(group)
        case .female: return !preGenderDiffGroups.contains(group)
        case .other:
            let lower = form.lowercased()

            if lower.hasPrefix("alolan") || lower == "alola-cap" { return alolanGameGroups.contains(group) }
            if lower.hasPrefix("galarian") { return galarianGameGroups.contains(group) }
            if lower.hasPrefix("hisuian") { return hisuianGameGroups.contains(group) }
            if lower.hasPrefix("paldean") { return paldeanGameGroups.contains(group) }

            if lower.contains("-cap") || lower == "ash" || lower == "bloodmoon" { return gen7PlusGameGroups.contains(group) }

            if ["ice-rider", "shadow-rider", "single-strike", "rapid-strike",
                "crowned", "noice", "hangry", "full-belly",
                "gulping", "gorging"].contains(lower) {
                return gen7PlusGameGroups.contains(group)
            }

            if ["fan", "frost", "heat", "mow", "wash",
                "origin", "altered", "sky", "land",
                "incarnate", "therian"].contains(lower) {
                return gen4PlusGameGroups.contains(group)
            }

            if ["attack", "defense", "speed",
                "rainy", "snowy", "sunny",
                "plant", "sandy", "trash"].contains(lower) {
                return gen3PlusGameGroups.contains(group)
            }

            if lower.count <= 2 { return gen2PlusGameGroups.contains(group) }

            return true
        }
    }
}
