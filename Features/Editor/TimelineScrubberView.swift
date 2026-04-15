import SwiftUI
import AVFoundation

/// Bound purely to the Struct array, rendering an NLE multi-track layout.
public struct TimelineScrubberView: View {
    @Binding public var segments: [VideoSegment]
    @Binding public var currentTime: TimeInterval
    @Binding public var selectedSegmentID: UUID?
    @Binding public var selectedCaptionID: UUID?
    public let totalDuration: TimeInterval
    public var hasVibeMusic: Bool = false
    
    public var onScrubbingChanged: ((Bool) -> Void)?
    public var onSeek: ((TimeInterval) -> Void)?
    public var onTrimEnded: (() -> Void)?
    public var onSegmentDeleted: ((VideoSegment) -> Void)?
    
    public var onRequestBRollPicker: ((UUID) -> Void)?
    public var onRemoveBRoll: ((UUID) -> Void)?
    
    public var onRequestTransitionPicker: ((UUID) -> Void)? // Phase 9.1
    
    @State private var isDraggingPlayhead: Bool = false
    @State private var dragStartTime: TimeInterval = 0
    private let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    // NLE Constants
    @State private var baseTimelineScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    private let minScale: CGFloat = 0.2
    private let maxScale: CGFloat = 5.0
    private let basePxPerSec: CGFloat = 80.0
    
    // Zoom Feedback State
    @State private var showZoomHUD: Bool = false
    @State private var hudWorkItem: DispatchWorkItem? = nil
    @State private var hasHitZoomLimit: Bool = false

