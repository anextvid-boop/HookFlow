import SwiftUI
import CoreMedia
import AVFoundation
import SwiftData
import PhotosUI

public struct EditorView: View {
    @Environment(AppRouter.self) private var router
    @State private var playerService = VideoPlayerService()
    
    let projectId: String
    
    @Query private var projects: [HFProject]
    
    // MEMORY SAFE: Edits (trim, delete) hit this struct array, not the physical disk. No silent fails.
    @State private var workingSegments: [VideoSegment] = [] 
    @State private var scrubTime: TimeInterval = 0.0
    @State private var selectedSegmentID: UUID? = nil
    @State private var selectedCaptionID: UUID? = nil
    
    // Phase 9: Transitions Engine
    @State private var showTransitionSheet = false
    @State private var activeTransitionSegmentID: UUID? = nil
    
    // Phase 11: Color Grading
    @State private var showColorGradingSheet = false
    
    @State private var exportTask: Task<Void, Never>?
    // Phase 8.1 & 6.2 Contextual Tools
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isReplacingMedia: Bool = false
    @State private var targetBRollSegmentID: UUID? = nil
    @State private var showVolumeSheet = false
    @State private var tempVolume: Double = 1.0
    @State private var isExporting = false
    @State private var showExportSettings = false
    @State private var targetQuality: RecordingQuality = .hd1080p
    @State private var targetFrameRate: Int = 30
    
    // Phase 15: Canvas Manipulation Gestures
    @GestureState private var pinchScale: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var rotateAngle: Angle = .zero
    @State private var accumulatedScale: CGFloat = 1.0
    @State private var accumulatedOffset: CGSize = .zero
    @State private var accumulatedRotation: Angle = .zero
    
    // Phase 7.1: Dummy Undo/Redo State
    @State private var mockUndoStackCount: Int = 0
    @State private var mockRedoStackCount: Int = 0
    
    private var totalDuration: TimeInterval {
        workingSegments.reduce(0) { $0 + (($1.endTrim ?? $1.duration) - $1.startTrim) }
    }
    
    private var estimatedExportSizeMB: Double {
        let duration = totalDuration
        var megabytesPerSecond: Double = 3.0 // Default 1080p30
        
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
    
    @State private var isScrubbing = false
    @State private var wasPlayingBeforeScrub = false
    
    // HUD Toggle
    @State private var showTeleprompterHUD = false
    
    // Phase 11 Script Editor
    @State private var showScriptModal = false
    @State private var scriptText = ""
    
    // Phase 4.2 Caption Styling HUD
    @State private var showCaptionStyleSheet = false
    @State private var captionFontName: String = "System"
    @State private var captionColor: Color = .white
    @State private var captionStrokeWidth: Double = 0.0
    @State private var captionShadowRadius: Double = 4.0
    
    // Phase 12 Teleprompter Logic
    @AppStorage("teleprompterSpeed") private var speed: Double = 50.0
    
    let stitchingService = StitchingService()
    
    public init(projectId: String) {
        self.projectId = projectId
        let idVal = UUID(uuidString: projectId) ?? UUID()
        self._projects = Query(filter: #Predicate<HFProject> { $0.id == idVal })
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, 10)
                .padding(.bottom, DesignTokens.Spacing.sm)
                .background(Color.black)
            
            // Phase 13 boundary crop visualization (Middle Canvas)
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    VideoPlayerRepresentable(player: playerService.player)
                        .allowsHitTesting(false)
                        .scaleEffect(selectedSegmentID != nil ? (accumulatedScale * pinchScale) : 1.0)
                        .rotationEffect(selectedSegmentID != nil ? (accumulatedRotation + rotateAngle) : .zero)
                        .offset(
                            x: selectedSegmentID != nil ? (accumulatedOffset.width + dragOffset.width) : 0,
                            y: selectedSegmentID != nil ? (accumulatedOffset.height + dragOffset.height) : 0
                        )
                        .aspectRatio(CGSize(width: 9, height: 16), contentMode: .fit)
                        .frame(width: geo.size.width, height: geo.size.height)
                        // Invisible hit box to catch gestures over the entire screen when a segment is selected
                        .overlay(
                            Color.white.opacity(0.001)
                                .gesture(
                                    selectedSegmentID != nil ?
                                    SimultaneousGesture(
                                        SimultaneousGesture(
                                            MagnificationGesture()
                                                .updating($pinchScale) { value, state, _ in
                                                    // In SwiftUI, magnification has a baseline of 1.0. We want to apply it gracefully.
                                                    state = value
                                                }
                                                .onEnded { value in
                                                    accumulatedScale *= value
                                                    commitTransformChanges()
                                                },
                                            DragGesture()
                                                .updating($dragOffset) { value, state, _ in
                                                    state = value.translation
                                                }
                                                .onEnded { value in
                                                    accumulatedOffset.width += value.translation.width
                                                    accumulatedOffset.height += value.translation.height
                                                    commitTransformChanges()
                                                }
                                        ),
                                        RotationGesture()
                                            .updating($rotateAngle) { value, state, _ in
                                                state = value
                                            }
                                            .onEnded { value in
                                                accumulatedRotation += value
                                                commitTransformChanges()
                                            }
                                    ) : nil
                                )
                                .onTapGesture(count: 2) {
                                    // Reset transforms on double tap
                                    if selectedSegmentID != nil {
                                        accumulatedScale = 1.0
                                        accumulatedOffset = .zero
                                        accumulatedRotation = .zero
                                        commitTransformChanges()
                                    }
                                }
                        )
                    
                    // Phase 7.4 Teleprompter Toggle Engine & Phase 12 Console Overlay
                    if showTeleprompterHUD {
                        teleprompterOverlayHUD
                    }
                    
                    // Phase 4.2 Live Interactive Caption Engine
                    captionOverlayEngine(in: geo.size)
                }
            }
            
