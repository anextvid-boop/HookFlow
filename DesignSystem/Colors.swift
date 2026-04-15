import SwiftUI

/// Centralized semantic color palette for the 1000x Glassmorphic engine.
public extension Color {
    // Pure spatial base
    static let hfBackground = Color(red: 0.05, green: 0.05, blue: 0.05) 
    
    // Translucent layers mapped for `.ultraThinMaterial` environments
    static let hfSurface = Color.white.opacity(0.05) 
    static let hfSurfaceHighlight = Color.white.opacity(0.1)
    
    // Core brand signals
    static let hfAccent = Color(red: 1.0, green: 0.15, blue: 0.3) // Premium neon/red tone
    static let hfSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    // Global typographic scales
    static let hfTextPrimary = Color.white
    static let hfTextSecondary = Color.white.opacity(0.6)
    static let hfTextTertiary = Color.white.opacity(0.3)
}
