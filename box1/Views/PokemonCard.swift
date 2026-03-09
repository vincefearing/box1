import SwiftUI

struct PokemonCard: View {
    let pokemon: CachedPokemon
    var isCaught: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: pokemon.sprites.first(where: { $0.form == "default" })?.normalUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .saturation(isCaught ? 1 : 0)
                    .opacity(isCaught ? 1 : 0.5)
            } placeholder: {
                ProgressView()
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCaught ? typeColor.opacity(0.2) : Color.gray.opacity(0.1))
            )

            Text(String(format: "#%03d", pokemon.dexNumber))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(pokemon.name.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }

    private var typeColor: Color {
        guard let hex = pokemon.types.first?.color else { return .gray }
        return Color(hex: hex)
    }
}
