import Foundation
import AVFoundation
import CoreImage

/// Executes heavy video merging entirely inside Background Task continuations.
/// Absolutely protects the Main Thread during the 4K Export cycle.
public final class StitchingService: Sendable {
    
    public init() {}
    
    /// Merges an array of video paths natively and returns the single absolute URL inside the temporary directory.
    public func stitchSegments(
        _ segmentsData: [(url: URL, timeRange: CMTimeRange?, speed: Double, bRollURL: URL?, brightness: Double, contrast: Double, saturation: Double, scale: Double, offsetX: Double, offsetY: Double, rotation: Double, outTransition: VideoTransitionType, outTransitionDuration: Double)], 
        targetQuality: RecordingQuality,
        canvasAspectRatio: String = "9:16",
        vibeMusicURL: URL? = nil,
        vibeVolume: Double = 0.1
    ) async throws -> URL {
        return try await Task.detached(priority: .userInitiated) {
            let composition = AVMutableComposition()
            guard let videoTrackA = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let videoTrackB = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let audioTrackA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let audioTrackB = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw NSError(domain: "StitchingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create hardware composition tracks"])
            }
            
            var insertTime = CMTime.zero
            var segmentRenderData: [StitchingCompositionInstruction.SegmentRenderData] = []
            var audioSegmentRanges: [(CMTimeRange, AudioTrackTarget, Double, Double, String)] = []
            
            enum AudioTrackTarget { case a, b }
            var useTrackA = true
            
            for (idx, segment) in segmentsData.enumerated() {
                let asset = AVURLAsset(url: segment.url)
                
                guard let assetVideoTrack = try await asset.loadTracks(withMediaType: .video).first,
                      let assetAudioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                    continue
                }
                
                let duration = try await asset.load(.duration)
                let range = segment.timeRange ?? CMTimeRange(start: .zero, duration: duration)
                
                let actualDuration: CMTime
                if segment.speed != 1.0 {
                    actualDuration = CMTimeMultiplyByFloat64(range.duration, multiplier: 1.0 / segment.speed)
                } else {
                    actualDuration = range.duration
                }
                
                if idx > 0 && segmentsData[idx - 1].outTransition == .crossDissolve {
                    let overlap = CMTime(seconds: segmentsData[idx - 1].outTransitionDuration, preferredTimescale: 600)
                    insertTime = CMTimeSubtract(insertTime, overlap)
                }
                
                let currentVideoTrack = useTrackA ? videoTrackA : videoTrackB
                let currentAudioTrack = useTrackA ? audioTrackA : audioTrackB
                let currentAudioTarget: AudioTrackTarget = useTrackA ? .a : .b
                
                // Audio Insertion
                try currentAudioTrack.insertTimeRange(range, of: assetAudioTrack, at: insertTime)
                if segment.speed != 1.0 {
                    let scaleRange = CMTimeRange(start: insertTime, duration: range.duration)
                    currentAudioTrack.scaleTimeRange(scaleRange, toDuration: actualDuration)
                }
                
                // Video Insertion (Base or B-Roll)
                if let bRollURL = segment.bRollURL {
                   let bRollAsset = AVURLAsset(url: bRollURL)
                   if let bRollVideoTrack = try? await bRollAsset.loadTracks(withMediaType: .video).first {
                        let bRollTotalDuration = try await bRollAsset.load(.duration)
                        var currentBrollTime = insertTime
                        var remainingDuration = range.duration
                        
                        while remainingDuration > .zero {
                            let chunkDuration = CMTimeMinimum(remainingDuration, bRollTotalDuration)
                            try currentVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: chunkDuration), of: bRollVideoTrack, at: currentBrollTime)
                            remainingDuration = CMTimeSubtract(remainingDuration, chunkDuration)
                            currentBrollTime = CMTimeAdd(currentBrollTime, chunkDuration)
                        }
                       
