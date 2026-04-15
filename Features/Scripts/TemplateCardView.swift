import SwiftUI

/// The premium Glassmorphic cell component presenting a script framework clearly through UI.
struct TemplateCardView: View {
    let template: ScriptTemplate
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    let action: () -> Void
    
    // Generates a soft haptic bump actively triggered when pressed
    let interactFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        Button(action: {
            interactFeedback.selectionChanged()
            action()
        }) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Header Row (Category & Heart)
                HStack(alignment: .top) {
                    HStack(spacing: 4) {
                        Image(systemName: template.category.iconName)
                            .font(.caption2)
                            .foregroundStyle(Color.hfAccent)
                        Text(template.category.rawValue.uppercased())
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.hfAccent)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.hfAccent.opacity(0.15))
                    .cornerRadius(4)
                    
                    Spacer()
                    
                    // Favorite Toggle
                    Button(action: {
                        interactFeedback.selectionChanged()
                        toggleFavorite()
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(isFavorite ? Color.hfAccent : Color.gray.opacity(0.8))
                    }
                }
                
                // Title and Meta
                Text(template.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
                
                // Sub-description
                Text(template.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
            }
            .contentShape(Rectangle())
            .padding(.all, DesignTokens.Spacing.md)
            .background(Material.ultraThinMaterial)
            .background(Color.hfAccent.opacity(0.05)) // Subtle interior brand glow
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        }
        .buttonStyle(HFScaleButtonStyle())
    }
}
