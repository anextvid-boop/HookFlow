import Foundation
import CoreImage
import AVFoundation

public class StitchingCompositor: NSObject, AVVideoCompositing, @unchecked Sendable {
    
    private let renderContextQueue = DispatchQueue(label: "com.hookflow.compositor")
    private var renderContext: AVVideoCompositionRenderContext?
    private let ciContext = CIContext()
    
    public var sourcePixelBufferAttributes: [String : Any & Sendable]? {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
        ]
    }
    
    public var requiredPixelBufferAttributesForRenderContext: [String : Any & Sendable] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
        ]
    }
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync {
            self.renderContext = newRenderContext
        }
    }
    
    public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        autoreleasepool {
            guard let instruction = request.videoCompositionInstruction as? StitchingCompositionInstruction else {
                request.finish(with: NSError(domain: "StitchingCompositor", code: 0, userInfo: nil))
                return
            }
            
            let compTime = request.compositionTime
            let renderSize = request.renderContext.size
            var finalBackground = CIImage(color: CIColor.black).cropped(to: CGRect(origin: .zero, size: renderSize))
            
            // 1. Identify which segments are active exactly at this composition time
            let activeSegments = instruction.segments.filter { $0.timeRange.containsTime(compTime) }.sorted { $0.timeRange.start < $1.timeRange.start }
            
            // Handle Dip to White logic
            var dipOpacity: Double = 0.0
            
            for (index, segmentData) in activeSegments.enumerated() {
                guard let pixelBuffer = request.sourceFrame(byTrackID: segmentData.trackID) else { continue }
                var image = CIImage(cvPixelBuffer: pixelBuffer)
                
                // --- Color Grading ---
                if !(segmentData.brightness == 0.0 && segmentData.contrast == 1.0 && segmentData.saturation == 1.0) {
                    if let filter = CIFilter(name: "CIColorControls") {
                        filter.setValue(image, forKey: kCIInputImageKey)
                        filter.setValue(segmentData.brightness, forKey: kCIInputBrightnessKey)
                        filter.setValue(segmentData.contrast, forKey: kCIInputContrastKey)
                        filter.setValue(segmentData.saturation, forKey: kCIInputSaturationKey)
                        if let output = filter.outputImage {
                            image = output
                        }
                    }
                }
                
                // --- Transform Logic (Scale, Rotation, Offset) ---
                let imageSize = image.extent.size
                let baseScale = min(renderSize.width / imageSize.width, renderSize.height / imageSize.height)
                let scaledImage = image.transformed(by: CGAffineTransform(scaleX: baseScale, y: baseScale))
                
                let baseDx = (renderSize.width - scaledImage.extent.width) / 2.0 - scaledImage.extent.origin.x
                let baseDy = (renderSize.height - scaledImage.extent.height) / 2.0 - scaledImage.extent.origin.y
                
                var transform = CGAffineTransform(translationX: baseDx, y: baseDy)
                let renderCenter = CGPoint(x: renderSize.width / 2.0, y: renderSize.height / 2.0)
                
                transform = transform
                    .translatedBy(x: renderCenter.x, y: renderCenter.y)
                    .rotated(by: segmentData.rotation)
                    .scaledBy(x: segmentData.scale, y: segmentData.scale)
                    .translatedBy(x: segmentData.offsetX, y: segmentData.offsetY)
                    .translatedBy(x: -renderCenter.x, y: -renderCenter.y)
                
                image = scaledImage.transformed(by: transform)
                
                // --- Transitions & Overlaps ---
                var opacity: Double = 1.0
                
                // Evaluate Outward Transition for this segment
                let endTime = CMTimeAdd(segmentData.timeRange.start, segmentData.timeRange.duration)
                let transitionStart = CMTimeSubtract(endTime, CMTime(seconds: segmentData.outTransitionDuration, preferredTimescale: 600))
                
                if compTime >= transitionStart && compTime <= endTime {
                    let progress = CMTimeGetSeconds(CMTimeSubtract(compTime, transitionStart)) / segmentData.outTransitionDuration
                    
                    if segmentData.outTransition == "Fade to Black" {
                        opacity = max(0, 1.0 - progress)
                    } else if segmentData.outTransition == "Dip to White" {
                        dipOpacity = max(dipOpacity, progress)
                    } else if segmentData.outTransition == "Cross Dissolve" {
                        opacity = max(0, 1.0 - progress)
                    }
                }
                
                // Evaluate Inward Transition (if the PREVIOUS segment had a transition that affects us)
                // If we are index 1 (meaning an outgoing segment is index 0 overlapping us)
                if index > 0 {
                    let overlappingOutgoingSegment = activeSegments[index - 1]
                    if overlappingOutgoingSegment.outTransition == "Cross Dissolve" {
                        let overlapStart = overlappingOutgoingSegment.timeRange.start
                        let overlapEnd = CMTimeAdd(overlapStart, overlappingOutgoingSegment.timeRange.duration)
                        let tStart = CMTimeSubtract(overlapEnd, CMTime(seconds: overlappingOutgoingSegment.outTransitionDuration, preferredTimescale: 600))
                        
                        if compTime >= tStart && compTime <= overlapEnd {
                            let progress = CMTimeGetSeconds(CMTimeSubtract(compTime, tStart)) / overlappingOutgoingSegment.outTransitionDuration
                            opacity = min(1.0, progress) // Cross dissolve fade IN
                        }
                    } else if overlappingOutgoingSegment.outTransition == "Dip to White" {
                        // Dip to white goes from 0 to 1 during the outgoing clip.
                        // For the incoming clip, it should go from 1 to 0 (white fade out)
                        let overlapStart = overlappingOutgoingSegment.timeRange.start
                        let overlapEnd = CMTimeAdd(overlapStart, overlappingOutgoingSegment.timeRange.duration)
                        let tStart = CMTimeSubtract(overlapEnd, CMTime(seconds: overlappingOutgoingSegment.outTransitionDuration, preferredTimescale: 600))
                        
                        if compTime >= tStart && compTime <= overlapEnd {
                            let progress = CMTimeGetSeconds(CMTimeSubtract(compTime, tStart)) / overlappingOutgoingSegment.outTransitionDuration
                            dipOpacity = max(dipOpacity, 1.0 - progress) // Fade out of white
                        }
                    }
                }
                
                if opacity < 1.0 {
                    if let matrixFilter = CIFilter(name: "CIColorMatrix") {
                        matrixFilter.setValue(image, forKey: kCIInputImageKey)
                        matrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: opacity), forKey: "inputAVector")
                        if let output = matrixFilter.outputImage {
                            finalBackground = output.composited(over: finalBackground)
                        }
                    }
                } else {
                    finalBackground = image.composited(over: finalBackground)
                }
            }
            
            // Dip to White Overlay execution
            if dipOpacity > 0.0 {
                let whiteImage = CIImage(color: CIColor.white).cropped(to: CGRect(origin: .zero, size: renderSize))
                if let filter = CIFilter(name: "CIColorMatrix") {
                    filter.setValue(whiteImage, forKey: kCIInputImageKey)
                    filter.setValue(CIVector(x: 0, y: 0, z: 0, w: dipOpacity), forKey: "inputAVector")
                    if let overlay = filter.outputImage {
                        finalBackground = overlay.composited(over: finalBackground)
                    }
                }
            }
            
            // Provide Buffer
            var newPixelBuffer: CVPixelBuffer? = nil
            renderContextQueue.sync {
                if let renderContext = self.renderContext {
                    newPixelBuffer = renderContext.newPixelBuffer()
                }
            }
            
            guard let pixelBuffer = newPixelBuffer else {
                request.finish(with: NSError(domain: "StitchingCompositor", code: 1, userInfo: nil))
                return
            }
            
            ciContext.render(finalBackground, to: pixelBuffer)
            request.finish(withComposedVideoFrame: pixelBuffer)
        }
    }
}

