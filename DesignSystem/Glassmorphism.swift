import SwiftUI

/// Standardized Glassmorphic Overlay ensuring standard blur application across the entire app.
/// This single modifier guarantees we don't have 14 different implementations of blur in the UI.
public struct HFGlassmorphismModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark) // Force dark mode materials for absolute spatial UI consistency
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // Elegant structural border for the 1000x premium feel
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

public extension View {
    /// Applies the universal Glassmorphism treatment to physically float an element above the V2 interface
    func hfGlassmorphic(
        padding: CGFloat = DesignTokens.Spacing.sm, 
        cornerRadius: CGFloat = DesignTokens.Radius.md
    ) -> some View {
        self.modifier(HFGlassmorphismModifier(padding: padding, cornerRadius: cornerRadius))
    }
}
