import AVFoundation

final class SoundService {
    static let shared = SoundService()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        prepareSound("chime_bell_confirm")
        prepareSound("chime_done")
        prepareSound("music_pipe_ramp_up")
        prepareSound("slide_drop")
    }

    private func prepareSound(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf")
                ?? Bundle.main.url(forResource: name, withExtension: "wav")
                ?? Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[name] = player
        } catch {}
    }

    func play(_ name: String) {
        guard let player = players[name] else { return }
        player.currentTime = 0
        player.play()
    }
}
