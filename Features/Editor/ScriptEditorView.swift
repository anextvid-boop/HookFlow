import SwiftUI

public struct ScriptEditorView: View {
    @State public var script: String
    public var onScriptChanged: ((String) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var textInputFocused: Bool
    
    public init(initialScript: String, onScriptChanged: ((String) -> Void)? = nil) {
        _script = State(initialValue: initialScript)
        self.onScriptChanged = onScriptChanged
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Phase 11.2 Text Storage Core & 11.4 Glass Background Map
                TextEditor(text: $script)
                    .font(HFTypography.title(size: 24))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .contentMargins(.all, 24) // Phase 11.2 Modifier Maps
                    .focused($textInputFocused)
                    .hfGlassmorphic()
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .padding()
            }
            .navigationTitle("Script Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Phase 11.4 Toolbar Safety Bounds
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        textInputFocused = false
                    }
                    .font(HFTypography.callout())
                    .foregroundColor(.hfAccent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .onChange(of: script) { oldValue, newValue in
                // Phase 11.3 Real-time Persistency Logic hook
                onScriptChanged?(newValue)
            }
        }
        .onAppear {
            // Phase 11.3 Dynamic Focus Manipulation State
            textInputFocused = true
        }
    }
}
