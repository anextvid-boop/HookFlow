import SwiftUI

/// Modally overlaid Engine Focus presenting literal hydrated interpolation seamlessly natively.
struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var profileManager: ProfileManager
    @Environment(AppRouter.self) private var router
    
    let template: ScriptTemplate
    
    var body: some View {
        ZStack {
            // Absolute Dark aesthetics
            Color.hfBackground.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        HStack(spacing: 4) {
                            Image(systemName: template.category.iconName)
                            Text(template.category.rawValue.uppercased())
                                .font(.system(.caption, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(Color.hfAccent)
                        
                        Text(template.title)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // MARK: - Fully Hydrated Content Presentation
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(Color.hfAccent)
                            Text("Auto-Hydrated Script")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .textCase(.uppercase)
                                .foregroundStyle(Color.hfAccent)
                        }
                        
                        Text(template.bodyPattern.hydrate(with: profileManager))
                            .font(.system(.body, design: .rounded))
                            .lineSpacing(6)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Material.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.xl)
            }
            
            // MARK: - Sticky Use Bottom Bar
            VStack {
                Spacer()
                
                Button(action: {
                    useTemplateAndRouteToStudio()
                }) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "video.fill")
                        Text("Use Template in Studio")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.hfAccent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, 30) // Safety padding from bottom
                .shadow(color: Color.hfAccent.opacity(0.4), radius: 15, y: 5)
            }
        }
        // Native interactive modal sizing down effectively
        .presentationDetents([.large, .fraction(0.85)])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Routing Handoff Logic
    
    private func useTemplateAndRouteToStudio() {
        let hydratedText = template.bodyPattern.hydrate(with: profileManager)
        
        // Phase 10: Routing Handshake
        // Instantiate the project dynamically and inject the script instantly into memory bounds
        let newProject = HFProject(title: template.title)
        let newScript = Script(title: template.title, bodyText: hydratedText)
        newProject.script = newScript
        newScript.project = newProject
        
        modelContext.insert(newProject)
        
        dismiss()
        
        // Wait 0.3s for dismiss animation to clear out memory stacks natively, then punch out to Home route
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            router.navigate(to: .studio(projectId: newProject.id.uuidString))
        }
    }
}
