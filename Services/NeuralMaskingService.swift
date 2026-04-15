import Foundation
import CoreImage
import Vision
import CoreMedia

/// Prevents the extreme compute of ML-based Neural Masking from dropping the Main Thread below 120 FPS.
@globalActor
public actor MaskingActor {
    public static let shared = MaskingActor()
}

/// A hardware-accelerated service specifically leveraging the Apple Neural Engine to cut the human 
/// subject out of the background in real-time. This powers the "Ghost UI" where teleprompter text 
/// floats natively behind the user's head during recording.
@MaskingActor
public final class NeuralMaskingService: ObservableObject {
    private let segmentationRequest = VNGeneratePersonSegmentationRequest()
    private let context = CIContext(options: [.useSoftwareRenderer: false]) // Force GPU Acceleration
    
    public init() {
        // Balances edge-detection (hair) against real-time FPS constraints
        segmentationRequest.qualityLevel = .balanced
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    }
    
    /// Accepts a raw 4K stream buffer and a dynamic `CIImage` background.
    /// Perfectly stitches the subject over the background natively in memory.
    public func applyNeuralMask(to pixelBuffer: CVPixelBuffer, customBackground background: CIImage) -> CIImage? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([segmentationRequest])
            guard let result = segmentationRequest.results?.first as? VNPixelBufferObservation else { return nil }
            
            let maskPixelBuffer = result.pixelBuffer
            let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            
            let rawImage = CIImage(cvPixelBuffer: pixelBuffer)
            
            // Scale the low-res CoreML mask explicitly back to the 4K boundaries
            let scaleX = rawImage.extent.width / maskImage.extent.width
            let scaleY = rawImage.extent.height / maskImage.extent.height
            let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            // CoreImage exact hardware blending pipeline
            guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
            
            blendFilter.setValue(rawImage, forKey: kCIInputImageKey) // The Subject (Foreground)
            blendFilter.setValue(background, forKey: kCIInputBackgroundImageKey) // The Teleprompter (Background)
            blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey) // The ML segmentation matte
            
            return blendFilter.outputImage
        } catch {
            print("Neural Engine Segmentation failed or dropped frame: \\(error)")
            return nil
        }
    }
}
