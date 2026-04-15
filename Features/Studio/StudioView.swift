import SwiftUI
import SwiftData
import AVFoundation

public enum ZIndexProtocols {
    public static let camera: Double = 0
    public static let gradient: Double = 1
    public static let text: Double = 2
    public static let uiControls: Double = 3
    public static let bottomSheet: Double = 4
}

/// The absolute 1000x Command Center.
/// State is decoupled from the camera. The UI is completely Subtractive (Ghost UI).
public struct StudioView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppRouter.self) private var router
    @StateObject private var captureService = VideoCaptureService()
    
    let projectId: String
    
    @State private var isRecording = false
    @State private var isMaskingBase = false // Applies Neural Masking during heavy background transitions
    @State private var isPreviewingTeleprompter = false
    @State private var showScriptModal = false
    
    // Core Engine Decoupling (Phase 1/3)
    @State private var teleprompterEngine = TeleprompterEngine()
    
    // Phase 1 Dummy Toggle
    @State private var debugShowBounds = false
    
    // Phase 10 Studio Export Engine additions
    @State private var isExporting = false
    @State private var showExportSettings = false
    @State private var targetQuality: RecordingQuality = .hd1080p
    @State private var targetFrameRate: Int = 30
    @State private var exportTask: Task<Void, Never>?
    let stitchingService = StitchingService()
    
    @Query private var projects: [HFProject]
    
    public init(projectId: String) {
        self.projectId = projectId
        let idVal = UUID(uuidString: projectId) ?? UUID()
        self._projects = Query(filter: #Predicate<HFProject> { $0.id == idVal })
    }
    
    // Abstracted reference to the exact script text natively derived from SwiftData
    private var scriptData: String {
        guard let project = projects.first else { return "Welcome to HookFlow V2. Create a script in the Editor." }
        return project.script?.bodyText ?? "Welcome to HookFlow V2. Nothing to read."
    }
    
    private var totalDuration: TimeInterval {
        guard let segments = projects.first?.videoSegments else { return 0 }
        return segments.reduce(0) { $0 + (($1.endTrim ?? $1.duration) - $1.startTrim) }
    }
    
    private var estimatedExportSizeMB: Double {
        let duration = totalDuration
        var megabytesPerSecond: Double = 3.0
        
        switch (targetQuality, targetFrameRate) {
        case (.hd720p, 24), (.hd720p, 30): megabytesPerSecond = 1.25
        case (.hd720p, 60): megabytesPerSecond = 1.8
        case (.hd1080p, 24), (.hd1080p, 30): megabytesPerSecond = 3.0
        case (.hd1080p, 60): megabytesPerSecond = 4.2
        case (.uhd4k, 24), (.uhd4k, 30): megabytesPerSecond = 7.5
        case (.uhd4k, 60): megabytesPerSecond = 10.6
        default: megabytesPerSecond = 3.0
        }
        
        return duration * megabytesPerSecond
    }
    
    @State private var lastRecordedURL: URL?
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. The Hardware View - Zero state bounds attached
            CameraPreviewLayer(session: captureService.captureSession)
                .ignoresSafeArea(.keyboard)
                .overlay(Color.green.opacity(debugShowBounds ? 0.3 : 0)) // Phase 1: Camera bound dummy
                .zIndex(ZIndexProtocols.camera)
            
            // 2. Programmatic Neural Masking 
            if isMaskingBase {
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(ZIndexProtocols.camera + 0.5)
            }
            
            // 4. Subtractive Ghost UI Controls (Phase 1 Port)
            StudioControlsOverlay(
                isRecording: $isRecording,
                isPreviewingTeleprompter: $isPreviewingTeleprompter,
                lastRecordedURL: lastRecordedURL,
                onRecordToggled: toggleRecording,
                onCloseTapped: closeStudio,
                onEditorTapped: openEditor,
                onScriptTapped: openScript,
                onRewindTapped: {
                    teleprompterEngine.rewind()
                },
                isFlashOn: captureService.isFlashOn,
                hasSegments: !(projects.first?.videoSegments.isEmpty ?? true),
                onFlipTapped: {
                    captureService.toggleCameraPosition()
                },
                onFlashTapped: {
                    captureService.toggleFlash()
                },
                onUndoTapped: undoLastTake,
                onSaveTapped: { showExportSettings = true }
            ) {
                // 3. Live Teleprompter Overlay (Strictly Hit Testing Disabled inside component)
                LiveTeleprompterView(
                    scriptContent: scriptData, 
                    isRecording: $isRecording, 
                    isPreviewing: $isPreviewingTeleprompter,
                    debugShowBounds: debugShowBounds
                )
                .zIndex(ZIndexProtocols.text)
            }
            .zIndex(ZIndexProtocols.uiControls)
            
            // Phase 10 Studio Export Engine UI
            if isExporting {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        Spacer()
                        
                        // Circular Progress Ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0.0, to: 0.75)
                                .stroke(Color.hfAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(Angle(degrees: Double(Date().timeIntervalSince1970).truncatingRemainder(dividingBy: 1) * 360))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isExporting)
                            
                            Image(systemName: "film")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            Text("Stitching Production...")
                                .font(HFTypography.title(size: 20))
                                .foregroundColor(.white)
                            
                            Text("Processing AVFoundation chunks natively.")
                                .font(HFTypography.caption())
                                .foregroundColor(.hfTextTertiary)
                        }
                        
                        Spacer()
                        
                        // Massive Cancel Boundary
                        Button(action: {
                            exportTask?.cancel()
                            withAnimation(.easeIn(duration: 0.3)) {
                                isExporting = false
                            }
                        }) {
                            Text("CANCEL EXPORT")
                                .font(HFTypography.title(size: 16))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .padding(.bottom, DesignTokens.Spacing.xl)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
                    .padding(32)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .environment(teleprompterEngine)
        .onAppear {
            isMaskingBase = false
            captureService.startSession()
            teleprompterEngine.pause()
        }
        .onDisappear {
            captureService.stopSession()
            teleprompterEngine.pause()
        }
        .onChange(of: isRecording) { _, rec in
            if rec {
                teleprompterEngine.play()
            } else {
                teleprompterEngine.pause()
                teleprompterEngine.rewind()
            }
        }
        .onChange(of: isPreviewingTeleprompter) { _, prev in
            if prev {
                teleprompterEngine.play()
            } else {
                teleprompterEngine.pause()
                teleprompterEngine.rewind()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .animation(.easeInOut(duration: 0.3), value: isMaskingBase)
        .sheet(isPresented: $showScriptModal) {
            TeleprompterScriptEditorView(projectId: projectId)
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showExportSettings) {
            ExportSettingsView(
                selectedQuality: $targetQuality,
                selectedFrameRate: $targetFrameRate,
                estimatedSizeMB: estimatedExportSizeMB,
                onExport: {
                    showExportSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        exportAndSave()
                    }
                }
            )
            .presentationDetents([.fraction(0.65), .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                // Phase 3 Step 4.3: Terminate cleanly
                if isRecording {
                    toggleRecording()
                }
                captureService.stopSession()
                teleprompterEngine.pause()
            } else {
                if !captureService.captureSession.isRunning {
                    captureService.startSession()
                }
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            Task {
                if let url = try? await captureService.stopRecording(),
                   let project = projects.first {
                   
                   do {
                       let draftURL = try await StorageManager.shared.getDraftDirectory(for: project.draftDirectoryName)
                       let filename = UUID().uuidString + ".mov"
                       let destinationURL = draftURL.appendingPathComponent(filename)
                       
                       try FileManager.default.moveItem(at: url, to: destinationURL)
                       
                       let asset = AVURLAsset(url: destinationURL)
                       let duration = try await asset.load(.duration).seconds
                       
                       await MainActor.run {
                           self.lastRecordedURL = destinationURL
                           project.videoSegments.append(VideoSegment(relativeVideoPath: filename, duration: duration))
                           
                           withAnimation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)) {
                               self.isRecording = false 
                           }
                       }
                   } catch {
                       print("Failed to save capture: \(error)")
                       await MainActor.run {
                           withAnimation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)) {
                               self.isRecording = false 
                           }
                       }
                   }
                } else {
                    await MainActor.run { 
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)) {
                            self.isRecording = false 
                        }
                    }
                }
            }
        } else {
            // Trigger actor background loop
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            do {
                try captureService.startRecording(to: tempURL)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)) {
                    isRecording = true
                }
            } catch {
                print("Phase 3 Step 4.2: Hardware failed to lock recording, teleprompter prevented from advancing. \(error)")
            }
        }
    }
    
    private func closeStudio() {
        captureService.stopSession()
        router.popToRoot()
    }
    
    private func openEditor() {
        isMaskingBase = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            captureService.stopSession()
            router.navigate(to: .editor(projectId: projectId))
        }
    }
    
    private func openScript() {
        showScriptModal = true
    }
    
    private func undoLastTake() {
        guard let project = projects.first, !project.videoSegments.isEmpty else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let removedSegment = project.videoSegments.removeLast()
            
            if let lastUrl = lastRecordedURL, lastUrl.lastPathComponent == removedSegment.relativeVideoPath {
                lastRecordedURL = nil
            }
            
            Task {
                do {
                    let draftURL = try await StorageManager.shared.getDraftDirectory(for: project.draftDirectoryName)
                    let fileURL = draftURL.appendingPathComponent(removedSegment.relativeVideoPath)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.removeItem(at: fileURL)
                    }
                } catch {
                    print("Failed to delete undone segment from disk: \(error)")
                }
            }
        }
    }
    
    private func exportAndSave() {
        guard !isExporting else { return }
        guard let project = projects.first, !project.videoSegments.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        withAnimation(.easeOut(duration: 0.3)) {
            isExporting = true
        }
        
        exportTask = Task {
            var segmentsData: [(url: URL, timeRange: CMTimeRange?, speed: Double, bRollURL: URL?, brightness: Double, contrast: Double, saturation: Double, scale: Double, offsetX: Double, offsetY: Double, rotation: Double, outTransition: VideoTransitionType, outTransitionDuration: Double)] = []
            for segment in project.videoSegments {
                if let resolved = try? await StorageManager.shared.resolveURL(for: segment.relativeVideoPath, in: project.draftDirectoryName) {
                    let start = segment.startTrim
                    let end = segment.endTrim ?? segment.duration
                    let range = CMTimeRange(
                        start: CMTime(seconds: start, preferredTimescale: 600),
                        duration: CMTime(seconds: end - start, preferredTimescale: 600)
                    )
                    var segmentBRollURL: URL? = nil
                    if let bRollRelativePath = segment.bRollRelativePath {
                        segmentBRollURL = try? await StorageManager.shared.resolveURL(for: bRollRelativePath, in: project.draftDirectoryName)
                    }
                    segmentsData.append((url: resolved, timeRange: range, speed: segment.playbackSpeed, bRollURL: segmentBRollURL, brightness: segment.brightness, contrast: segment.contrast, saturation: segment.saturation, scale: segment.scale, offsetX: segment.offsetX, offsetY: segment.offsetY, rotation: segment.rotation, outTransition: segment.outTransition, outTransitionDuration: segment.outTransitionDuration))
                }
            }
            
            do {
                try Task.checkCancellation()
                let enrichedData = segmentsData
                try Task.checkCancellation()
                let stitchedURL = try await stitchingService.stitchSegments(enrichedData, targetQuality: targetQuality, canvasAspectRatio: "9:16")
                
                try Task.checkCancellation()
                try await StorageManager.shared.saveToCameraRoll(videoURL: stitchedURL)
                
                await MainActor.run {
                    isExporting = false
                    exportTask = nil
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    shareVideo(url: stitchedURL)
                }
            } catch {
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.isExporting = false
                    }
                    print("Export Failed off-thread: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func shareVideo(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }
}
