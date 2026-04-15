import SwiftUI
import SwiftData

/// The dynamic TextEditor layer explicitly designed to build CustomTemplates with fluid keyboard-bound bracket injections natively.
struct TemplateComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var templateTitle: String = ""
    @State private var bodyPattern: String = ""
    
    // Generates a soft haptic bump actively triggered when pressed
    let interactFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.hfBackground.ignoresSafeArea()
                
                VStack(spacing: DesignTokens.Spacing.md) {
                    
                    TextField("Name your template...", text: $templateTitle)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Material.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.top, DesignTokens.Spacing.md)
                    
                    TextEditor(text: $bodyPattern)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden) 
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, DesignTokens.Spacing.md)
                    
                    // MARK: - Variable Injection Toolbar
                    buildVariableToolbar()
                }
            }
            .navigationTitle("Custom Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTemplate() }
                        .font(.system(.body, weight: .bold))
                        .foregroundStyle(templateTitle.isEmpty || bodyPattern.isEmpty ? Color.gray : Color.hfAccent)
                        .disabled(templateTitle.isEmpty || bodyPattern.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Sub-component Logic
    
    @ViewBuilder
    private func buildVariableToolbar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                variablePill("[BUSINESS_NAME]")
                variablePill("[INDUSTRY_NICHE]")
                variablePill("[TARGET_AUDIENCE]")
                variablePill("[PAIN_POINT]")
                variablePill("[CORE_OFFER]")
                variablePill("[BRAND_TONE]")
                variablePill("[PRIMARY_CTA]")
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(Material.ultraThinMaterial)
    }
    
    @ViewBuilder
    private func variablePill(_ tag: String) -> some View {
        Button(action: {
            interactFeedback.selectionChanged()
            injectVariable(tag)
        }) {
            Text(tag)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.hfAccent.opacity(0.2))
                .foregroundStyle(Color.hfAccent)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.hfAccent, lineWidth: 1))
        }
        .buttonStyle(HFScaleButtonStyle())
    }
    
    // MARK: - Logic Hooks
    
    private func injectVariable(_ tag: String) {
        // Appends to the current text cursor implicitly. 
        // For absolute precision, this could hook directly into underlying UITextView cursors,
        // but physically appending acts as a reliable fast-fallback natively.
        if !bodyPattern.isEmpty && !bodyPattern.hasSuffix(" ") && !bodyPattern.hasSuffix("\n") {
            bodyPattern += " " // Add safe space buffer
        }
        bodyPattern += tag + " "
    }
    
    private func saveTemplate() {
        let custom = CustomTemplate(title: templateTitle, bodyPattern: bodyPattern)
        modelContext.insert(custom)
        dismiss()
    }
}