                        if segment.speed != 1.0 {
                            let scaleRange = CMTimeRange(start: insertTime, duration: range.duration)
                            currentVideoTrack.scaleTimeRange(scaleRange, toDuration: actualDuration)
                        }
                   }
                } else {
                    try currentVideoTrack.insertTimeRange(range, of: assetVideoTrack, at: insertTime)
                    if segment.speed != 1.0 {
                        let scaleRange = CMTimeRange(start: insertTime, duration: range.duration)
                        currentVideoTrack.scaleTimeRange(scaleRange, toDuration: actualDuration)
                    }
                }
                
                if insertTime == .zero {
                    if let transform = try? await assetVideoTrack.load(.preferredTransform) {
                        videoTrackA.preferredTransform = transform
                        videoTrackB.preferredTransform = transform
                    }
                }
                
                let mappedRange = CMTimeRange(start: insertTime, duration: actualDuration)
                
                segmentRenderData.append(StitchingCompositionInstruction.SegmentRenderData(
                    timeRange: mappedRange,
                    trackID: currentVideoTrack.trackID,
                    brightness: segment.brightness,
                    contrast: segment.contrast,
                    saturation: segment.saturation,
                    scale: segment.scale,
                    offsetX: segment.offsetX,
                    offsetY: segment.offsetY,
                    rotation: segment.rotation,
                    outTransition: segment.outTransition.rawValue,
                    outTransitionDuration: segment.outTransitionDuration
                ))
                
                audioSegmentRanges.append((mappedRange, currentAudioTarget, segment.outTransitionDuration, 1.0, segment.outTransition.rawValue))
                
                insertTime = CMTimeAdd(insertTime, actualDuration)
                useTrackA.toggle()
            }
            
            // Inject Vibe Music via Hardware Mixing
            var audioMix: AVMutableAudioMix? = nil
            let mix = AVMutableAudioMix()
            var inputParams: [AVMutableAudioMixInputParameters] = []
            
            let paramsA = AVMutableAudioMixInputParameters(track: audioTrackA)
            let paramsB = AVMutableAudioMixInputParameters(track: audioTrackB)
            
            for (range, target, outTransitionDuration, volume, transitionStr) in audioSegmentRanges {
                let params = target == .a ? paramsA : paramsB
                
                if transitionStr == "Cross Dissolve" {
                    let transStart = CMTimeSubtract(CMTimeAdd(range.start, range.duration), CMTime(seconds: outTransitionDuration, preferredTimescale: 600))
                    let transRange = CMTimeRange(start: transStart, duration: CMTime(seconds: outTransitionDuration, preferredTimescale: 600))
                    params.setVolumeRamp(fromStartVolume: Float(volume), toEndVolume: 0.0, timeRange: transRange)
                } else {
                    params.setVolumeRamp(fromStartVolume: Float(volume), toEndVolume: Float(volume), timeRange: range)
                }
            }
            
            inputParams.append(paramsA)
            inputParams.append(paramsB)
            
            if let vibeURL = vibeMusicURL,
               let vibeAsset = AVURLAsset(url: vibeURL) as AVURLAsset?,
               let vibeAssetTrack = try? await vibeAsset.loadTracks(withMediaType: .audio).first,
               let vibeBgTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                
                let vibeDuration = try await vibeAsset.load(.duration)
                var currentVibeTime = CMTime.zero
                
                while currentVibeTime < insertTime {
                    let remaining = CMTimeSubtract(insertTime, currentVibeTime)
                    let chunk = CMTimeMinimum(remaining, vibeDuration)
                    try vibeBgTrack.insertTimeRange(CMTimeRange(start: .zero, duration: chunk), of: vibeAssetTrack, at: currentVibeTime)
                    currentVibeTime = CMTimeAdd(currentVibeTime, chunk)
                }
                
                let vibeParams = AVMutableAudioMixInputParameters(track: vibeBgTrack)
                let clampedVolume = max(0.0, min(1.0, Float(vibeVolume)))
                vibeParams.setVolume(clampedVolume, at: .zero)
                inputParams.append(vibeParams)
            }
            
            mix.inputParameters = inputParams
            audioMix = mix
            
            // Phase 11 & 13 & 15: Compile Global Video Composition Custom Compositor Instruction
            let videoComposition = AVMutableVideoComposition()
            videoComposition.customVideoCompositorClass = StitchingCompositor.self
            
            // Calculate base framerate and frameDuration natively
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // Assuming 30FPS base export
            
            let instruction = StitchingCompositionInstruction(
                timeRange: CMTimeRange(start: .zero, duration: insertTime),
                segments: segmentRenderData,
                trackIDs: [videoTrackA.trackID, videoTrackB.trackID]
            )
            videoComposition.instructions = [instruction]
            
            // Apply Target Render Size logic based on Aspect Ratio selection
            let baseSize = composition.naturalSize
            let maxDim = max(baseSize.width, baseSize.height)
            let minDim = min(baseSize.width, baseSize.height)
            
            if canvasAspectRatio == "1:1" {
                videoComposition.renderSize = CGSize(width: minDim, height: minDim)
            } else if canvasAspectRatio == "16:9" {
                videoComposition.renderSize = CGSize(width: maxDim, height: minDim)
            } else {
                videoComposition.renderSize = CGSize(width: minDim, height: maxDim)
            }
            
            let presetName: String
            switch targetQuality {
            case .hd720p:
                presetName = AVAssetExportPreset1280x720
            case .hd1080p:
                presetName = AVAssetExportPresetHEVC1920x1080
            case .uhd4k:
                presetName = AVAssetExportPresetHEVCHighestQuality
            }
            
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: presetName) else {
                throw NSError(domain: "StitchingService", code: 2, userInfo: [NSLocalizedDescriptionKey: "AVAssetExportSession hardware initialization failed"])
            }
            
            exportSession.videoComposition = videoComposition
            if let audioMix = audioMix {
                exportSession.audioMix = audioMix
            }
            
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_v2_export.mov")
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mov
            exportSession.shouldOptimizeForNetworkUse = true
            
            await exportSession.export()
            
            if let error = exportSession.error {
                throw error
            }
            
            return outputURL
        }.value
    }
}

