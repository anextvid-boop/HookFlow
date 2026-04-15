import SwiftUI
import Observation
import QuartzCore

// Added PreferenceKey to measure text height for clamping bounds
private struct TextHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// The Interactive Teleprompter Overlay.
/// Maps DragGestures to manual offsets, pausing the 60fps clock automatically, 
/// and elegantly resuming after a physical delay (3 seconds).
public struct LiveTeleprompterView: View {
    let scriptContent: String
    
    @Environment(TeleprompterEngine.self) private var engine
    
    @Binding var isRecording: Bool
    @Binding var isPreviewing: Bool
    
    // Bounds debugging from parent (Phase 1)
    var debugShowBounds: Bool
    
    // Generate massive test payload automatically
    private var activeScript: String {
        if debugShowBounds {
            let chunk = "DUMMY TEXT OVERFLOW TEST WIDE STRING WRAP. "
            return String(repeating: chunk, count: 1200) // ~7000 words
        }
        return scriptContent
    }
    
    // Mapped from AppStorage settings globally to determine pixels-per-second scroll rate.
    @AppStorage("teleprompterSpeed") var teleprompterSpeed: Double = 60.0 
    @AppStorage("teleprompterSize") var teleprompterSize: Double = 42.0
    @AppStorage("teleprompterMargin") var teleprompterMargin: Double = 24.0
    @AppStorage("teleprompterAlignment") var teleprompterAlignmentStr: String = "center"
    @AppStorage("teleprompterMirrored") var teleprompterMirrored: Bool = false
    @AppStorage("teleprompterTextColor") var teleprompterTextColorStr: String = "white"
    @AppStorage("teleprompterHideInstructions") var teleprompterHideInstructions: Bool = false
    
    // Phase 1: Interactive Scrub State
    @State private var previousDragTranslation: CGFloat = 0
    
    // Phase 2: Dynamic Boundaries
    @State private var contentHeight: CGFloat = 1000 // Fallback
    
    // Phase 8: Rich Text Attributed String Cache (Prevents continuous 60fps recomputation lags)
    @State private var processedScript: AttributedString = AttributedString("")
    
    public init(scriptContent: String, isRecording: Binding<Bool>, isPreviewing: Binding<Bool>, debugShowBounds: Bool = false) {
        self.scriptContent = scriptContent
        self._isRecording = isRecording
        self._isPreviewing = isPreviewing
        self.debugShowBounds = debugShowBounds
    }
    
    // Convert the string representation of alignment to SwiftUI TextAlignment
    private var textAlignment: TextAlignment {
        switch teleprompterAlignmentStr {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    private var textColor: Color {
        switch teleprompterTextColorStr {
        case "yellow": return .yellow
        case "green": return Color(red: 0.2, green: 1.0, blue: 0.2)
        default: return .white
        }
    }
    
    private func rebuildProcessedScript() {
        var baseString = activeScript
        
        // Hide instructions toggle logic
        if teleprompterHideInstructions && (isRecording || isPreviewing) {
            // Physically extract [ ] blocks
            if let regex = try? NSRegularExpression(pattern: "\\[[^\\]]*\\]", options: []) {
                baseString = regex.stringByReplacingMatches(
                    in: baseString, 
                    options: [], 
                    range: NSRange(location: 0, length: baseString.utf16.count), 
                    withTemplate: ""
                )
            }
        }
        
        let nsString = NSMutableAttributedString(string: baseString)
        let fullRange = NSRange(location: 0, length: baseString.utf16.count)
        
        if !teleprompterHideInstructions || (!isRecording && !isPreviewing) {
            if let regex = try? NSRegularExpression(pattern: "\\[[^\\]]*\\]", options: []) {
                let matches = regex.matches(in: baseString, options: [], range: fullRange)
                let instructionColor = UIColor(red: 1.0, green: 0.15, blue: 0.3, alpha: 0.6) // HookFlow Red + dimmed aggressively
                
                for match in matches {
                    nsString.addAttribute(.foregroundColor, value: instructionColor, range: match.range)
                }
            }
        }
        
        processedScript = AttributedString(nsString)
    }
    
    public var body: some View {
        GeometryReader { proxy in
            Color.clear.overlay(alignment: .top) {
                ZStack(alignment: .top) {
                // Bounds Debug Overlay
                if debugShowBounds {
                    Path { path in
                        // Eye-line markers
                        path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.2))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height * 0.2))
                        path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.35))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height * 0.35))
                    }
                    .stroke(Color.yellow, lineWidth: 2)
                    .zIndex(100)
                    
                    Text("Geo: \(Int(proxy.size.width))x\(Int(proxy.size.height))")
                        .foregroundColor(.yellow)
                        .background(Color.black)
                        .position(x: proxy.size.width / 2, y: 150)
                        .zIndex(100)
                }
                
                VStack {
                    Text(processedScript)
                        .font(.system(size: CGFloat(teleprompterSize), weight: .heavy, design: .rounded))
                        .kerning(2.5) // Step 1.4: Extreme tracking
                        .lineSpacing(CGFloat(teleprompterSize) * 0.3)
                        .foregroundColor(textColor) // Step 1.3: User customizable colors
                        .multilineTextAlignment(textAlignment)
                        .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2) // Step 1.2: Mandatory strict shadow depth
                        .padding(.horizontal, CGFloat(teleprompterMargin))
                        .background(debugShowBounds ? Color.red.opacity(0.4) : Color.clear)
                        .scaleEffect(x: teleprompterMirrored ? -1 : 1, y: 1, anchor: .center)
                        // Phase 4 Stage 4: Camera Field-of-View Hardware Offsets
                        .offset(x: 12) // Step 4.2: Slight off-center guide towards physical lens
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: TextHeightPreferenceKey.self, value: geo.size.height)
                        }
                    )
                    .contentShape(Rectangle())
                    // The drag gesture allows the user to grab the text directly, updating delta dynamically 
                    // WITHOUT explicitly pausing or halting the underlying hardware scroll engine.
                    .gesture(
                        DragGesture(minimumDistance: 10, coordinateSpace: .global)
                            .onChanged { value in
                                let delta = value.translation.height - previousDragTranslation
                                previousDragTranslation = value.translation.height
                                
                                let maxScroll = max(0, contentHeight)
                                let inversionMultiplier: CGFloat = teleprompterMirrored ? -1 : 1
                                
                                // Delta math overrides hardware engine strictly mathematically without pausing logic
                                engine.currentYOffset -= (delta * inversionMultiplier)
                                engine.currentYOffset = min(maxScroll + 400, max(-300, engine.currentYOffset))
                            }
                            .onEnded { _ in
                                previousDragTranslation = 0
                            }
                    )
                }
                .drawingGroup() // Phase 3: Force Metal GPU acceleration
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: proxy.size.width)
            .onAppear {
                rebuildProcessedScript()
            }
            .onChange(of: activeScript) { _, _ in rebuildProcessedScript() }
            .onChange(of: teleprompterHideInstructions) { _, _ in rebuildProcessedScript() }
            .onChange(of: isRecording) { _, _ in rebuildProcessedScript() }
            .onChange(of: isPreviewing) { _, _ in rebuildProcessedScript() }
            .onPreferenceChange(TextHeightPreferenceKey.self) { height in
                // Add a small buffer so the last line comfortably clears the center
                self.contentHeight = height + (proxy.size.height / 2)
                engine.setMaxScroll(self.contentHeight)
                // Also update speed dynamically right away as it initializes
                engine.updateSpeed(teleprompterSpeed)
            }
            .onChange(of: teleprompterSpeed) { _, newSpd in
                engine.updateSpeed(newSpd)
            }
            .padding(.vertical, 40) // Bounds are now handled securely by safeAreaInset of the wrapper
            .offset(y: -engine.currentYOffset)
            } // Close Color.clear.overlay
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.0), // Prioritize top reading 
                        .init(color: .black, location: 0.40), // Hard baseline text edge
                        .init(color: .clear, location: 0.70) // Rapid fade towards center bottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Phase 4 Stage 1: Geometry-Anchored Reading Zone (Eye-line Marker)
            HStack {
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(90))
                    .foregroundColor(.hfAccent)
                    .font(.system(size: 12))
                    .offset(x: -8)
                Spacer()
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(-90))
                    .foregroundColor(.hfAccent)
                    .font(.system(size: 12))
                    .offset(x: 8)
            }
            .offset(y: proxy.size.height * 0.20 + 4) // Center the triangles on the top native boundary text baseline
            .opacity((isRecording || isPreviewing) ? 1.0 : 0.6)
            .animation(.easeInOut, value: isRecording || isPreviewing)
            .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark) // Step 4.1: Target text readability overrides

    }
}

