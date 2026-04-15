import SwiftUI

/// Fluid typography system. 
/// Built to integrate natively with iOS Dynamic Type while tightly controlling the structural geometry.
public enum HFTypography {
    
    public static func display(size: CGFloat = 48) -> Font {
        .custom("AvenirNext-Heavy", size: size)
    }
    
    public static func title(size: CGFloat = 32) -> Font {
        .custom("AvenirNext-Bold", size: size)
    }
    
    public static func callout(size: CGFloat = 16) -> Font {
        // Crisp, sub-font style for functional UI elements
        .system(size: size, weight: .semibold, design: .default)
    }
    
    public static func body(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    
    public static func caption(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
}
