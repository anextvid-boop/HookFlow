import SwiftUI

public struct TeleprompterSettingsConsole: View {
    @AppStorage("teleprompterSpeed") private var teleprompterSpeed: Double = 60.0
    @AppStorage("teleprompterSize") private var teleprompterSize: Double = 42.0
    @AppStorage("teleprompterMargin") private var teleprompterMargin: Double = 24.0
    @AppStorage("teleprompterAlignment") private var teleprompterAlignmentStr: String = "center"
    @AppStorage("teleprompterMirrored") private var teleprompterMirrored: Bool = false
    @AppStorage("teleprompterTextColor") private var teleprompterTextColorStr: String = "white"
    @AppStorage("teleprompterHideInstructions") private var teleprompterHideInstructions: Bool = false
    
    @Binding var isPreviewingTeleprompter: Bool
    
    public init(isPreviewingTeleprompter: Binding<Bool>) {
        self._isPreviewingTeleprompter = isPreviewingTeleprompter
    }
    
    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "tortoise.fill")
                    .foregroundColor(.hfTextSecondary)
                    .frame(width: 24)
                Slider(value: Binding(
                    get: { teleprompterSpeed },
                    set: { val in
                        if val != teleprompterSpeed {
                            teleprompterSpeed = val
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    }
                ), in: 10...150)
                    .tint(.hfAccent)
                Image(systemName: "hare.fill")
                    .foregroundColor(.hfTextSecondary)
                    .frame(width: 24)
            }
            
            HStack {
                Image(systemName: "textformat.size.smaller")
                    .foregroundColor(.hfTextSecondary)
                    .frame(width: 24)
                Slider(value: Binding(
                    get: { teleprompterSize },
                    set: { val in
                        if val != teleprompterSize {
                            teleprompterSize = val
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    }
                ), in: 20...120)
                    .tint(.white)
                Image(systemName: "textformat.size.larger")
                    .foregroundColor(.hfTextSecondary)
                    .frame(width: 24)
            }
            
            HStack {
                Image(systemName: "arrow.left.and.right.text.vertical")
                    .foregroundColor(.hfTextSecondary)
                    .frame(width: 24)
                Slider(value: Binding(
                    get: { teleprompterMargin },
                    set: { val in
                        if val != teleprompterMargin {
                            teleprompterMargin = val
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    }
                ), in: 0...100)
                    .tint(.white)
                Image(systemName: "arrow.right.and.left.text.vertical")
                    .foregroundColor(.hfTextSecondary)
                    .frame(width: 24)
            }
            
            HStack(spacing: 24) {
                // Alignment group
                HStack(spacing: 12) {
                    Button(action: { teleprompterAlignmentStr = "leading" }) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(teleprompterAlignmentStr == "leading" ? .hfAccent : .white)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("align_left_button")
                    Button(action: { teleprompterAlignmentStr = "center" }) {
                        Image(systemName: "text.aligncenter")
                            .foregroundColor(teleprompterAlignmentStr == "center" ? .hfAccent : .white)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("align_center_button")
                    Button(action: { teleprompterAlignmentStr = "trailing" }) {
                        Image(systemName: "text.alignright")
                            .foregroundColor(teleprompterAlignmentStr == "trailing" ? .hfAccent : .white)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("align_right_button")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Capsule().fill(.black.opacity(0.3)))
                
                // Color group
                HStack(spacing: 12) {
                    Button(action: { teleprompterTextColorStr = "white" }) {
                        Circle().fill(Color.white).frame(width: 20, height: 20)
                            .overlay(Circle().stroke(teleprompterTextColorStr == "white" ? Color.blue : Color.clear, lineWidth: 2))
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("color_white_button")
                    Button(action: { teleprompterTextColorStr = "yellow" }) {
                        Circle().fill(Color.yellow).frame(width: 20, height: 20)
                            .overlay(Circle().stroke(teleprompterTextColorStr == "yellow" ? Color.blue : Color.clear, lineWidth: 2))
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("color_yellow_button")
                    Button(action: { teleprompterTextColorStr = "green" }) {
                        Circle().fill(Color.green).frame(width: 20, height: 20)
                            .overlay(Circle().stroke(teleprompterTextColorStr == "green" ? Color.blue : Color.clear, lineWidth: 2))
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("color_green_button")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Capsule().fill(.black.opacity(0.3)))
                
                Spacer()
            }
            
            HStack(spacing: 24) {
                // Mirror toggle
                Button(action: { teleprompterMirrored.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill") // Flip icon
                        Text("Mirror")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(teleprompterMirrored ? .hfAccent : .white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Capsule().fill(.black.opacity(0.3)))
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("mirror_teleprompter_button")
                
                // Hide Instructions toggle
                Button(action: { teleprompterHideInstructions.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: teleprompterHideInstructions ? "eye.slash.fill" : "eye.fill")
                        Text("Instructions")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(teleprompterHideInstructions ? .hfAccent : .white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Capsule().fill(.black.opacity(0.3)))
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("hide_instructions_button")
                
                Spacer()
            }
            
            // Phase 3 Teleprompter Practice Toggle
            Button(action: {
                isPreviewingTeleprompter.toggle()
            }) {
                HStack {
                    Image(systemName: isPreviewingTeleprompter ? "stop.fill" : "play.fill")
                    Text(isPreviewingTeleprompter ? "Stop Preview" : "Preview Scroll")
                        .font(HFTypography.caption())
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(Capsule().fill(Color.hfAccent))
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("preview_teleprompter_button")
            .padding(.top, DesignTokens.Spacing.xs)
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .preferredColorScheme(.dark)
    }
}