/// Engine controlling deterministic teleprompter scrolling via Native CADisplayLink.
@MainActor
@Observable
public final class TeleprompterEngine {
    
    // Core physical bounds
    public var currentYOffset: CGFloat = 0
    public var maxScrollHeight: CGFloat = 0
    
    // Engine State
    public var isPlaying: Bool = false
    public var targetSpeed: Double = 60.0 // Points per second
    public var currentSpeed: Double = 0.0
    
    // Soft Start logic
    private var softStartDuration: CFTimeInterval = 1.5
    private var softStartTime: CFTimeInterval = 0
    private var isSoftStarting: Bool = false
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    
    public init() {}
    
    /// Binds the speed parameter cleanly from UI
    public func updateSpeed(_ newSpeed: Double) {
        self.targetSpeed = newSpeed
        if !isSoftStarting {
            self.currentSpeed = newSpeed
        }
    }
    
    public func setMaxScroll(_ height: CGFloat) {
        self.maxScrollHeight = max(0, height)
    }
    
    /// Play the display link
    public func play() {
        guard !isPlaying else { return }
        self.isPlaying = true
        self.isSoftStarting = true
        self.currentSpeed = 0
        self.lastTimestamp = CACurrentMediaTime()
        self.softStartTime = self.lastTimestamp
        startLink()
    }
    
    /// Pause the display link entirely without resetting offset
    public func pause() {
        guard isPlaying else { return }
        self.isPlaying = false
        stopLink()
    }
    
    /// Immediate rewind
    public func rewind() {
        self.currentYOffset = 0
    }
    
    // Internal link execution
    private func startLink() {
        displayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(handleTick(link:)))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }
    
    private func stopLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handleTick(link: CADisplayLink) {
        guard isPlaying else { return }
        
        let currentTimestamp = link.timestamp
        let delta = currentTimestamp - lastTimestamp
        self.lastTimestamp = currentTimestamp
        
        // Phase 3 Step 3.4: Soft-start interpolation
        if isSoftStarting {
            let elapsed = currentTimestamp - softStartTime
            if elapsed >= softStartDuration {
                self.currentSpeed = targetSpeed
                self.isSoftStarting = false
            } else {
                // Ease in out or simple linear ramp
                let progress = elapsed / softStartDuration
                self.currentSpeed = targetSpeed * progress
            }
        } else {
            self.currentSpeed = targetSpeed
        }
        
        // Translate speed (points per second) over precise exact frame time
        let offsetDelta = CGFloat(currentSpeed * delta)
        
        // Progress the UI
        let nextOffset = currentYOffset + offsetDelta
        
        if nextOffset >= maxScrollHeight {
            currentYOffset = maxScrollHeight
            pause() // Autostop at bottom
        } else {
            currentYOffset = nextOffset
        }
    }
}

