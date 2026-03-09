import SwiftData

@Model
class CachedGame {
    @Attribute(.unique) var id: Int
    var name: String
    var generation: Int
    var region: String
    var gameGroup: String

    init(from game: Game) {
        self.id = game.id
        self.name = game.name
        self.generation = game.generation
        self.region = game.region
        self.gameGroup = game.gameGroup
    }
}
