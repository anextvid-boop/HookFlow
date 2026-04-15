import SwiftUI
import SwiftData

/// The isolated Script Builder.
/// Structurally designed as a bottom-up `.sheet` that persists over the Studio camera feed.
/// Features a massive layout padded for distraction-free typing while capturing the ultraThinMaterial visual context.
public struct TeleprompterScriptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let projectId: String
    
    // MEMORY SAFE: Keystrokes bind exclusively to this local copy.
    @State private var localText: String = ""
    @FocusState private var textInputFocused: Bool
    
    public init(projectId: String) {
        self.projectId = projectId
    }
    
    public var body: some View {
        ZStack {
            // Glassmorphic background enabling the user to squint and see their camera under the sheet
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Darker overlay to ensure text contrast remains legible regardless of camera feed
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar with drag handle and explicit dismiss
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 5)
                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .accessibilityIdentifier("dismiss_script_editor_button")
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.top, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xs)
                
                // Native Instructional Text Editor backing replacing simple TextEditor
                // Allows dynamic NSAttributedString mappings internally
                ZStack(alignment: .topLeading) {
                    if localText.isEmpty {
                        Text("Start typing your script here...\n\nUse [brackets] to add instructions that won't be read aloud.")
                            .font(HFTypography.title(size: 32))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.horizontal, DesignTokens.Spacing.xs)
                            .padding(.top, DesignTokens.Spacing.xs)
                            .allowsHitTesting(false) // Let touches pass through
                    }
                    
                    InstructionalTextEditor(text: $localText)
                        .focused($textInputFocused)
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                // Character count UI marker
                Text("\(localText.count) characters")
                    .font(HFTypography.caption())
                    .foregroundColor(.hfTextSecondary)
                    .padding(.trailing, DesignTokens.Spacing.md)
                    
                Button("Done") {
                    textInputFocused = false
                }
                .font(HFTypography.caption())
                .fontWeight(.bold)
                .foregroundColor(.hfAccent)
                .accessibilityIdentifier("done_script_editor_button")
            }
        }
        .onAppear {
            loadScript()
            // Auto focus script editor instantaneously
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textInputFocused = true
            }
        }
        .onDisappear {
            commitChanges()
        }
    }
    
    private func loadScript() {
        let projectIdUUID = UUID(uuidString: projectId) ?? UUID()
        let descriptor = FetchDescriptor<HFProject>(predicate: #Predicate { $0.id == projectIdUUID })
        if let project = try? modelContext.fetch(descriptor).first {
            localText = project.script?.bodyText ?? ""
        }
    }
    
    private func commitChanges() {
        let projectIdUUID = UUID(uuidString: projectId) ?? UUID()
        let descriptor = FetchDescriptor<HFProject>(predicate: #Predicate { $0.id == projectIdUUID })
        if let project = try? modelContext.fetch(descriptor).first {
            if project.script == nil {
                project.script = Script(title: "Draft Script", bodyText: localText)
            } else {
                project.script?.bodyText = localText
            }
            project.lastModifiedDate = Date()
            try? modelContext.save()
        }
    }
}

/// A native `UITextView` wrapper natively executing Regex loop highlighting against Instructional bounds.
struct InstructionalTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        
        let font = UIFont(name: "AvenirNext-Bold", size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .bold)
        textView.font = font
        textView.textColor = .white
        textView.isScrollEnabled = true
        textView.keyboardAppearance = .dark
        textView.tintColor = UIColor(Color.hfAccent)
        
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { // Check only text value to prevent format-only loop loops
            let selectedRange = uiView.selectedRange
            uiView.attributedText = context.coordinator.formatText(text)
            uiView.selectedRange = selectedRange
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: InstructionalTextEditor
        
        // Caching fonts avoiding native OOM mapping repeatedly inside heavy typing callbacks
        private let defaultFont = UIFont(name: "AvenirNext-Bold", size: 32) ?? UIFont.systemFont(ofSize: 32, weight: .bold)
        
        // Exact Regex targeting strictly explicitly bounded brackets `[ ]`
        private let bracketRegex: NSRegularExpression? = {
            try? NSRegularExpression(pattern: "\\[[^\\]]*\\]", options: [])
        }()
        
        init(_ parent: InstructionalTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Prevent cursor reset jumps by preserving range
            let selectedRange = textView.selectedRange
            let newText = textView.text ?? ""
            
            // Format instantly locking physical bounds bypassing any layout recalculations stutter
            textView.attributedText = formatText(newText)
            textView.selectedRange = selectedRange
            
            // Bind back up
            parent.text = newText
        }
        
        func formatText(_ text: String) -> NSAttributedString {
            let attributed = NSMutableAttributedString(string: text)
            let fullRange = NSRange(location: 0, length: attributed.length)
            
            // Default Global Formatting
            attributed.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
            attributed.addAttribute(.font, value: defaultFont, range: fullRange)
            
            guard let regex = bracketRegex else { return attributed }
            
            let matches = regex.matches(in: text, options: [], range: fullRange)
            let instructionColor = UIColor(red: 1.0, green: 0.15, blue: 0.3, alpha: 1.0) // .hfAccent fallback
            
            for match in matches {
                // Natively apply distinct structural format isolated to exactly the Instruction bounds
                attributed.addAttribute(.foregroundColor, value: instructionColor, range: match.range)
                attributed.addAttribute(.font, value: defaultFont, range: match.range)
            }
            
            return attributed
        }
    }
}