    private var currentScale: CGFloat {
        let scale = baseTimelineScale * gestureZoomScale
        return min(maxScale, max(minScale, scale))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Context/Toolbar region for active segment
            ZStack {
                HStack {
                    Spacer()
                    if selectedSegmentID != nil {
                        Text("Hold edges to trim")
                            .font(HFTypography.caption(size: 10))
                            .foregroundColor(.hfAccent)
                    }
                }
                
                // Zoom HUD perfectly centered over timeline context toolbar
                Text(String(format: "Zoom: %.1fx", currentScale))
                    .font(HFTypography.caption(size: 10).bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
                    .opacity(showZoomHUD ? 1.0 : 0.0)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, 4)
            
            GeometryReader { geo in
                let pxPerSec = basePxPerSec * currentScale
                let dynamicWidth = max(geo.size.width, totalDuration * pxPerSec)
                let halfAnchor = geo.size.width / 2.0
                
                ZStack(alignment: .topLeading) {
                    
                    // Track Canvas Background
                    Color.black.opacity(0.3)
                        .frame(width: geo.size.width, height: geo.size.height)
                        
                    // --- 5.1 METRONOME RULER CANVAS --- //
                    Canvas { context, size in
                        let durationInt = Int(ceil(totalDuration)) + 60 // Pad memory beyond bounds securely
                        let textFont = Font.system(size: 8, weight: .bold)
                        
                        for s in 0...durationInt {
                            let xLoc = CGFloat(s) * pxPerSec
                            let isPrimary = s % 5 == 0 // Every 5 sec
                            
                            var path = Path()
                            path.move(to: CGPoint(x: xLoc, y: 0))
                            path.addLine(to: CGPoint(x: xLoc, y: isPrimary ? 12 : 6))
                            
                            context.stroke(path, with: .color(.white.opacity(isPrimary ? 0.6 : 0.2)), lineWidth: 1)
                            
                            if isPrimary {
                                let m = s / 60
                                let sec = s % 60
                                let timeText = String(format: "%02d:%02d", m, sec)
                                context.draw(Text(timeText).font(textFont).foregroundColor(.white.opacity(0.8)), at: CGPoint(x: xLoc + 14, y: 6))
                            }
                        }
                    }
                    .frame(width: dynamicWidth, height: 20)
                    .offset(x: halfAnchor - (currentTime * pxPerSec))
                    .allowsHitTesting(false)
                    
                    // MULTI-TRACK STACK (Dynamically auto-scrolling)
                    VStack(alignment: .leading, spacing: 6) {
                        
                        // --- TRACK 0: CAPTIONS ---
                        HStack(spacing: 0) {
                            ForEach($segments) { $segment in
                                let duration = ((segment.endTrim ?? segment.duration) - segment.startTrim) / segment.playbackSpeed
                                let w = max(0, duration * pxPerSec)
                                
                                ZStack(alignment: .leading) {
                                    Color.clear.frame(width: w, height: 20).contentShape(Rectangle())
                                    
                                    if segment.captionTokens != nil {
                                        ForEach(segment.captionTokens!.indices, id: \.self) { index in
                                            let token = segment.captionTokens![index]
                                            let sTrim = segment.startTrim
                                            let eTrim = segment.endTrim ?? segment.duration
                                            
                                            // Render only visible temporal space overlapping trim
                                            if token.endTime > sTrim && token.startTime < eTrim {
                                                let vStart = max(sTrim, token.startTime)
                                                let xOffset = (vStart - sTrim) * pxPerSec
                                                let isAnySelected = selectedCaptionID != nil || selectedSegmentID != nil
                                                
                                                CaptionNodeScaffold(
                                                    token: Binding(get: { segment.captionTokens![index] }, set: { segment.captionTokens?[index] = $0 }),
                                                    isSelected: selectedCaptionID == token.id,
                                                    isAnySelected: isAnySelected,
                                                    pxPerSec: pxPerSec,
                                                    segmentDuration: segment.duration
                                                )
                                                .offset(x: xOffset)
                                                .onTapGesture {
                                                    withAnimation(.spring) {
                                                        selectedCaptionID = selectedCaptionID == token.id ? nil : token.id
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(width: w, height: 20)
                                .clipped()
                            }
                        }
                        .padding(.top, 12)
                            
                        // --- TRACK 1: B-ROLL OVERLAYS ---
                            HStack(spacing: 0) {
                                ForEach(segments) { segment in
                                    let duration = ((segment.endTrim ?? segment.duration) - segment.startTrim) / segment.playbackSpeed
                                    let w = duration * pxPerSec
                                    
                                    if segment.bRollRelativePath != nil {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Color.purple.opacity(0.8))
                                            .overlay(Text("B-Roll").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                                            .frame(width: w, height: 24)
                                            .contentShape(Rectangle())
                                            .zIndex(10)
                                    } else {
                                        Color.clear.frame(width: w, height: 24)
                                            .contentShape(Rectangle())
                                    }
                                }
                            }
                            .padding(.top, 12)
                            
                            // --- TRACK 2: MAIN VIDEO SEGMENTS ---
                            HStack(spacing: 0) {
                                ForEach($segments) { $segment in
                                    let duration = ((segment.endTrim ?? segment.duration) - segment.startTrim) / segment.playbackSpeed
                                    let w = max(0, duration * pxPerSec)
                                    let isSelected = selectedSegmentID == segment.id
                                    let isAnySelected = selectedSegmentID != nil || selectedCaptionID != nil
                                    let hasTransition = segment.outTransition != .none
                                    let transitionOffsetWidth = hasTransition ? (segment.outTransitionDuration * pxPerSec) : 0
                                    
                                    ZStack {
                                        // Visual Block
                                        Rectangle()
                                            .fill(isSelected ? Color.yellow.opacity(0.1) : Color.hfSurface)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: isSelected ? 2 : 0)
                                            )
                                            .overlay(
                                                // Phase 8.2 & Part 2: Real-time Async Thumbnail Strip
                                                GeometryReader { segmentGeo in
                                                    VideoThumbnailStrip(segment: segment, width: segmentGeo.size.width)
                                                }
                                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                            .shadow(color: isSelected ? Color.yellow.opacity(0.6) : Color.clear, radius: isSelected ? 6 : 0, y: isSelected ? 0 : 0)
                                            .scaleEffect(isSelected ? 1.02 : 1.0)
                                            .opacity(isAnySelected ? (isSelected ? 1.0 : 0.4) : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                                        
                                        // Show Speed Chip
                                        if segment.playbackSpeed != 1.0 {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Text("\(segment.playbackSpeed, specifier: "%.1f")x")
                                                        .font(.system(size: 8, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .padding(2)
                                                        .background(Color.hfAccent)
                                                        .cornerRadius(2)
                                                }
                                            }
                                            .padding(2)
                                        }
                                        
                                        // Trim Handles (only if selected)
                                        if isSelected {
                                            HStack {
                                                // LEFT HANDLE
                                                trimHandle(isLeft: true, segment: $segment, pxPerSec: pxPerSec)
                                                Spacer()
                                                // RIGHT HANDLE
                                                trimHandle(isLeft: false, segment: $segment, pxPerSec: pxPerSec)
                                            }
                                        }
                                        
                                        // Phase 9.1: Transition Intersection Node
                                        if segment.id != segments.last?.id {
                                            HStack {
                                                Spacer(minLength: 0)
                                                Button(action: {
                                                    onRequestTransitionPicker?(segment.id)
                                                }) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                            .fill(hasTransition ? Color.hfAccent : Color.white)
                                                            .frame(width: 16, height: 20)
                                                            .shadow(color: .black.opacity(0.4), radius: 2)
                                                        if hasTransition {
                                                            Image(systemName: "slider.horizontal.3")
                                                                .font(.system(size: 8, weight: .bold))
                                                                .foregroundColor(.white)
                                                        } else {
                                                            Image(systemName: "plus")
                                                                .font(.system(size: 10, weight: .black))
                                                                .foregroundColor(.black)
                                                        }
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .offset(x: 8 - (transitionOffsetWidth / 2)) // Center on the physical stitched seam
                                                .zIndex(200)
                                            }
                                        }
                                    }
                                    .frame(width: w, height: 44)
                                    // Phase 9.3: Overlap Clip Alignment Rendering
                                    .padding(.trailing, -transitionOffsetWidth)
                                    .contentShape(Rectangle())
                                    .zIndex(isSelected ? 100 : 1)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedSegmentID == segment.id {
                                                selectedSegmentID = nil 
                                            } else {
                                                selectedSegmentID = segment.id
                                            }
                                        }
                                        
                                        // Phase 3.2: Snap playhead to segment start time
                                        var absoluteTime: Double = 0
                                        for seg in segments {
                                            if seg.id == segment.id { break }
                                            let segDuration = ((seg.endTrim ?? seg.duration) - seg.startTrim) / seg.playbackSpeed
                                            absoluteTime += segDuration
                                            // Account for transition overlaps
                                            if seg.outTransition != .none {
                                                absoluteTime -= seg.outTransitionDuration
                                            }
                                        }
                                        onSeek?(max(0, absoluteTime))
                                    }
                                    .contextMenu {
                                        segmentContextMenu(for: segment)
                                    }
                                }
                                
                                // Phase 3.2: Visual "End of Project" Marker
                                VStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 2)
                                    Text("END")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 4)
                                }
                                .padding(.leading, 8)
                                .frame(width: 32)
                            }
                            // --- TRACK 3: VIBE MUSIC ---
                            if hasVibeMusic {
                                let trackWidth = max(0, totalDuration * pxPerSec)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color(red: 0.2, green: 0.6, blue: 0.8).opacity(0.8)) // CapCut audio blue
                                    .overlay(
                                        AudioWaveformVisualizer(width: trackWidth, height: 24)
                                    )
                                    .overlay(
                                        HStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 10, height: 10)
                                                .offset(x: 4, y: -2)
                                                .shadow(radius: 1)
                                            Spacer()
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 10, height: 10)
                                                .offset(x: -4, y: -2)
                                                .shadow(radius: 1)
                                        },
                                        alignment: .top
                                    )
                                    .overlay(
                                        HStack {
                                            Text("Vibe Music")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(4)
                                                .background(Color.black.opacity(0.4))
                                                .cornerRadius(4)
                                            Spacer()
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                    )
                                    .frame(width: trackWidth, height: 24)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .frame(width: dynamicWidth, alignment: .leading)
                        .offset(x: halfAnchor - (currentTime * pxPerSec)) // Absolute anchor unlinks from layout width
                        
                        // --- STATIC PLAYHEAD SCAFFOLDING ---
                        ZStack(alignment: .top) {
                            Rectangle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.8), radius: 2)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                            
                            // Top Anchor
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 2)
                                .offset(y: -4)
                            
                            // Bottom Anchor
                            VStack {
                                Spacer()
                                Image(systemName: "arrowtriangle.up.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.8), radius: 2)
                                    .offset(y: 4)
                            }
                        }
                        .offset(x: halfAnchor - 1)
                        .zIndex(500)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isDraggingPlayhead {
                                    isDraggingPlayhead = true
                                    dragStartTime = currentTime
                                    onScrubbingChanged?(true)
                                }
                                let deltaX = -(value.translation.width / pxPerSec)
                                let newTime = max(0, min(totalDuration, dragStartTime + deltaX))
                                currentTime = newTime
                                onSeek?(newTime)
                            }
                            .onEnded { _ in
                                isDraggingPlayhead = false
                                onScrubbingChanged?(false)
                            }
                    )
                    .clipped()
                // Pinch to Zoom
                .simultaneousGesture(
                    MagnificationGesture()
                        .updating($gestureZoomScale) { currentState, gestureState, _ in
                            gestureState = currentState
                        }
                        .onChanged { value in
                            withAnimation(.linear(duration: 0.1)) {
                                showZoomHUD = true
                            }
                            hudWorkItem?.cancel()
                            
                            let scale = baseTimelineScale * value
                            if scale <= minScale || scale >= maxScale {
                                if !hasHitZoomLimit {
                                    impactFeedback.impactOccurred(intensity: 1.0)
                                    hasHitZoomLimit = true
                                }
                            } else {
                                hasHitZoomLimit = false
                            }
                        }
                        .onEnded { value in
                            let newScale = baseTimelineScale * value
                            baseTimelineScale = min(maxScale, max(minScale, newScale))
                            hasHitZoomLimit = false
                            
                            let workItem = DispatchWorkItem {
                                withAnimation(.easeOut(duration: 0.5)) { showZoomHUD = false }
                            }
                            hudWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
                        }
                )
            }
            .frame(minHeight: 100, maxHeight: 200) // Gives vertical room dynamically for B-Roll + Video + Music
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .hfGlassmorphic(padding: 0, cornerRadius: DesignTokens.Radius.sm)
    }
    
    // MARK: - Trim Handle UI & Logic
    private func trimHandle(isLeft: Bool, segment: Binding<VideoSegment>, pxPerSec: CGFloat) -> some View {
        ZStack {
            // Invisible Hitbox Extender (44x44 minimum per Apple HIG via Phase 5.2)
            Color.white.opacity(0.001)
                .frame(width: 44, height: 44)
            
            // Visual Handle Wrap
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white)
                .frame(width: 14, height: 50)
                .overlay(
                    // 4x4 Anchor Guiding Line
                    VStack(spacing: 4) {
                        Rectangle().fill(Color.black.opacity(0.8)).frame(width: 2, height: 4).cornerRadius(1)
                        Rectangle().fill(Color.black.opacity(0.8)).frame(width: 2, height: 4).cornerRadius(1)
                        Rectangle().fill(Color.black.opacity(0.8)).frame(width: 2, height: 4).cornerRadius(1)
                    }
                )
                .shadow(radius: 2)
        }
        .contentShape(Rectangle()) // Confine gesture processing exactly to this explicit box
        .offset(x: isLeft ? -8 : 8)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        let delta = value.translation.width / pxPerSec
                        
                        if isLeft {
                            let newStart = max(0, segment.wrappedValue.startTrim + delta)
                            let currentEnd = segment.wrappedValue.endTrim ?? segment.wrappedValue.duration
                            if newStart < currentEnd - 0.2 {
                                segment.wrappedValue.startTrim = newStart
                                selectionFeedback.selectionChanged()
                            } else if newStart >= currentEnd - 0.2 {
                                // Magnetic overlap edge limit met
                                segment.wrappedValue.startTrim = currentEnd - 0.2
                                impactFeedback.impactOccurred(intensity: 0.6)
                            }
                        } else {
                            let newEnd = min(segment.wrappedValue.duration, (segment.wrappedValue.endTrim ?? segment.wrappedValue.duration) + delta)
                            if newEnd > segment.wrappedValue.startTrim + 0.2 {
                                segment.wrappedValue.endTrim = newEnd
                                selectionFeedback.selectionChanged()
                            } else if newEnd <= segment.wrappedValue.startTrim + 0.2 {
                                // Magnetic overlap edge limit met
                                segment.wrappedValue.endTrim = segment.wrappedValue.startTrim + 0.2
                                impactFeedback.impactOccurred(intensity: 0.6)
                            }
                        }
                    }
                    .onEnded { _ in
                        impactFeedback.impactOccurred()
                        onTrimEnded?()
                    }
            )
    }
    
    // MARK: - Context Menu Actions
    @ViewBuilder
    private func segmentContextMenu(for segment: VideoSegment) -> some View {
        Menu {
            Button("0.5x (Slow Motion)") { updateSpeed(for: segment.id, to: 0.5) }
            Button("1.0x (Normal)") { updateSpeed(for: segment.id, to: 1.0) }
            Button("1.5x (Fast)") { updateSpeed(for: segment.id, to: 1.5) }
            Button("2.0x (Turbo)") { updateSpeed(for: segment.id, to: 2.0) }
        } label: {
            Label("Playback Speed", systemImage: "timer")
        }
        
        Button {
            if segment.bRollRelativePath == nil {
                onRequestBRollPicker?(segment.id)
            } else {
                onRemoveBRoll?(segment.id)
            }
        } label: {
            Label(segment.bRollRelativePath == nil ? "Add B-Roll" : "Remove B-Roll", systemImage: "photo.on.rectangle")
        }
        
        Button(role: .destructive) {
            deleteSegment(segment)
        } label: {
            Label("Delete Segment", systemImage: "trash")
        }
        
        Button {
            duplicateSegment(id: segment.id)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
    }
    
    private func updateSpeed(for id: UUID, to speed: Double) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring) {
            segments[index].playbackSpeed = speed
            onTrimEnded?()
        }
    }
    
    private func deleteSegment(_ target: VideoSegment) {
        withAnimation(.spring) {
            segments.removeAll(where: { $0.id == target.id })
            if selectedSegmentID == target.id { selectedSegmentID = nil }
            onSegmentDeleted?(target)
            onTrimEnded?()
        }
    }
    
    private func duplicateSegment(id: UUID) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring) {
            let source = segments[index]
            let duplicate = VideoSegment(
                relativeVideoPath: source.relativeVideoPath,
                relativeThumbnailPath: source.relativeThumbnailPath,
                duration: source.duration,
                creationDate: source.creationDate,
                startTrim: source.startTrim,
                endTrim: source.endTrim,
                captionTokens: source.captionTokens,
                playbackSpeed: source.playbackSpeed,
                bRollRelativePath: source.bRollRelativePath
            )
            segments.insert(duplicate, at: index + 1)
            onTrimEnded?()
        }
    }
}

