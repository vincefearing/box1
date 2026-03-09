import SwiftUI

struct PokemonCard: View {
    let pokemon: CachedPokemon
    var isCaught: Bool = false
    var displayDexNumber: Int?

    var body: some View {
        VStack(spacing: 4) {
            Group {
                let localPath = SpriteService.localPath(dexNumber: pokemon.dexNumber, form: "default")
                if let uiImage = UIImage(contentsOfFile: localPath.path) {
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

            Text(String(format: "#%03d", displayDexNumber ?? pokemon.dexNumber))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(pokemon.name.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCaught ? typeColor.opacity(0.15) : Color(.systemGray6))
        )
        .animation(.easeInOut(duration: 0.3), value: isCaught)
    }

    private var typeColor: Color {
        guard let hex = pokemon.types.first?.color else { return .gray }
        return Color(hex: hex)
    }
}

struct PokemonCardWithMenu: View {
    let pokemon: CachedPokemon
    let isCaught: Bool
    let onToggle: () -> Void

    var body: some View {
        PokemonCard(pokemon: pokemon, isCaught: isCaught)
            .contextMenu {
                Button(action: onToggle) {
                    Label(
                        isCaught ? "Remove from Collection" : "Mark as Caught",
                        systemImage: isCaught ? "xmark.circle" : "checkmark.circle"
                    )
                }
            }
    }
}
