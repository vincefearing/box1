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
            SpriteImage(dexNumber: pokemon.dexNumber, form: form, shiny: isShiny, remoteUrl: pokemon.spriteUrl(form: form, shiny: isShiny))
                .saturation(isCaught ? 1 : 0)
                .opacity(isCaught ? 1 : 0.5)
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
                if let category = FormCategory.categorize(form) {
                    Image("FormIcons/\(category.iconName)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(isCaught ? category.iconColor : Color(.systemGray4), in: Circle())
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
                .fill(isCaught ? pokemon.primaryTypeColor.opacity(0.15) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isOrigin ? pokemon.primaryTypeColor.opacity(0.6) : .clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isCaught)
    }
}
