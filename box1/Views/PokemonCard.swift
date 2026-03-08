import SwiftUI

struct PokemonCard: View {
    let pokemon: CachedPokemon

    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: pokemon.sprites.first?.normalUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(typeColor.opacity(0.2))
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
