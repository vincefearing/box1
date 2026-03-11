import Foundation

class SpriteService {
    private static let spritesDirectory: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sprites", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func localPath(dexNumber: Int, form: String, shiny: Bool = false) -> URL {
        let filename = shiny ? "\(dexNumber)_\(form)_shiny.png" : "\(dexNumber)_\(form).png"
        return spritesDirectory.appendingPathComponent(filename)
    }

    static func spriteExists(dexNumber: Int, form: String, shiny: Bool = false) -> Bool {
        FileManager.default.fileExists(atPath: localPath(dexNumber: dexNumber, form: form, shiny: shiny).path)
    }

    func downloadAllSprites(from pokemonList: [CachedPokemon]) async {
        let items = pokemonList.compactMap { pokemon -> SpriteDownload? in
            guard let sprite = pokemon.sprites.first(where: { $0.form == "default" }),
                  !SpriteService.spriteExists(dexNumber: pokemon.dexNumber, form: "default"),
                  let url = URL(string: sprite.normalUrl) else { return nil }
            return SpriteDownload(dexNumber: pokemon.dexNumber, form: "default", url: url, shiny: false)
        }
        await downloadSprites(items)
        print("Sprite download complete (\(items.count) sprites)")
    }

    func downloadFormSprites(from pokemonList: [CachedPokemon]) async {
        var items: [SpriteDownload] = []
        for pokemon in pokemonList {
            for sprite in pokemon.sprites where sprite.form != "default" {
                guard !SpriteService.spriteExists(dexNumber: pokemon.dexNumber, form: sprite.form),
                      let url = URL(string: sprite.normalUrl) else { continue }
                items.append(SpriteDownload(dexNumber: pokemon.dexNumber, form: sprite.form, url: url, shiny: false))
            }
        }
        await downloadSprites(items)
        print("Form sprite download complete (\(items.count) sprites)")
    }

    func downloadShinySprites(from pokemonList: [CachedPokemon]) async {
        var items: [SpriteDownload] = []
        for pokemon in pokemonList {
            for sprite in pokemon.sprites {
                guard let shinyUrlString = sprite.shinyUrl,
                      !SpriteService.spriteExists(dexNumber: pokemon.dexNumber, form: sprite.form, shiny: true),
                      let url = URL(string: shinyUrlString) else { continue }
                items.append(SpriteDownload(dexNumber: pokemon.dexNumber, form: sprite.form, url: url, shiny: true))
            }
        }
        await downloadSprites(items)
        print("Shiny sprite download complete (\(items.count) sprites)")
    }

    // MARK: - Private

    private struct SpriteDownload {
        let dexNumber: Int
        let form: String
        let url: URL
        let shiny: Bool
    }

    private func downloadSprites(_ items: [SpriteDownload]) async {
        var enqueued = 0
        await withTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: item.url)
                        try data.write(to: SpriteService.localPath(dexNumber: item.dexNumber, form: item.form, shiny: item.shiny))
                    } catch {
                        print("Failed to download sprite #\(item.dexNumber) \(item.form): \(error)")
                    }
                }
                enqueued += 1
                if enqueued % 20 == 0 {
                    await group.next()
                }
            }
        }
    }
}
