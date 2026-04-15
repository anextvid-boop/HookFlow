import SwiftUI
import SwiftData

/// The precise Ghost UI for Studio controls using TikTok's side-rail vertical layout.
public struct StudioControlsOverlay<Content: View>: View {
    @Binding var isRecording: Bool
    @Binding var isPreviewingTeleprompter: Bool
    let lastRecordedURL: URL?
    
    let onRecordToggled: () -> Void
    let onCloseTapped: () -> Void
    let onEditorTapped: () -> Void
    let onScriptTapped: () -> Void
    let onRewindTapped: () -> Void
    
    let isFlashOn: Bool
    let hasSegments: Bool
    let onFlipTapped: () -> Void
    let onFlashTapped: () -> Void
    let onUndoTapped: () -> Void
    let onSaveTapped: () -> Void
    
    @State private var showingSavedToast = false
    @State private var showingTeleprompterSettings = false
    
    // Teleprompter defaults
    @AppStorage("teleprompterSpeed") private var teleprompterSpeed: Double = 60.0
    @AppStorage("teleprompterSize") private var teleprompterSize: Double = 42.0
    @AppStorage("teleprompterMargin") private var teleprompterMargin: Double = 24.0
    @AppStorage("teleprompterAlignment") private var teleprompterAlignmentStr: String = "center"
    @AppStorage("teleprompterMirrored") private var teleprompterMirrored: Bool = false
    
    let content: Content
    
    public init(
        isRecording: Binding<Bool>,
        isPreviewingTeleprompter: Binding<Bool>,
        lastRecordedURL: URL?,
        onRecordToggled: @escaping () -> Void,
        onCloseTapped: @escaping () -> Void,
        onEditorTapped: @escaping () -> Void,
        onScriptTapped: @escaping () -> Void,
        onRewindTapped: @escaping () -> Void = {},
        isFlashOn: Bool = false,
        hasSegments: Bool = false,
        onFlipTapped: @escaping () -> Void = {},
        onFlashTapped: @escaping () -> Void = {},
        onUndoTapped: @escaping () -> Void = {},
        onSaveTapped: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self._isRecording = isRecording
        self._isPreviewingTeleprompter = isPreviewingTeleprompter
        self.lastRecordedURL = lastRecordedURL
        self.onRecordToggled = onRecordToggled
        self.onCloseTapped = onCloseTapped
        self.onEditorTapped = onEditorTapped
        self.onScriptTapped = onScriptTapped
        self.onRewindTapped = onRewindTapped
        self.isFlashOn = isFlashOn
        self.hasSegments = hasSegments
        self.onFlipTapped = onFlipTapped
        self.onFlashTapped = onFlashTapped
        self.onUndoTapped = onUndoTapped
        self.onSaveTapped = onSaveTapped
        self.content = content()
    }
    
    private func railButtonTemplate(icon: String, color: Color = .white) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(color)
            .frame(width: 44, height: 44)
            .background(Circle().fill(.black.opacity(0.5)).shadow(radius: 4))
            .contentShape(Rectangle())
    }
    
    public var body: some View {
        content
            // LAYER 1: Top-Left Close Navigation
            .overlay(alignment: .topLeading) {
                if !isRecording {
                    Button(action: onCloseTapped) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.black.opacity(0.5)).shadow(radius: 4))
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("close_button")
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            // LAYER 2: Trailing Vertical Setup Rail
            .overlay(alignment: .trailing) {
                if !isRecording {
                    VStack(spacing: 20) {
                        Button(action: onFlipTapped) {
                            railButtonTemplate(icon: "arrow.triangle.2.circlepath.camera.fill")
                        }
                        
                        Button(action: onFlashTapped) {
                            railButtonTemplate(
                                icon: isFlashOn ? "bolt.fill" : "bolt.slash.fill", 
                                color: isFlashOn ? .yellow : .white
                            )
                        }
                        
                        Button(action: onScriptTapped) {
                            railButtonTemplate(icon: "doc.text.viewfinder")
                        }
                        
                        Button(action: onRewindTapped) {
                            railButtonTemplate(icon: "backward.end.alt.fill")
                        }
                        
                        Button(action: {
                            withAnimation {
                                let wasShowing = showingTeleprompterSettings
                                showingTeleprompterSettings.toggle()
                                if wasShowing {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                } else {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                }
                            }
                        }) {
                            railButtonTemplate(
                                icon: "textformat.size",
                                color: showingTeleprompterSettings ? .hfAccent : .white
                            )
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(Color.black.opacity(0.3)))
                    .padding(.trailing, 16) // Slightly nudged back from extreme edge for the dock spacing
                    .padding(.bottom, 60) // Nudge up to stay clear of the record array
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            // LAYER 3: Active Teleprompter Settings Drawer
            .overlay(alignment: .top) {
                if showingTeleprompterSettings && !isRecording {
                    TeleprompterSettingsConsole(isPreviewingTeleprompter: $isPreviewingTeleprompter)
                        .padding(.horizontal, 24)
                        .padding(.top, 84) 
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            // LAYER 4: Bottom Record HUD - Safe Area Locked
            .safeAreaInset(edge: .bottom) {
                HStack(alignment: .center) {
                    // Left Node (Discard Segment if valid layer exists)
                    ZStack(alignment: .leading) {
                        if !isRecording {
                            Button(action: onUndoTapped) {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 24, weight: .bold))
                                    Text("Discard")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(.black.opacity(0.5)).shadow(radius: 4))
                                .contentShape(Rectangle())
                            }
                            .accessibilityIdentifier("discard_segment_button")
                            .transition(.opacity.combined(with: .scale))
                            .disabled(!hasSegments)
                            .opacity(hasSegments ? 1.0 : 0.25)
                        }
                    }
                    .frame(width: 140, alignment: .center)
                    
                    Spacer()
                    
                    // Center Node (Record Button Core)
                    Button(action: onRecordToggled) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 5)
                                .frame(width: 84, height: 84)
                            
                            RoundedRectangle(cornerRadius: isRecording ? 8 : 34)
                                .fill(Color.hfAccent)
                                .frame(width: isRecording ? 36 : 68, height: isRecording ? 36 : 68)
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("record_button")
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Right Node (Editor/Save Stack)
                    ZStack(alignment: .trailing) {
                        if !isRecording {
                            HStack(spacing: 12) {
                                if showingSavedToast {
                                    Text("Saved")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(.green.opacity(0.8)))
                                        .transition(.opacity)
                                }
                                
                                Button(action: onEditorTapped) {
                                    Image(systemName: "film")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(lastRecordedURL != nil ? .white : .gray)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(lastRecordedURL != nil ? .blue.opacity(0.8) : .black.opacity(0.5)).shadow(radius: 4))
                                        .contentShape(Rectangle())
                                }
                                .accessibilityIdentifier("editor_button")
                                .disabled(lastRecordedURL == nil)
                                .opacity(lastRecordedURL != nil ? 1.0 : 0.25)
                                
                                Button(action: onSaveTapped) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(.black.opacity(0.5)).shadow(radius: 4))
                                        .contentShape(Rectangle())
                                }
                                .accessibilityIdentifier("save_to_photos_button")
                                .disabled(lastRecordedURL == nil)
                                .opacity(lastRecordedURL != nil ? 1.0 : 0.25)
                            }
                        }
                    }
                    .frame(width: 140, alignment: .center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
    }
    
}
