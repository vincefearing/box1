import SwiftData

@Model
class UserPokemon {
    var pokemonId: Int
    var form: String
    var isCaught: Bool
    var isShinyCaught: Bool
    var isOriginCaught: Bool

    init(pokemonId: Int, form: String, isCaught: Bool = false, isShinyCaught: Bool = false, isOriginCaught: Bool = false) {
        self.pokemonId = pokemonId
        self.form = form
        self.isCaught = isCaught
        self.isShinyCaught = isShinyCaught
        self.isOriginCaught = isOriginCaught
    }
}