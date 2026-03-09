import SwiftUI

struct PokemonCard: View {
    let pokemon: CachedPokemon
    var isCaught: Bool = false
    var isShiny: Bool = false
    var isOrigin: Bool = false
    var displayDexNumber: Int?
    var form: String = "default"

    var body: some View {
        VStack(spacing: 8) {
            Group {
                let localPath = SpriteService.localPath(dexNumber: pokemon.dexNumber, form: form, shiny: isShiny)
                let fallbackPath = SpriteService.localPath(dexNumber: pokemon.dexNumber, form: form)
                if isShiny, let uiImage = UIImage(contentsOfFile: localPath.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .saturation(isCaught ? 1 : 0)
                        .opacity(isCaught ? 1 : 0.5)
                } else if let uiImage = UIImage(contentsOfFile: fallbackPath.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .saturation(isCaught ? 1 : 0)
                        .opacity(isCaught ? 1 : 0.5)
                } else {
                    ProgressView()
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if isShiny {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .padding(4)
                }
            }

            Text(String(format: "#%03d", displayDexNumber ?? pokemon.dexNumber))
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 3) {
                if let iconName = formIconName {
                    Image("FormIcons/\(iconName)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(isCaught ? formIconColor : Color(.systemGray4), in: Circle())
                }
                Text(pokemon.name.capitalized)
                    .fontWeight(.medium)
            }
            .font(.caption)
            .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCaught ? typeColor.opacity(0.15) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isOrigin ? typeColor.opacity(0.6) : .clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isCaught)
    }

    private var formIconName: String? {
        guard let category = FormCategory.categorize(form) else { return nil }
        switch category {
        case .mega: return "mega"
        case .gigantamax: return "gmax"
        case .female: return "female"
        case .other: return "other-form"
        }
    }

    private var formIconColor: Color {
        guard let category = FormCategory.categorize(form) else { return .clear }
        switch category {
        case .mega: return .purple
        case .gigantamax: return .red
        case .female: return .pink
        case .other: return .orange
        }
    }

    private var typeColor: Color {
        guard let hex = pokemon.types.first?.color else { return .gray }
        return Color(hex: hex)
    }
}
