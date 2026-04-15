import Foundation

/// Absolute spacing and radius scales guaranteeing mathematical consistency across the entire UI.
public enum DesignTokens {
    public enum Spacing {
        public static let xxxs: CGFloat = 4
        public static let xxs: CGFloat  = 8
        public static let xs: CGFloat   = 12
        public static let sm: CGFloat   = 16
        public static let md: CGFloat   = 24
        public static let lg: CGFloat   = 32
        public static let xl: CGFloat   = 40
        public static let xxl: CGFloat  = 64
        public static let xxxl: CGFloat = 120
    }
    
    public enum Radius {
        public static let xxs: CGFloat  = 2
        public static let xs: CGFloat   = 4
        public static let sm: CGFloat   = 8
        public static let md: CGFloat   = 16
        public static let lg: CGFloat   = 24
        public static let xl: CGFloat   = 32
        public static let full: CGFloat = 9999
    }
}
