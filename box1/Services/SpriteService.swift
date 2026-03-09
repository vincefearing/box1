import Foundation

class SpriteService {
    private static var spritesDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sprites", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func localPath(dexNumber: Int, form: String, shiny: Bool = false) -> URL {
        let filename = shiny ? "\(dexNumber)_\(form)_shiny.png" : "\(dexNumber)_\(form).png"
        return spritesDirectory.appendingPathComponent(filename)
    }

    static func spriteExists(dexNumber: Int, form: String, shiny: Bool = false) -> Bool {
        FileManager.default.fileExists(atPath: localPath(dexNumber: dexNumber, form: form, shiny: shiny).path)
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

    func downloadFormSprites(from pokemonList: [CachedPokemon]) async {
        var count = 0
        await withTaskGroup(of: Void.self) { group in
            for pokemon in pokemonList {
                for sprite in pokemon.sprites where sprite.form != "default" {
                    guard !SpriteService.spriteExists(dexNumber: pokemon.dexNumber, form: sprite.form),
                          let url = URL(string: sprite.normalUrl) else { continue }

                    let dexNumber = pokemon.dexNumber
                    let form = sprite.form
                    group.addTask {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            try data.write(to: SpriteService.localPath(dexNumber: dexNumber, form: form))
                        } catch {
                            print("Failed to download sprite for #\(dexNumber) \(form): \(error)")
                        }
                    }

                    count += 1
                    if count % 20 == 0 {
                        await group.next()
                        print("Downloaded \(count) form sprites")
                    }
                }
            }
        }
        print("Form sprite download complete (\(count) sprites)")
    }

    func downloadShinySprites(from pokemonList: [CachedPokemon]) async {
        var count = 0
        await withTaskGroup(of: Void.self) { group in
            for pokemon in pokemonList {
                for sprite in pokemon.sprites {
                    guard let shinyUrlString = sprite.shinyUrl,
                          !SpriteService.spriteExists(dexNumber: pokemon.dexNumber, form: sprite.form, shiny: true),
                          let url = URL(string: shinyUrlString) else { continue }

                    let dexNumber = pokemon.dexNumber
                    let form = sprite.form
                    group.addTask {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            try data.write(to: SpriteService.localPath(dexNumber: dexNumber, form: form, shiny: true))
                        } catch {
                            print("Failed to download shiny sprite for #\(dexNumber) \(form): \(error)")
                        }
                    }

                    count += 1
                    if count % 20 == 0 {
                        await group.next()
                        print("Downloaded \(count) shiny sprites")
                    }
                }
            }
        }
        print("Shiny sprite download complete (\(count) sprites)")
    }
}
