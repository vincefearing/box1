import SwiftUI

struct SpriteImage: View {
    let dexNumber: Int
    let form: String
    var shiny: Bool = false
    var remoteUrl: String?

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    private var localPath: URL {
        SpriteService.localPath(dexNumber: dexNumber, form: form, shiny: shiny)
    }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
            } else {
                Color.clear
            }
        }
        .task(id: "\(dexNumber)_\(form)_\(shiny)") {
            await loadSprite()
        }
    }

    private func loadSprite() async {
        // Check local cache first
        if let cached = UIImage(contentsOfFile: localPath.path) {
            uiImage = cached
            return
        }

        guard let remoteUrl, let url = URL(string: remoteUrl) else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: localPath)
            if let downloaded = UIImage(data: data) {
                uiImage = downloaded
            }
        } catch {
            print("Failed to load sprite #\(dexNumber) \(form): \(error)")
        }
    }
}
