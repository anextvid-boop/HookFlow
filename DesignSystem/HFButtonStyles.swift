import SwiftUI

/// Standard scale effect animation for tactile high-fidelity tap feedback. 
/// Mimics the native Apple/TikTok interaction behavior.
public struct HFScaleButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == HFScaleButtonStyle {
    static var hfScale: HFScaleButtonStyle {
        HFScaleButtonStyle()
    }
}
