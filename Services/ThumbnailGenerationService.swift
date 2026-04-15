import Foundation
import CoreImage
import AVFoundation

/// Isolated actor to generate UI thumbnails purely in the background to prevent Editor timeline lag.
/// By delegating heavy CGImage decoding away from the Main Thread, timeline scrubbing remains 120 FPS.
public actor ThumbnailGenerationService {
    public static let shared = ThumbnailGenerationService()
    
    private init() {}
    
    /// Utilizing AVAssetImageGenerator to asynchronously pull frames 
    public func generateThumbnail(for videoURL: URL, at time: CMTime = .zero) async throws -> CGImage {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        // Optimize generator for exact, immediate UI loading
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        let (cgImage, _) = try await imageGenerator.image(at: time)
        return cgImage
    }
}