// MARK: - Subcomponents
fileprivate struct CaptionNodeScaffold: View {
    @Binding var token: CaptionToken
    let isSelected: Bool
    let isAnySelected: Bool
    let pxPerSec: CGFloat
    let segmentDuration: TimeInterval
    
    // For drag gesture deltas
    @State private var dragStartToken: CaptionToken? = nil
    
    var body: some View {
        let boxWidth = max(8, CGFloat(token.endTime - token.startTime) * pxPerSec)
        
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isSelected ? Color.orange : Color.orange.opacity(0.6))
                
            Text(token.text)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, 2)
                
            if isSelected {
                HStack(spacing: 0) {
                    // Left Handle
                    Rectangle().fill(Color.white).frame(width: 8).cornerRadius(2)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if dragStartToken == nil { dragStartToken = token }
                                    let deltaTime = value.translation.width / pxPerSec
                                    let newStart = max(0, dragStartToken!.startTime + deltaTime)
                                    if newStart < token.endTime - 0.1 {
                                        token.startTime = newStart
                                    }
                                }
                                .onEnded { _ in dragStartToken = nil }
                        )
                    Spacer()
                    // Right Handle
                    Rectangle().fill(Color.white).frame(width: 8).cornerRadius(2)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if dragStartToken == nil { dragStartToken = token }
                                    let deltaTime = value.translation.width / pxPerSec
                                    let newEnd = min(segmentDuration, dragStartToken!.endTime + deltaTime)
                                    if newEnd > token.startTime + 0.1 {
                                        token.endTime = newEnd
                                    }
                                }
                                .onEnded { _ in dragStartToken = nil }
                        )
                }
                .offset(y: 0)
            }
        }
        .frame(width: boxWidth, height: 18)
        // Center Body Drag for moving entire token
        .gesture(
             DragGesture()
                 .onChanged { value in
                     if dragStartToken == nil { dragStartToken = token }
                     let deltaTime = value.translation.width / pxPerSec
                     let duration = dragStartToken!.endTime - dragStartToken!.startTime
                     let newStart = max(0, dragStartToken!.startTime + deltaTime)
                     let newEnd = newStart + duration
                     if newEnd <= segmentDuration {
                         token.startTime = newStart
                         token.endTime = newEnd
                     } else {
                         token.endTime = segmentDuration
                         token.startTime = segmentDuration - duration
                     }
                 }
                 .onEnded { _ in dragStartToken = nil }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
        .shadow(color: isSelected ? Color.yellow.opacity(0.6) : Color.clear, radius: isSelected ? 4 : 0)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .opacity(isAnySelected ? (isSelected ? 1.0 : 0.4) : 1.0)
    }
}

