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

    private static let megaGameGroups: Set<String> = [
        "X & Y", "Omega Ruby & Alpha Sapphire",
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee", "Legends: Z-A"
    ]

    private static let gmaxGameGroups: Set<String> = [
        "Sword & Shield"
    ]

    private static let preGenderDiffGroups: Set<String> = [
        "Red & Blue", "Yellow",
        "Gold & Silver", "Crystal",
        "Ruby & Sapphire", "Emerald", "FireRed & LeafGreen"
    ]

    private static let alolanGameGroups: Set<String> = [
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee",
        "Sword & Shield",
        "Brilliant Diamond & Shining Pearl",
        "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let galarianGameGroups: Set<String> = [
        "Sword & Shield"
    ]

    private static let hisuianGameGroups: Set<String> = [
        "Legends: Arceus", "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let paldeanGameGroups: Set<String> = [
        "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let gen7PlusGameGroups: Set<String> = [
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee",
        "Sword & Shield",
        "Brilliant Diamond & Shining Pearl",
        "Legends: Arceus",
        "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let gen4PlusGameGroups: Set<String> = [
        "Diamond & Pearl", "Platinum",
        "HeartGold & SoulSilver",
        "Black & White", "Black 2 & White 2",
        "X & Y", "Omega Ruby & Alpha Sapphire",
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee",
        "Sword & Shield",
        "Brilliant Diamond & Shining Pearl",
        "Legends: Arceus",
        "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let gen3PlusGameGroups: Set<String> = [
        "Ruby & Sapphire", "Emerald", "FireRed & LeafGreen",
        "Diamond & Pearl", "Platinum",
        "HeartGold & SoulSilver",
        "Black & White", "Black 2 & White 2",
        "X & Y", "Omega Ruby & Alpha Sapphire",
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee",
        "Sword & Shield",
        "Brilliant Diamond & Shining Pearl",
        "Legends: Arceus",
        "Scarlet & Violet", "Legends: Z-A"
    ]

    private static let gen2PlusGameGroups: Set<String> = [
        "Gold & Silver", "Crystal",
        "Ruby & Sapphire", "Emerald", "FireRed & LeafGreen",
        "Diamond & Pearl", "Platinum",
        "HeartGold & SoulSilver",
        "Black & White", "Black 2 & White 2",
        "X & Y", "Omega Ruby & Alpha Sapphire",
        "Sun & Moon", "Ultra Sun & Ultra Moon",
        "Let's Go Pikachu & Eevee",
        "Sword & Shield",
        "Brilliant Diamond & Shining Pearl",
        "Legends: Arceus",
        "Scarlet & Violet", "Legends: Z-A"
    ]

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
