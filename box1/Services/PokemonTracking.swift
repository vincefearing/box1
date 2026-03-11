import SwiftData

enum CatchResult {
    case caught
    case needsUncatch(hasData: Bool, action: () -> Void)
}

enum PokemonTracking {

    static func toggleCaught(
        entry: UserPokemon?,
        dexNumber: Int,
        form: String,
        context: ModelContext
    ) -> CatchResult {
        if let existing = entry, existing.isCaught {
            let hasData = !existing.nickname.isEmpty || !existing.notes.isEmpty
            return .needsUncatch(hasData: hasData) {
                uncatch(entry: existing)
            }
        } else if let existing = entry {
            existing.isCaught = true
            SoundService.shared.playCatchFeedback()
            return .caught
        } else {
            let newEntry = UserPokemon(pokemonId: dexNumber, form: form, isCaught: true)
            context.insert(newEntry)
            SoundService.shared.playCatchFeedback()
            return .caught
        }
    }

    static func toggleTracking(
        _ keyPath: ReferenceWritableKeyPath<UserPokemon, Bool>,
        entry: UserPokemon?,
        dexNumber: Int,
        form: String,
        context: ModelContext
    ) {
        if let existing = entry {
            let wasCaught = existing.isCaught
            existing[keyPath: keyPath].toggle()
            if existing[keyPath: keyPath] && !wasCaught {
                existing.isCaught = true
                SoundService.shared.playCatchFeedback()
            }
        } else {
            let newEntry = UserPokemon(pokemonId: dexNumber, form: form, isCaught: true)
            newEntry[keyPath: keyPath] = true
            context.insert(newEntry)
            SoundService.shared.playCatchFeedback()
        }
    }

    static func uncatch(entry: UserPokemon) {
        entry.isCaught = false
        entry.nickname = ""
        entry.notes = ""
        SoundService.shared.playUncatch()
    }
}
