import SwiftUI
import AVKit
import UIKit

// Lecture vidéo MP4 en boucle silencieuse — utilisé dans HomeView et MascotView
struct LoopingVideoView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .black

        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none

        context.coordinator.player = player
        context.coordinator.token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        view.playerLayer = playerLayer
        view.player = player  // PlayerContainerView lance play() après le premier layout
        context.coordinator.playerLayer = playerLayer
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    class Coordinator: NSObject {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var token: Any?
        deinit {
            if let token { NotificationCenter.default.removeObserver(token) }
        }
    }
}

// UIView qui repositionne le AVPlayerLayer et démarre la lecture au premier layout
class PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    private var hasStarted = false

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
        // Démarre la lecture seulement quand le frame est valide (> 0)
        if !hasStarted && bounds.width > 0 {
            hasStarted = true
            player?.play()
        }
    }
}
