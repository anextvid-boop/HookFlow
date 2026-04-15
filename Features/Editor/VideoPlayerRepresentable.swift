import SwiftUI
import AVFoundation

/// Isolated bridge ensuring SwiftUI re-renders NEVER touch the active AVQueuePlayer directly.
/// This single-handedly fixes the lag/stutter associated with standard VideoPlayer wrappers.
public struct VideoPlayerRepresentable: UIViewRepresentable {
    public let player: AVQueuePlayer
    
    public init(player: AVQueuePlayer) {
        self.player = player
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.masksToBounds = true
        view.layer.addSublayer(playerLayer)
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            DispatchQueue.main.async {
                // Ensure player object is exactly synced
                if layer.player !== player {
                    layer.player = player
                }
                layer.frame = uiView.bounds
            }
        }
    }
}