// Phase 8.2 & Part 2 Async Thumbnail Loader
fileprivate struct VideoThumbnailStrip: View {
    let segment: VideoSegment
    let width: CGFloat
    
    @State private var thumbnails: [UIImage] = []
    @State private var loadedCount: Int = 0
    
    var body: some View {
        let expectedCount = max(1, Int(width / 40))
        
        HStack(spacing: 0) {
            if thumbnails.isEmpty {
                ForEach(0..<expectedCount, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .frame(width: max(0, width / CGFloat(expectedCount)))
                        .clipped()
                }
            } else {
                ForEach(0..<thumbnails.count, id: \.self) { index in
                    Image(uiImage: thumbnails[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(0, width / CGFloat(thumbnails.count)))
                        .clipped()
                        .animation(.none, value: thumbnails.count)
                }
            }
        }
        .task(id: width) {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = docDir.appendingPathComponent(segment.relativeVideoPath)
            
            if abs(loadedCount - expectedCount) > 2 || thumbnails.isEmpty {
                await loadThumbnails(from: url, expectedCount: expectedCount)
            }
        }
    }
    
    private func loadThumbnails(from url: URL, expectedCount: Int) async {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 80, height: 80)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        guard let durationObj = try? await asset.load(.duration) else { return }
        let duration = durationObj.seconds
        
        let start = segment.startTrim
        let end = segment.endTrim ?? duration
        let actualDuration = end - start
        
        guard actualDuration > 0 else { return }
        
        let interval = actualDuration / Double(expectedCount)
        var times: [NSValue] = []
        for i in 0..<expectedCount {
            let t = start + (interval * Double(i)) + (interval / 2)
            times.append(NSValue(time: CMTime(seconds: t, preferredTimescale: 600)))
        }
        
        var fetchedImages: [UIImage] = []
        let capturedCount = expectedCount
        generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
            if let cgImage = image, result == .succeeded {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    fetchedImages.append(uiImage)
                    if fetchedImages.count == capturedCount {
                        self.thumbnails = fetchedImages
                        self.loadedCount = capturedCount
                    }
                }
            }
        }
    }
}

// Phase 6 Audio Waveform
fileprivate struct AudioWaveformVisualizer: View {
    let width: CGFloat
    let height: CGFloat
    let density: CGFloat = 4.0 // pixels per sample

    var body: some View {
        Canvas { context, size in
            let sampleCount = Int(size.width / density)
            var path = Path()
            
            for i in 0..<sampleCount {
                let x = CGFloat(i) * density
                
                // Deterministic pseudo-random generation to simulate audio dynamics
                let seed = Double(i) * 0.1
                let pseudoRandom = abs(sin(seed * 12.3) * cos(seed * 4.5))
                
                let amplitudeBase = height * 0.2
                let amplitudeMod = height * 0.7 * pseudoRandom
                let dynamicHeight = amplitudeBase + amplitudeMod
                
                let yStart = (height - dynamicHeight) / 2
                path.move(to: CGPoint(x: x, y: yStart))
                path.addLine(to: CGPoint(x: x, y: yStart + dynamicHeight))
            }
            
            context.stroke(path, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: width, height: height)
        .clipped()
    }
}
