import SwiftUI
import AVFoundation

/// The bridge between UIKit's AV hardware layer and SwiftUI.
/// Strictly designed to pass the isolated session down without enforcing any state observation.
public struct CameraPreviewLayer: UIViewRepresentable {
    public let session: AVCaptureSession
    
    public init(session: AVCaptureSession) {
        self.session = session
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            // Ensure hardware layer strictly conforms to bounds asynchronously to avoid layout deadlocks
            DispatchQueue.main.async {
                layer.frame = uiView.bounds
            }
        }
    }
}
