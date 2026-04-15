import Foundation
import AVFoundation
import Observation

/// The heavily optimized playback engine driving the Editor timeline.
/// It wraps AVQueuePlayer and AVPlayerLooper seamlessly avoiding manual boundary calculations.
@Observable
@MainActor
public final class VideoPlayerService {
    public let player: AVQueuePlayer
    private var playerLooper: AVPlayerLooper?
    private var currentPlayerItem: AVPlayerItem?
    
    private var timeObserverToken: Any?
    
    public var isPlaying: Bool = false
    
    public init() {
        self.player = AVQueuePlayer()
    }
    
    public func load(videoURL: URL, loop: Bool = false) {
        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        self.currentPlayerItem = item
        
        if loop {
            self.playerLooper = AVPlayerLooper(player: player, templateItem: item)
        } else {
            self.playerLooper = nil
            self.player.replaceCurrentItem(with: item)
        }
    }
    
    public func play() {
        player.play()
        isPlaying = true
    }
    
    public func pause() {
        player.pause()
        isPlaying = false
    }
    
    /// Strict timeline scrubbing decoupled from Main Thread rendering stutter
    public func seek(to time: CMTime) async {
        await player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // Phase 8.2 Clock Thread Observer
    public func addPeriodicTimeObserver(interval: CMTime, block: @escaping @MainActor (CMTime) -> Void) {
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            Task { @MainActor in
                block(time)
            }
        }
    }
    
    public func removeTimeObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    // Phase 8.4 Application Layer Termination Map
    public func clearPlayer() {
        player.pause()
        isPlaying = false
        removeTimeObserver()
        player.replaceCurrentItem(with: nil)
    }
}