            // Bottom Panel Area (Toolbar & NLE Timeline)
            VStack(spacing: 0) {
                // Toolbar Strip
                ZStack {
                    if selectedCaptionID != nil {
                        captionContextToolbar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if selectedSegmentID != nil {
                        selectedContextToolbar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        globalContextToolbar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(height: 60)
                .padding(.vertical, DesignTokens.Spacing.sm)
                
                // Timeline Strip perfectly constrained to memory limits
                TimelineScrubberView(
                    segments: $workingSegments, 
                    currentTime: $scrubTime,
                    selectedSegmentID: $selectedSegmentID,
                    selectedCaptionID: $selectedCaptionID,
                    totalDuration: totalDuration,
                    hasVibeMusic: false, // Phase 6.2 Implementation pending
                    onScrubbingChanged: { scrubbing in
                        guard !isExporting else { return }
                        isScrubbing = scrubbing
                        if scrubbing {
                            playerService.pause()
                        } else {
                            Task {
                                await playerService.seek(to: CMTime(seconds: scrubTime, preferredTimescale: 600))
                            }
                            // If we want to auto-play after scrub, we can call togglePlay
                        }
                    },
                    onSeek: { time in
                        guard !isExporting else { return }
                        Task {
                            await playerService.seek(to: CMTime(seconds: time, preferredTimescale: 600))
                        }
                        scrubTime = time
                    },
                    onTrimEnded: {
                        reloadPlayer()
                    },
                    onSegmentDeleted: { segment in
                        guard !isExporting else { return }
                        if let index = workingSegments.firstIndex(where: { $0.id == segment.id }) {
                            workingSegments.remove(at: index)
                            if let project = projects.first {
                                project.videoSegments = workingSegments
                            }
                            reloadPlayer()
                        }
                    },
                    onRequestBRollPicker: { segmentID in
                        targetBRollSegmentID = segmentID
                        showPhotosPicker = true
                    },
                    onRemoveBRoll: { segmentID in
                        if let index = workingSegments.firstIndex(where: { $0.id == segmentID }) {
                            workingSegments[index].bRollRelativePath = nil
                            reloadPlayer()
                        }
                    },
                    onRequestTransitionPicker: { segmentID in
                        self.activeTransitionSegmentID = segmentID
                        self.showTransitionSheet = true
                    }
                )
                .frame(height: 180)
                .padding(.bottom, 30) // Safe Area
            }
            .background(Color(white: 0.1).ignoresSafeArea(edges: .bottom))
            
            // Phase 10.2: Progress HUD Engine
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
        .onAppear {
            loadProject()
            // Phase 8.2 Clock Thread Observer
            playerService.addPeriodicTimeObserver(interval: CMTime(seconds: 0.05, preferredTimescale: 600)) { time in
                if !isScrubbing {
                    scrubTime = time.seconds
                }
            }
        }
        .onDisappear {
            // Phase 8.4 Application Layer Termination Map
            playerService.clearPlayer()
        }
        // Phase 10.4 Dismiss Lockout
        .interactiveDismissDisabled(isExporting)
        // Phase 11.1 Presentation Structure
        .sheet(isPresented: $showScriptModal) {
            ScriptEditorView(initialScript: scriptText) { newScript in
                scriptText = newScript
                // Real-time persistency hook
                // StorageManager.shared.updateProject()
            }
        }
        .sheet(isPresented: $showTransitionSheet) {
            transitionSheetView()
        }
        .sheet(isPresented: $showExportSettings) {
            ExportSettingsView(
                selectedQuality: $targetQuality,
                selectedFrameRate: $targetFrameRate,
                estimatedSizeMB: estimatedExportSizeMB,
                onExport: {
                    showExportSettings = false
                    // Start export automatically after dismissal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        exportAndSave()
                    }
                }
            )
            .presentationDetents([.fraction(0.65), .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showColorGradingSheet, onDismiss: {
            reloadPlayer()
            // StorageManager.shared.updateProject() // Implicit persist later
        }) {
            if let id = selectedSegmentID, let idx = workingSegments.firstIndex(where: { $0.id == id }) {
                ColorGradingSheet(
                    brightness: $workingSegments[idx].brightness,
                    contrast: $workingSegments[idx].contrast,
                    saturation: $workingSegments[idx].saturation,
                    onDismiss: { showColorGradingSheet = false }
                )
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showVolumeSheet, onDismiss: {
            reloadPlayer()
        }) {
            if let id = selectedSegmentID, let idx = workingSegments.firstIndex(where: { $0.id == id }) {
                VolumeHUD(
                    volume: $workingSegments[idx].volume,
                    onDismiss: { showVolumeSheet = false }
                )
                .presentationDetents([.fraction(0.3)])
                .presentationDragIndicator(.visible)
            }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .any(of: [.videos, .images]))
        .onChange(of: selectedPhotoItem) { _, _ in
            processSelectedPhotoItem()
        }
        // Phase 4.2: Caption Style Bottom Sheet
        .sheet(isPresented: $showCaptionStyleSheet) {
            captionStyleSheetView()
        }
    }
    
    private func loadProject() {
        guard let project = projects.first else { return }
        workingSegments = project.videoSegments
        
        reloadPlayer()
    }
    
    // Abstracted to properly sync the engine when timeline is structurally modified
    private func reloadPlayer() {
        guard let project = projects.first else { return }
        playerService.clearPlayer()
        
        // Exact boundary execution here:
        // By pulling natively from the SwiftData array, we are completely detached from hardware crashes.
        Task {
            let composition = AVMutableComposition()
            guard let videoTrackA = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let videoTrackB = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let audioTrackA = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let audioTrackB = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            
            var insertTime = CMTime.zero
            var segmentMap: [(CMTimeRange, VideoSegment, CMPersistentTrackID)] = []
            var segmentRenderData: [StitchingCompositionInstruction.SegmentRenderData] = []
            
            var useTrackA = true
            
            for (idx, segment) in workingSegments.enumerated() {
                if let url = try? await StorageManager.shared.resolveURL(for: segment.relativeVideoPath, in: project.draftDirectoryName) {
                    let asset = AVURLAsset(url: url)
                    if let assetVideoTrack = try? await asset.loadTracks(withMediaType: .video).first,
                       let assetAudioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                        
                        let start = segment.startTrim
                        let end = segment.endTrim ?? segment.duration
                        let rawDuration = CMTime(seconds: end - start, preferredTimescale: 600)
                        let timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600), duration: rawDuration)
                        
                        if idx > 0, workingSegments[idx - 1].outTransition == .crossDissolve {
                            let overlap = CMTime(seconds: workingSegments[idx - 1].outTransitionDuration, preferredTimescale: 600)
                            insertTime = CMTimeSubtract(insertTime, overlap)
                        }
                        
                        let currentVideoTrack = useTrackA ? videoTrackA : videoTrackB
                        let currentAudioTrack = useTrackA ? audioTrackA : audioTrackB
                        
                        // Insert Audio (always from the primary asset)
                        try? currentAudioTrack.insertTimeRange(timeRange, of: assetAudioTrack, at: insertTime)
                        
                        // Video Insertion (Base or B-Roll)
                        var bRollInjected = false
                        if let bRollRelativePath = segment.bRollRelativePath,
                           let bRollURL = try? await StorageManager.shared.resolveURL(for: bRollRelativePath, in: project.draftDirectoryName) {
                            let bRollAsset = AVURLAsset(url: bRollURL)
                            if let bRollVideoTrack = try? await bRollAsset.loadTracks(withMediaType: .video).first {
                                if let bRollTotalDuration = try? await bRollAsset.load(.duration) {
                                    var currentBrollTime = insertTime
                                    var remainingDuration = rawDuration
                                    
                                    while remainingDuration > .zero {
                                        let chunkDuration = CMTimeMinimum(remainingDuration, bRollTotalDuration)
                                        try? currentVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: chunkDuration), of: bRollVideoTrack, at: currentBrollTime)
                                        remainingDuration = CMTimeSubtract(remainingDuration, chunkDuration)
                                        currentBrollTime = CMTimeAdd(currentBrollTime, chunkDuration)
                                    }
                                    bRollInjected = true
                                }
                            }
                        }
                        
                        if !bRollInjected {
                            try? currentVideoTrack.insertTimeRange(timeRange, of: assetVideoTrack, at: insertTime)
                        }
                        
                        let mappedRange = CMTimeRange(start: insertTime, duration: rawDuration)
                        segmentMap.append((mappedRange, segment, currentAudioTrack.trackID))
                        
                        let renderData = StitchingCompositionInstruction.SegmentRenderData(
                            timeRange: mappedRange,
                            trackID: currentVideoTrack.trackID,
                            brightness: segment.brightness,
                            contrast: segment.contrast,
                            saturation: segment.saturation,
                            scale: segment.scale,
                            offsetX: segment.offsetX,
                            offsetY: segment.offsetY,
                            rotation: segment.rotation,
                            outTransition: segment.outTransition.rawValue,
                            outTransitionDuration: segment.outTransitionDuration
                        )
                        segmentRenderData.append(renderData)
                        
                        insertTime = CMTimeAdd(insertTime, rawDuration)
                        useTrackA.toggle()
                    }
                }
            }
            
            let videoComposition = AVMutableVideoComposition()
            videoComposition.customVideoCompositorClass = StitchingCompositor.self
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            
            let baseSize = composition.naturalSize
            let maxDim = max(baseSize.width, baseSize.height)
            let minDim = min(baseSize.width, baseSize.height)
            
            videoComposition.renderSize = CGSize(width: minDim, height: maxDim)
            
            let instruction = StitchingCompositionInstruction(
                timeRange: CMTimeRange(start: .zero, duration: insertTime),
                segments: segmentRenderData,
                trackIDs: [videoTrackA.trackID, videoTrackB.trackID]
            )
            videoComposition.instructions = [instruction]
            
            let playerItem = AVPlayerItem(asset: composition)
            playerItem.videoComposition = videoComposition
            
            // Phase 6.2 & 9 Audio Mixing
            let audioMix = AVMutableAudioMix()
            var audioInputParamsList: [AVMutableAudioMixInputParameters] = []
            
            let paramsA = AVMutableAudioMixInputParameters(track: audioTrackA)
            let paramsB = AVMutableAudioMixInputParameters(track: audioTrackB)
            
            for (range, segment, targetTrackID) in segmentMap {
                let params = targetTrackID == audioTrackA.trackID ? paramsA : paramsB
                
                // Cross dissolve audio fading (fade out)
                _ = Float(segment.volume)
                if segment.outTransition == .crossDissolve {
                    let transStartTime = CMTimeSubtract(CMTimeAdd(range.start, range.duration), CMTime(seconds: segment.outTransitionDuration, preferredTimescale: 600))
                    let transRange = CMTimeRange(start: transStartTime, duration: CMTime(seconds: segment.outTransitionDuration, preferredTimescale: 600))
                    params.setVolumeRamp(fromStartVolume: Float(segment.volume), toEndVolume: 0.0, timeRange: transRange)
                } else {
                    params.setVolumeRamp(fromStartVolume: Float(segment.volume), toEndVolume: Float(segment.volume), timeRange: range)
                }
            }
            
            audioInputParamsList.append(paramsA)
            audioInputParamsList.append(paramsB)
            audioMix.inputParameters = audioInputParamsList
            
            playerItem.audioMix = audioMix
            
            await MainActor.run {
                self.playerService.player.replaceCurrentItem(with: playerItem)
            }
        }
    }
    
    private func commitTransformChanges() {
        guard let id = selectedSegmentID, let idx = workingSegments.firstIndex(where: { $0.id == id }) else { return }
        workingSegments[idx].scale = Double(accumulatedScale)
        workingSegments[idx].offsetX = Double(accumulatedOffset.width)
        workingSegments[idx].offsetY = Double(accumulatedOffset.height)
        workingSegments[idx].rotation = accumulatedRotation.degrees
        
        if let project = projects.first {
            project.videoSegments = workingSegments
        }
        reloadPlayer()
    }
    
    private func togglePlay() {
        if playerService.isPlaying {
            playerService.pause()
        } else {
            playerService.play()
        }
    }
    
    private func deleteSelectedSegment() {
        guard let id = selectedSegmentID,
              let index = workingSegments.firstIndex(where: { $0.id == id }) else { return }
              
        withAnimation(.spring) {
            let removed = workingSegments.remove(at: index)
            selectedSegmentID = nil
            
            if let project = projects.first {
                project.videoSegments = workingSegments
                // Fire cleanup process asynchronously
                Task {
                    do {
                        let draftURL = try await StorageManager.shared.getDraftDirectory(for: project.draftDirectoryName)
                        let fileURL = draftURL.appendingPathComponent(removed.relativeVideoPath)
                        if FileManager.default.fileExists(atPath: fileURL.path) {
                            try FileManager.default.removeItem(at: fileURL)
                        }
                    } catch {
                        print("Failed to delete unused segment: \(error)")
                    }
                }
            }
        }
        
        reloadPlayer()
    }
    
    private func duplicateSelectedSegment() {
        guard let id = selectedSegmentID,
              let index = workingSegments.firstIndex(where: { $0.id == id }) else { return }
              
        withAnimation(.spring) {
            let source = workingSegments[index]
            // We duplicate natively targeting the EXACT same file chunk under a new UUID struct
            let duplicate = VideoSegment(
                relativeVideoPath: source.relativeVideoPath,
                duration: source.duration,
                startTrim: source.startTrim,
                endTrim: source.endTrim,
                brightness: source.brightness,
                contrast: source.contrast,
                saturation: source.saturation,
                scale: source.scale,
                offsetX: source.offsetX,
                offsetY: source.offsetY,
                rotation: source.rotation
            )
            workingSegments.insert(duplicate, at: index + 1)
            
            if let project = projects.first {
                project.videoSegments = workingSegments
            }
        }
        
        reloadPlayer()
    }
    
    private func activeSegmentIndex() -> Int? {
        if let id = selectedSegmentID, let idx = workingSegments.firstIndex(where: { $0.id == id }) {
            return idx
        }
        var accumulated: TimeInterval = 0
        for (index, segment) in workingSegments.enumerated() {
            let segDur = ((segment.endTrim ?? segment.duration) - segment.startTrim) / segment.playbackSpeed
            if scrubTime >= accumulated && scrubTime < accumulated + segDur {
                return index
            }
            accumulated += segDur
        }
        return workingSegments.isEmpty ? nil : workingSegments.count - 1
    }
    
    private func splitSegmentAtScrubTime() {
        guard let idx = activeSegmentIndex() else { return }
        
        var accumulated: TimeInterval = 0
        for i in 0..<idx {
            accumulated += ((workingSegments[i].endTrim ?? workingSegments[i].duration) - workingSegments[i].startTrim) / workingSegments[i].playbackSpeed
        }
        
        let segment = workingSegments[idx]
        
        // Prevent extremely tiny clip splitting protecting against math rounding zeros
        let currentEffectiveDuration = ((segment.endTrim ?? segment.duration) - segment.startTrim) / segment.playbackSpeed
        if currentEffectiveDuration < 0.2 { return } 
        
        // Find split point internally to the clip coordinates
        let localSplitTime = segment.startTrim + ((scrubTime - accumulated) * segment.playbackSpeed)
        
        // Make sure we're not splitting exactly at boundaries
        if localSplitTime <= segment.startTrim + 0.1 || localSplitTime >= (segment.endTrim ?? segment.duration) - 0.1 { return }
        
        let rightSegment = VideoSegment(
            relativeVideoPath: segment.relativeVideoPath,
            relativeThumbnailPath: segment.relativeThumbnailPath,
            duration: segment.duration,
            creationDate: segment.creationDate,
            startTrim: localSplitTime,
            endTrim: segment.endTrim,
            captionTokens: nil, // Do not duplicate captions into the second half implicitly
            playbackSpeed: segment.playbackSpeed,
            bRollRelativePath: segment.bRollRelativePath,
            outTransition: segment.outTransition,
            outTransitionDuration: segment.outTransitionDuration,
            brightness: segment.brightness,
            contrast: segment.contrast,
            saturation: segment.saturation,
            volume: segment.volume,
            scale: segment.scale,
            offsetX: segment.offsetX,
            offsetY: segment.offsetY,
            rotation: segment.rotation
        )
        
        withAnimation(.spring) {
            workingSegments[idx].endTrim = localSplitTime
            workingSegments[idx].outTransition = .none // The exact cut wipes the transition from the left 
            workingSegments[idx].outTransitionDuration = 0.5
            workingSegments.insert(rightSegment, at: idx + 1)
        }
        reloadPlayer()
    }
    
    
    
    private func addDummyCaption() {
        guard let idx = activeSegmentIndex() else { return }
        let seg = workingSegments[idx]
        let sTrim = seg.startTrim
        let tokenWidth = min(1.0, ((seg.endTrim ?? seg.duration) - sTrim))
        let newText = CaptionToken(text: "New Text Hook", startTime: sTrim, endTime: sTrim + tokenWidth)
        withAnimation(.spring) {
            if workingSegments[idx].captionTokens == nil {
                workingSegments[idx].captionTokens = [newText]
            } else {
                workingSegments[idx].captionTokens?.append(newText)
            }
        }
    }

    
    private func exportAndSave() {
        guard !isExporting, !workingSegments.isEmpty else { return }
        guard let project = projects.first else { return }
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        withAnimation(.easeOut(duration: 0.3)) {
            isExporting = true
        }
        playerService.pause()
        
        // Exact architectural verification: Fire Heavy computation totally off the main thread.
        // Phase 10.2 AVFoundation Background Processing Map
        exportTask = Task {
            var segmentsData: [(url: URL, timeRange: CMTimeRange?, speed: Double, bRollURL: URL?, brightness: Double, contrast: Double, saturation: Double, scale: Double, offsetX: Double, offsetY: Double, rotation: Double, outTransition: VideoTransitionType, outTransitionDuration: Double)] = []
            for segment in workingSegments {
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
                // Dispatch isolated IO writer task.
                try await StorageManager.shared.saveToCameraRoll(videoURL: stitchedURL)
                
                await MainActor.run {
                    isExporting = false
                    exportTask = nil
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    // Phase 10.3 Post-Completion Export Trigger
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
            
            // For iPad compatibility
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func closeEditor() {
        if let project = projects.first {
            project.videoSegments = workingSegments
        }
        playerService.clearPlayer()
        router.navigate(to: .dashboard)
    }
    
    // Phase 8.1: Import from Photos Picker
    private func processSelectedPhotoItem() {
        guard let item = selectedPhotoItem, let project = projects.first else { return }
        let replacingId = isReplacingMedia ? selectedSegmentID : nil
        let draftDirectoryName = project.draftDirectoryName
        let localTargetBRollSegmentID = targetBRollSegmentID
        
        Task {
            do {
                if let movieTransfer = try await item.loadTransferable(type: MovieTransfer.self) {
                    let draftURL = try await StorageManager.shared.getDraftDirectory(for: draftDirectoryName)
                    let filename = UUID().uuidString + ".mov"
                    let destinationURL = draftURL.appendingPathComponent(filename)
                    
                    try FileManager.default.moveItem(at: movieTransfer.url, to: destinationURL)
                    
                    let asset = AVURLAsset(url: destinationURL)
                    let duration = try await asset.load(.duration).seconds
                    
                    await MainActor.run {
                        withAnimation(.spring) {
                            if let bRollID = localTargetBRollSegmentID, let index = workingSegments.firstIndex(where: { $0.id == bRollID }) {
                                // Overlay natively onto track
                                workingSegments[index].bRollRelativePath = filename
                            } else if isReplacingMedia, let index = workingSegments.firstIndex(where: { $0.id == replacingId }) {
                                let newSeg = VideoSegment(relativeVideoPath: filename, duration: duration)
                                workingSegments[index] = newSeg
                                selectedSegmentID = newSeg.id
                            } else {
                                let newSeg = VideoSegment(relativeVideoPath: filename, duration: duration)
                                workingSegments.append(newSeg)
                            }
                            project.videoSegments = workingSegments
                        }
                        reloadPlayer()
                        isReplacingMedia = false
                        targetBRollSegmentID = nil
                        selectedPhotoItem = nil
                    }
                }
            } catch {
                print("Failed to process Photos picker media: \(error)")
                await MainActor.run {
                    isReplacingMedia = false
                    targetBRollSegmentID = nil
                    selectedPhotoItem = nil
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button(action: closeEditor) {
                Image(systemName: "chevron.left")
                    .font(HFTypography.title(size: 20))
                    .foregroundColor(.white)
                    .padding(.vertical, DesignTokens.Spacing.sm)
            }
            
            Spacer()
            
            // Phase 7.1: Undo/Redo Engine UI
            HStack(spacing: DesignTokens.Spacing.xl) {
                Button(action: {
                    if mockUndoStackCount > 0 { mockUndoStackCount -= 1; mockRedoStackCount += 1 }
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(HFTypography.callout())
                        .foregroundColor(mockUndoStackCount > 0 ? .white : .white.opacity(0.3))
                }
                .disabled(mockUndoStackCount == 0)
                
                Button(action: {
                    if mockRedoStackCount > 0 { mockRedoStackCount -= 1; mockUndoStackCount += 1 }
                }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(HFTypography.callout())
                        .foregroundColor(mockRedoStackCount > 0 ? .white : .white.opacity(0.3))
                }
                .disabled(mockRedoStackCount == 0)
            }
            // Temporarily mapping edit actions to bump undo stack just for UI scaffolding
            .onChange(of: selectedSegmentID) { _, newValue in
                if newValue != nil {
                    mockUndoStackCount += 1
                }
            }
            
            Spacer()
            
            // Explicit Export Background Call
            Button(action: { showExportSettings = true }) {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(DesignTokens.Spacing.xs)
                        .frame(width: 44, height: 44)
                        .background(Color.hfAccent.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(HFTypography.callout())
                        .foregroundColor(.white)
                        .padding(DesignTokens.Spacing.xs)
                        .frame(width: 44, height: 44)
                        .background(Color.hfAccent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
                }
            }
            .disabled(isExporting)
        }
    }
    
    private var teleprompterOverlayHUD: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text(scriptText.isEmpty ? "Tap 'Edit Script' to add text" : scriptText)
                .font(HFTypography.title(size: 24))
                .foregroundColor(.white)
                .opacity(0.8)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: 150)
                .mask(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black, .black, .clear]), startPoint: .top, endPoint: .bottom)
                )
            
            Divider().background(Color.white.opacity(0.3))
            
            // Phase 12.1 & 12.2 Teleprompter Settings Controls
            VStack(spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("Scroll Speed")
                        .font(HFTypography.caption())
                        .foregroundColor(.hfTextTertiary)
                    Spacer()
                    Text("\(Int(speed))")
                        .font(HFTypography.caption())
                        .foregroundColor(.hfAccent)
                }
                
                Slider(value: $speed, in: 10...100, step: 1.0)
                    .accentColor(.hfAccent)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .padding(.horizontal, DesignTokens.Spacing.md)
        .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 0.95))))
    }
    
    private var selectedContextToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                toolbarButton(icon: "scissors", label: "Split", color: .white) {
                    splitSegmentAtScrubTime()
                }
                
                toolbarButton(icon: "photo.on.rectangle", label: "Replace", color: .white) {
                    isReplacingMedia = true
                    showPhotosPicker = true
                }
                
                toolbarButton(icon: "speaker.wave.2", label: "Volume", color: .white) {
                    showVolumeSheet = true
                }
                
                toolbarButton(icon: "slider.horizontal.3", label: "Color", color: .white) {
                    showColorGradingSheet = true
                }
                
                toolbarButton(icon: "plus.square.on.square", label: "Duplicate", color: .white) {
                    duplicateSelectedSegment()
                }
                
                toolbarButton(icon: "trash", label: "Delete", color: .red) {
                    deleteSelectedSegment()
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring) { selectedSegmentID = nil }
                }) {
                    Text("Done")
                        .font(HFTypography.caption())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.2)))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }
    
    private var globalContextToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                toolbarButton(icon: playerService.isPlaying ? "pause.fill" : "play.fill", label: playerService.isPlaying ? "Pause" : "Play", color: playerService.isPlaying ? .hfAccent : .white) {
                    togglePlay()
                }
                
                toolbarButton(icon: "doc.plaintext", label: "Script", color: .white) {
                    showScriptModal = true
                }
                
                toolbarButton(icon: "text.quote", label: "Prompter", color: showTeleprompterHUD ? .hfAccent : .white) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showTeleprompterHUD.toggle()
                    }
                }
                
                toolbarButton(icon: "plus.circle", label: "Add Clip", color: .white) {
                    isReplacingMedia = false
                    showPhotosPicker = true
                }
                
                toolbarButton(icon: "macwindow.badge.plus", label: "B-Roll", color: .white) {
                    if let selID = selectedSegmentID {
                        targetBRollSegmentID = selID
                        showPhotosPicker = true
                    } else if let activeIdx = activeSegmentIndex() {
                        targetBRollSegmentID = workingSegments[activeIdx].id
                        showPhotosPicker = true
                    }
                }
                
                toolbarButton(icon: "textformat", label: "Text", color: .white) {
                    addDummyCaption()
                }
                
                toolbarButton(icon: "wand.and.stars", label: "Effects", color: .white) {
                    print("Effects hook")
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }
    
    private func toolbarButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(height: 24)
                
                Text(label)
                    .font(HFTypography.caption(size: 10))
                    .foregroundColor(color == .white ? .hfTextSecondary : color)
            }
        }
        .disabled(isExporting)
    }
    
    @ViewBuilder
    private func transitionSheetView() -> some View {
        VStack(spacing: 24) {
            Text("Select Transition")
                .font(HFTypography.title(size: 20))
                .foregroundColor(.white)
                .padding(.top, 24)
            
            VStack(spacing: 12) {
                ForEach(VideoTransitionType.allCases, id: \.self) { transition in
                    Button(action: {
                        if let id = activeTransitionSegmentID, let idx = workingSegments.firstIndex(where: { $0.id == id }) {
                            workingSegments[idx].outTransition = transition
                            
                            // Default assignment if selecting an active transition and duration is zero
                            if transition != .none && workingSegments[idx].outTransitionDuration == 0 {
                                workingSegments[idx].outTransitionDuration = 0.5
                            }
                            
                            reloadPlayer()
                        }
                    }) {
                        HStack {
                            Text(transition.rawValue)
                                .font(HFTypography.body())
                            Spacer()
                            if let id = activeTransitionSegmentID, let idx = workingSegments.firstIndex(where: { $0.id == id }), workingSegments[idx].outTransition == transition {
                                Image(systemName: "checkmark")
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.hfSurface)
                        .cornerRadius(8)
                    }
                }
                
                if let id = activeTransitionSegmentID, let idx = workingSegments.firstIndex(where: { $0.id == id }), workingSegments[idx].outTransition != .none {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration: \(String(format: "%.1f", workingSegments[idx].outTransitionDuration))s")
                            .font(HFTypography.caption())
                            .foregroundColor(.gray)
                        
                        Slider(value: Binding(
                            get: { workingSegments[idx].outTransitionDuration },
                            set: { workingSegments[idx].outTransitionDuration = $0 }
                        ), in: 0.2...2.0, step: 0.1) { editing in
                            if !editing { reloadPlayer() }
                        }
                        .tint(Color.hfAccent)
                    }
                    .padding()
                    .background(Color.hfSurface)
                    .cornerRadius(8)
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 24)
            
            Button("Done") {
                showTransitionSheet = false
            }
            .font(HFTypography.callout())
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.hfAccent)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.hfBackground.ignoresSafeArea())
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }
    
    // Phase 4.2: Caption Context Toolbar & StyleSheet
    private var captionContextToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                toolbarButton(icon: "textformat", label: "Edit Text", color: .white) {
                    showScriptModal = true
                }
                
                toolbarButton(icon: "paintpalette", label: "Style", color: .white) {
                    showCaptionStyleSheet = true
                }
                
                toolbarButton(icon: "trash", label: "Delete", color: .red) {
                    if let capID = selectedCaptionID, let segIdx = workingSegments.firstIndex(where: { $0.captionTokens?.contains(where: { $0.id == capID }) == true }) {
                        workingSegments[segIdx].captionTokens?.removeAll(where: { $0.id == capID })
                        selectedCaptionID = nil
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring) { selectedCaptionID = nil }
                }) {
                    Text("Done")
                        .font(HFTypography.caption())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.2)))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }
    
    @ViewBuilder
    private func captionStyleSheetView() -> some View {
        VStack(spacing: 24) {
            Text("Caption Style")
                .font(HFTypography.title(size: 20))
                .foregroundColor(.white)
                .padding(.top, 24)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Font
                    HStack {
                        Text("Font").foregroundColor(.white)
                        Spacer()
                        Picker("Font", selection: $captionFontName) {
                            Text("System").tag("System")
                            Text("Arial").tag("Arial")
                            Text("Avenir").tag("Avenir")
                            Text("Courier").tag("Courier")
                            Text("Impact").tag("Impact")
                        }
                        .tint(.hfAccent)
                    }
                    .padding()
                    .background(Color.hfSurface)
                    .cornerRadius(8)
                    
                    // Color
                    ColorPicker("Text Color", selection: $captionColor)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.hfSurface)
                        .cornerRadius(8)
                    
                    // Stroke
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Stroke Width").foregroundColor(.white)
                            Spacer()
                            Text("\(captionStrokeWidth, specifier: "%.1f")").foregroundColor(.gray)
                        }
                        Slider(value: $captionStrokeWidth, in: 0...5, step: 0.5)
                            .accentColor(.hfAccent)
                    }
                    .padding()
                    .background(Color.hfSurface)
                    .cornerRadius(8)
                    
                    // Shadow
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Shadow Blur").foregroundColor(.white)
                            Spacer()
                            Text("\(captionShadowRadius, specifier: "%.1f")").foregroundColor(.gray)
                        }
                        Slider(value: $captionShadowRadius, in: 0...20, step: 1.0)
                            .accentColor(.hfAccent)
                    }
                    .padding()
                    .background(Color.hfSurface)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
        }
        .presentationDetents([.fraction(0.6)])
        .presentationDragIndicator(.visible)
        .background(Color(white: 0.1).ignoresSafeArea())
    }
    
    // Renders the actual on-screen caption string if scrubber is at its timestamp
    @ViewBuilder
    private func captionOverlayEngine(in size: CGSize) -> some View {
        if let activeToken = workingSegments.flatMap({ $0.captionTokens ?? [] }).first(where: { scrubTime >= $0.startTime && scrubTime <= $0.endTime }) {
            Text(activeToken.text)
                .font(captionFontName == "System" ? .system(size: 36, weight: .bold, design: .default) : .custom(captionFontName, size: 36, relativeTo: .title).weight(.bold))
                .foregroundColor(captionColor)
                // Outline Hack using Shadow for robust "stroke"
                .shadow(color: .black, radius: captionStrokeWidth > 0 ? captionStrokeWidth : 0)
                .shadow(color: .black, radius: captionStrokeWidth > 0 ? captionStrokeWidth : 0)
                // Drop shadow
                .shadow(color: captionColor.opacity(0.8), radius: captionShadowRadius, x: 0, y: captionShadowRadius * 0.5)
                .multilineTextAlignment(.center)
                .padding()
                .position(x: size.width / 2, y: size.height * 0.75) // Lower middle
        }
    }
}


// Phase 6.2 Volume Control HUD
public struct VolumeHUD: View {
    @Binding var volume: Double
    var onDismiss: () -> Void
    
    // Convert 0...5 float range to 0...500 percentage string
    private var volumePercentage: String {
        return "\(Int(volume * 100))%"
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Volume")
                    .font(HFTypography.title(size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation {
                        volume = 1.0
                    }
                }) {
                    Text("Reset")
                        .font(HFTypography.callout())
                        .foregroundColor(.hfAccent)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.hfTextTertiary)
                    Spacer()
                    Text(volumePercentage)
                        .font(HFTypography.caption())
                        .foregroundColor(volume == 1.0 ? .hfTextTertiary : .white)
                        .frame(width: 50, alignment: .trailing)
                }
                
                Slider(value: $volume, in: 0...5.0, step: 0.1)
                    .accentColor(.hfAccent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
    }
}
