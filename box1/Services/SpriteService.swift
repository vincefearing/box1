import Foundation

class SpriteService {
    private static var spritesDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sprites", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func localPath(dexNumber: Int, form: String) -> URL {
        spritesDirectory.appendingPathComponent("\(dexNumber)_\(form).png")
    }

    static func spriteExists(dexNumber: Int, form: String) -> Bool {
        FileManager.default.fileExists(atPath: localPath(dexNumber: dexNumber, form: form).path)
    }

    func downloadAllSprites(from pokemonList: [CachedPokemon]) async {
        let total = pokemonList.count
        var downloaded = 0

        await withTaskGroup(of: Void.self) { group in
            let maxConcurrent = 20

            for pokemon in pokemonList {
                guard let sprite = pokemon.sprites.first(where: { $0.form == "default" }),
                      !SpriteService.spriteExists(dexNumber: pokemon.dexNumber, form: "default"),
                      let url = URL(string: sprite.normalUrl) else {
                    downloaded += 1
                    continue
                }

                let dexNumber = pokemon.dexNumber
                group.addTask {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        try data.write(to: SpriteService.localPath(dexNumber: dexNumber, form: "default"))
                    } catch {
                        print("Failed to download sprite for #\(dexNumber): \(error)")
                    }
                }

                downloaded += 1
                if downloaded % maxConcurrent == 0 {
                    await group.next()
                    print("Downloaded \(downloaded)/\(total) sprites")
                }
            }
        }
        print("Sprite download complete")
    }
}