public class StitchingCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol, @unchecked Sendable {
    public var timeRange: CMTimeRange
    public var enablePostProcessing: Bool = true
    public var containsTweening: Bool = true
    public var requiredSourceTrackIDs: [NSValue]? = nil
    public var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    public struct SegmentRenderData {
        public let timeRange: CMTimeRange
        public let trackID: CMPersistentTrackID
        
        public let brightness: Double
        public let contrast: Double
        public let saturation: Double
        public let scale: Double
        public let offsetX: Double
        public let offsetY: Double
        public let rotation: Double
        public let outTransition: String
        public let outTransitionDuration: Double
        
        public init(timeRange: CMTimeRange, trackID: CMPersistentTrackID, brightness: Double, contrast: Double, saturation: Double, scale: Double, offsetX: Double, offsetY: Double, rotation: Double, outTransition: String, outTransitionDuration: Double) {
            self.timeRange = timeRange
            self.trackID = trackID
            self.brightness = brightness
            self.contrast = contrast
            self.saturation = saturation
            self.scale = scale
            self.offsetX = offsetX
            self.offsetY = offsetY
            self.rotation = rotation
            self.outTransition = outTransition
            self.outTransitionDuration = outTransitionDuration
        }
    }
    
    public var segments: [SegmentRenderData] = []
    
    public init(timeRange: CMTimeRange, segments: [SegmentRenderData], trackIDs: [CMPersistentTrackID]) {
        self.timeRange = timeRange
        self.segments = segments
        self.requiredSourceTrackIDs = trackIDs.map { NSNumber(value: $0) as NSValue }
        super.init()
    }
}
