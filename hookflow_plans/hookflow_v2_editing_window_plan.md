# Comprehensive HookFlow V2 Editing Window Plan

This document outlines the 14-phase granular execution strategy for implementing professional-grade features into HookFlow V2.

## Execution Doctrine: The Rebuild Protocol
**Rule of Engagement**: We do **not** blindly append new features to the existing HookFlow V2 editing interface if the code is inefficient. Before executing any Phase, the active component is audited. If the underlying structure is rigid or memory-heavy, we will perform an **entire rework from scratch** for that feature. The goal is a structural foundation that is **300%-500% more efficient** than V1. Duct-taping new features to bad architecture is strictly prohibited.


---


## Phase 1: Core Engine & Timeline Magnification (Pinch-to-Zoom)

**Objective**: 
Implement a smooth, two-finger zooming interaction on the timeline screen so users can zoom in on specific frames of their video for precise editing, without causing the app to freeze.

**Market UX Standards**:
- **Works ✅**: Zooming in continuously without staggered steps. The timeline zooms directly where the user places their fingers (anchored to the playhead), and long videos perform just as well as short ones.
- **Doesn't Work ❌**: Snapping to predefined zoom sizes. Zooming from the very beginning of the video instead of the current timestamp. Slower devices freezing when a long video is zoomed out.

### Stage 1: State Management & Constants Initialization
- **Step 1.1**: Define absolute structural bounds (`minScale: 0.2` and `maxScale: 5.0`) on the parent timeline view.
- **Step 1.2**: Introduce `@GestureState private var gestureZoomScale: CGFloat = 1.0` to track live finger movement.
- **Step 1.3**: Build a dynamic `currentScale` evaluation function that multiplies the base scale by the active gesture state.

### Stage 2: Gesture Layer Implementation & Hit-Test Culling
- **Step 2.1**: Attach `.gesture(MagnificationGesture())` onto the timeline scroll container.
- **Step 2.2**: Bind `.updating($gestureZoomScale)` to intercept real-time pinch values.
- **Step 2.3**: Permanently mutate the `timelineScale` variable on the gesture's `.onEnded` callback.
- **Step 2.4**: Wrap `.onEnded` in spring animations for physical rubberbanding snap-backs when the limit is breached.

### Stage 3: UI Dimension Calculations
- **Step 3.1**: Bind structural frame `width` for Segments and B-Roll to a strict mathematical formula: `duration * basePxPerSec * currentScale`.
- **Step 3.2**: Update the gray canvas master container `width` property natively to match the sum of all segments.
- **Step 3.3**: Ensure placeholder views respect the same width formula as active video layers.

### Stage 4: Layout & Rendering Optimization (Memory Culling)
- **Step 4.1**: Refactor internal track arrays into strict `LazyHStack` elements so off-screen views are destroyed.
- **Step 4.2**: Wrap complex child blocks in lightweight unique `id` constraints to prevent unnecessary SwiftUI diffing.
- **Step 4.3**: Inject `.transaction { $0.animation = nil }` on the active pinch event to throttle iOS background animations.

### Stage 5: UX/UI Zoom Feedback Haptics
- **Step 5.1**: Build a temporary `Text(Zoom: %.1fx)` heads-up display (HUD) element.
- **Step 5.2**: Inject conditional fade-out `.opacity` logic so the HUD disappears 1 second after the user stops zooming.
- **Step 5.3**: Invoke a soft haptic rumble (`UIImpactFeedbackGenerator`) exactly when the user's pinch hits the 0.2x or 5.0x bounds.

### Stage 6: Playhead Centering & Anchor Physics
- **Step 6.1**: Capture the logical anchor using internal horizontal offsets relative to the central playhead needle.
- **Step 6.2**: Calculate the delta difference between the old scale and the new scale during the pinch.
- **Step 6.3**: Push an instantaneous horizontal coordinate shift matching the delta to trick the UI into anchoring on the needle.


---


## Phase 2: Advanced Track Mechanics (Snapping & Scrolling)

**Objective**: 
Ensure that dragging clips or scrolling the timeline feels natural and magnetically snaps to important edges (like the start of a new video clip), preventing sloppy or accidental overlapping cuts.

**Market UX Standards**:
- **Works ✅**: Swiping the timeline and having it naturally slow down and stop cleanly on the edge of a video clip. Allowing users to easily tap and move a small sticker sitting on top of a large video.
- **Doesn't Work ❌**: Infinite scrolling that has no friction. Tapping the screen to select a sticker, but the app mistakenly highlights the large video underneath it instead.

### Stage 1: Native Momentum Alignment
- **Step 1.1**: Append `.scrollTargetBehavior(.viewAligned)` dynamically to the timeline track boundaries.
- **Step 1.2**: Inject `#available(iOS 17)` checks to safely inject `.scrollTargetLayout()` inside the master track container.
- **Step 1.3**: Disable view-alignment specifically during an active drag or pinch to prevent scroll-fighting.

### Stage 2: Track Hierarchy Decoupling
- **Step 2.1**: Establish explicit `zIndex` sorting matrices to ensure secondary clips always hover cleanly over static primary clips.
- **Step 2.2**: Rebind `contentShape(Rectangle())` on all tracks to eliminate "dead zones" where taps fail to register.
- **Step 2.3**: Segregate touch priority: B-Roll gestures take complete precedence over Main Track gestures if both overlap.

### Stage 3: Dynamic Selection Elevation
- **Step 3.1**: Dynamically bind `.zIndex(isSelected ? 100 : 1)` on all interactive elements.
- **Step 3.2**: Intercept `.onDrag` to elevate the layer instantly so it does not ghost behind adjacent segments during movement.
- **Step 3.3**: Drop the layer back down to baseline upon release of the drag constraint.

### Stage 4: Pan vs. Pinch Conflict Resolution
- **Step 4.1**: Create a specialized `.exclusiveGesture` wrapper that actively listens for multiple touch points.
- **Step 4.2**: Prevent accidental horizontal timeline movements when the user's explicit intent is a vertical pinch to zoom.

### Stage 5: Magnetic Edge Snapping Physics
- **Step 5.1**: Evaluate horizontal movement offsets continuously during the `.onChanged` phase of a drag gesture.
- **Step 5.2**: If the trailing edge of the dragging clip falls within `5.0px` of an adjacent clip's leading edge, override the coordinate.
- **Step 5.3**: Snap the clip perfectly to the boundary and trigger a light haptic "snip" to validate the connection.


---


## Phase 3: Player Behaviors & Auto-Replay Intersections

**Objective**: 
Create a video player that automatically loops seamlessly when it reaches the end, and instantly updates its preview frame the absolute moment the user taps or scrubs the timeline.

**Market UX Standards**:
- **Works ✅**: Smooth, infinite video looping when playback hits the end of the project. Swiping the timeline aggressively results in an immediate frame update on the video player without delay.
- **Doesn't Work ❌**: The video stopping at the end and forcing the user to manually click a "Reset" arrow. Grabbing the timeline handle and seeing the preview frame lag 2 seconds behind.

### Stage 1: Boundary State Observation
- **Step 1.1**: Inject internal observers capturing `AVPlayerItemDidPlayToEndTime`.
- **Step 1.2**: Bind a forceful `player.seek(to: .zero)` instruction.
- **Step 1.3**: Re-trigger `.play()` immediately upon the seek resolving to simulate an infinite loop.

### Stage 2: Playback Status Synchronization
- **Step 2.1**: Monitor the internal player `timeControlStatus` precisely to the Play/Pause UI button.
- **Step 2.2**: Force a temporary `player.pause()` explicitly the absolute millisecond the user touches the timeline scrubber.
- **Step 2.3**: Prevent race conditions where the UI button shows "Pause" but the video is secretly still stopped.

### Stage 3: Memory Safe Buffering Control
- **Step 3.1**: Hook into `AVPlayerItem.preferredForwardBufferDuration` to limit redundant cache loading since our assets are primarily local to the device.
- **Step 3.2**: Enforce weak self references (`[weak self]`) inside all time-polling loops to eliminate memory leaks over long sessions.
- **Step 3.3**: Clear the playback buffer aggressively if the user places the app into the background state.

### Stage 4: Programmatic Playhead Snapping
- **Step 4.1**: Allow the user to tap on an arbitrary clip on the far side of the timeline and snap the global `player.seek` to that specific `CMTime` instantly.
- **Step 4.2**: Wrap the programmatic seek jumps with a `.debounce` filter to prevent `AVFoundation` API spamming.


---


## Phase 4: Teleprompter vs. Captioning Subsystems

**Objective**: 
Separate auto-generated captions from the teleprompter script, turning them into independent, draggable on-screen timeline objects that users can fully customize with fonts, colors, and timing handles.

**Market UX Standards**:
- **Works ✅**: Treating captions like physical stickers that can be dragged left or right. Allowing users to tap a poorly translated word and fix the spelling instantly holding its place on the screen.
- **Doesn't Work ❌**: Hard-baking captions prematurely into the video render so they cannot be tweaked. Tying captions strictly to the teleprompter speed, causing them to desync if the speaker talks faster than the prompter.

### Stage 1: Data Model Decoupling
- **Step 1.1**: Create an independent `CaptionSegment` data structure decoupled entirely from the original Teleprompter string.
- **Step 1.2**: Inject word-level parsing logic to break the spoken string into distinct subtitle blocks based on timing arrays.
- **Step 1.3**: Store these blocks securely in an isolated `.json` payload attached to the master project schema.

### Stage 2: Caption Node UI Assembly
- **Step 2.1**: Build `CaptionNodeView` as a draggable, horizontally-bounded component mapping precisely to a designated Caption Track on the timeline.
- **Step 2.2**: Render the actual text inside the node block so users can visually see what word is where.
- **Step 2.3**: Connect an `onTapGesture` text-editor override allowing users to rapidly fix spelling errors via a keyboard pop-up.

### Stage 3: Aesthetic Styling Controls
- **Step 3.1**: Build a sliding bottom panel presenting Font Selection, Text Color, Stroke Width, and Shadow Opacity toggles.
- **Step 3.2**: Abstract the design selections into a master `CaptionStyleConfig`.
- **Step 3.3**: Route the config parameters to the `AVVideoCompositionCoreAnimationTool` context during rendering playback.

### Stage 4: Drag and Drop Retiming
- **Step 4.1**: Bind physical left/right width extension drag handles explicitly to the Caption node.
- **Step 4.2**: Ensure that dragging a caption's width actively overwrites its `duration` and `startTime` properties without shifting adjacent captions on the timeline.

### Stage 5: Collision and Overflow Prevention
- **Step 5.1**: Implement boundary limits ensuring a caption node cannot physically be resized to overlap another caption block on the same timeline plane.
- **Step 5.2**: Inject mathematical evaluation to auto-scale font size dynamically if a word is physically too large to fit in the given video format aspect ratio.


---


## Phase 5: Granular UI Details & NLE Polish

**Objective**: 
Add professional polish to the editing interface, including highly visible timeline rulers, larger touch targets so users don't miss when trying to trim a clip, and smart action menus that only show relevant tools.

**Market UX Standards**:
- **Works ✅**: Dynamic visual rulers that adapt as you zoom in (showing 5-second marks, then 1-second marks). Thick, padded interaction zones so thumbs don't miss tiny handles. Contextual toolbars that change based on what you taped.
- **Doesn't Work ❌**: Static time markers that bunch up and overlap when zoomed out. Trim handles that are exactly 1 pixel wide. Static action toolbars showing grayed-out buttons that confuse the user.

### Stage 1: Visual Metronome (Timeline Rulers)
- **Step 1.1**: Implement a custom `Canvas` drawing matrix for 1-second and 5-second interval tick marks along the top edge of the timeline.
- **Step 1.2**: Feed the current zoom scale directly into the `Canvas` to recalculate and distribute the tick marks dynamically as the user pinches.
- **Step 1.3**: Fade out 1-second markers via opacity if they begin to physically overlap each other due to extreme zoom-outs.

### Stage 2: Handle Expansions (Touch Hitbox Optimization)
- **Step 2.1**: Expand the invisible hitboxes of all trim drag handles to a minimum of `44x44` pixels.
- **Step 2.2**: Draw a sharp 4x4 vertical anchor line physically inside the center of the invisible hitbox to guide the user's thumb.
- **Step 2.3**: Establish touch matrix priority so sliding a handle never accidentally triggers a general scroll gesture.

### Stage 3: Contextual Action Trays
- **Step 3.1**: Hide the global toolbar options (Import, Settings, Export) when a specific timeline clip is tapped.
- **Step 3.2**: Render a localized toolbar (Split, Replace, Adjust Volume, Delete) specifically linked directly to the selected segment.
- **Step 3.3**: Construct smooth `.transition(.move(edge: .bottom))` logic for seamlessly swapping out the active toolbars.

### Stage 4: Selection State Highlighting
- **Step 4.1**: Wrap actively selected timeline segments in a highly visible 2pt yellow glowing `.overlay` border.
- **Step 4.2**: Soften all unselected tracks via `.opacity(0.4)` dimming to establish immediate visual hierarchy on the active component.

### Stage 5: Tap Haptic Engine
- **Step 5.1**: Tie `UISelectionFeedbackGenerator()` into all primary selection taps to establish premium touch feel.
- **Step 5.2**: Inject a distinct heavier `UINotificationFeedbackGenerator(style: .success)` specifically when a clip is successfully sliced/split.


---


## Phase 6: Audio Engineering & Waveform Visualization

**Objective**: 
Analyze the sound from video clips and draw it as visual audio waves directly on the timeline, allowing users to trim exactly when someone begins speaking and giving them tools to fade volume levels perfectly.

**Market UX Standards**:
- **Works ✅**: Accurate visual rendering of audio loudness directly on the timeline block. Audio waveforms updating their visual shape when a user changes the volume slider.
- **Doesn't Work ❌**: Blind timeline trimming (forcing the user to guess where a word starts). Linear volume fading that sounds unnatural to the human ear.

### Stage 1: Audio Extraction Engine
- **Step 1.1**: Build an `AssetAudioReader` utilizing an active `AVAssetReaderTrackOutput` buffer.
- **Step 1.2**: Read physical PCM data frames and parse them into relative Root-Mean-Square (RMS) amplitude float arrays.
- **Step 1.3**: Downsample the mathematical array to match physical UI pixels (e.g. 100 samples per clip) to avoid UI overload.

### Stage 2: Waveform Rendering Cache
- **Step 2.1**: Map incoming float array amplitudes to a series of vertical bounds.
- **Step 2.2**: Flatten the arrays using native `Path { }` rendering logic and bind it into a `.drawingGroup()` to utilize the GPU, preventing CPU-strain from rendering 1000s of objects.
- **Step 2.3**: Tie the color of the waveform closely to the underlying segment type (e.g. Green for B-Roll, Blue for Primary).

### Stage 3: Audio Deck Controls
- **Step 3.1**: Build a 0 to 100% Volume slider attached to the context toolbar.
- **Step 3.2**: Feed independent volume state variables dynamically into the central `StitchingService`.
- **Step 3.3**: Bind them to the `AVMutableAudioMixInputParameters` to dictate output levels.

### Stage 4: Visual Audio Fades
- **Step 4.1**: Introduce interactive UI markers placed on the top trailing/leading corners of selected clips.
- **Step 4.2**: Allow users to drag the marker horizontally to apply a physical fade-in or fade-out zone.
- **Step 4.3**: Apply bezier-curve mathematical mappings so Audio fades logarithmically (natural sound) rather than linearly.

### Stage 5: Concurrent Extraction Safety
- **Step 5.1**: Dispatch all complex waveform generation jobs to `DispatchQueue.global(qos: .utility)` to never freeze the UI Main Thread.
- **Step 5.2**: Store generated waveform paths within a fast-access `NSCache` memory sink based on the Asset URL to instantly display visuals when reopening the timeline.


---


## Phase 7: The Undo/Redo Engine

**Objective**: 
Build a comprehensive safety net that records every structural edit made, allowing users to confidently undo or redo destructive actions to the timeline without permanently losing their hard work.

**Market UX Standards**:
- **Works ✅**: Hitting 'Undo' and watching an accidentally deleted video clip instantly reappear in its exact correct position with its trims intact.
- **Doesn't Work ❌**: Hard-destructive edits that force users to delete the entire project and start over if they accidentally trim the wrong clip boundary.

### Stage 1: State Snapshot Architecture
- **Step 1.1**: Create an `EditCommand` model defining an exact replica of the user's NLE Timeline payload (video arrays, captions, audio, current playhead time).
- **Step 1.2**: Instantiate a primary `historyStack` array to append new payload snapshots.

### Stage 2: User Input Catching
- **Step 2.1**: Inject silent `.append` snapshot catches at the precise moments when a user successfully releases a Drag handle or taps an execution button (Delete/Split).
- **Step 2.2**: Limit the historical stack count to `max(20)` total snapshots to prevent the application from bloating system memory during long editing sessions.

### Stage 3: Rollback Execution Mapping
- **Step 3.1**: Bind physical UI "Back/Forward" curvature arrows to `historyStack.popLast()` instructions.
- **Step 3.2**: Ensure popping an active state automatically pushes it into a secondary `redoStack` array.
- **Step 3.3**: Overwrite the active project data models entirely with the extracted snapshot data.

### Stage 4: State Garbage Collection
- **Step 4.1**: If the user performs an Undo, but then performs a *brand new action*, instantly purge the `redoStack` permanently.
- **Step 4.2**: Prevent logical anomalies or timeline breakage from jumping across split timelines mathematically.

### Stage 5: Immediate Playback Sync
- **Step 5.1**: Force an immediate trigger of `StitchingService.stitch()` upon successful rollback completion.
- **Step 5.2**: Reload the new AV data payload immediately so the user can see their undone changes visibly inside the preview screen.


---


## Phase 8: Asset Library & Media Swapping

**Objective**: 
Build an efficient local media browsing interface that lets users seamlessly swap placeholder video clips with real footage, while perfectly preserving the custom start/end trims of the original block.

**Market UX Standards**:
- **Works ✅**: Selecting a highly edited 2-second clip, pressing "Replace", picking a new 10-second video from the phone gallery, and having the timeline automatically slice the new video down to fit the perfect 2-second gap.
- **Doesn't Work ❌**: Replacing a meticulously timed clip, only for the new longer video to push the entire timeline completely out of sync by extending the duration boundary.

### Stage 1: Media Browser Setup
- **Step 1.1**: Implement an iOS standard `PhotosPicker` wrapper tailored for video validation.
- **Step 1.2**: Provide a fallback menu logic for extracting direct `.mp4` payloads from the device's Files schema in the event iCloud Photo references fail to resolve.

### Stage 2: The Constrained Swap Logic
- **Step 2.1**: Implement a precise "Replace Track" engine that targets the active Segment's UUID.
- **Step 2.2**: Replace the underlying video identity path, but actively copy the `duration` and target bounds applied from previous user trims.
- **Step 2.3**: Mathematically slice the incoming video so its new `endTime` matches the old block's physical length.

### Stage 3: Auto-Resolution and Aspect Validation
- **Step 3.1**: Intercept the incoming video URL and instantly parse its natural resolution.
- **Step 3.2**: Fire a contextual UI warning if a native 1:1 square video is attempting to replace a 9:16 vertical frame layout.

### Stage 4: Thumbnail Generation Matrix
- **Step 4.1**: Parse the new media timeline instantly upon selection to produce `CGImage` thumbnail strips for visual feedback on the timeline blocks.
- **Step 4.2**: Push the generation task to a background thread to prevent UI stalling, gradually fading the images into the clip boundaries as they finish rendering.


---


## Phase 9: Transitions & Keyframe Architecture

**Objective**: 
Give users the ability to add smooth, professional visual transitions (like cross-dissolves) between overlapping video clips, accompanied by an intuitive on-screen hit-button to configure them.

**Market UX Standards**:
- **Works ✅**: Tapping an intersection between two clips, picking "Fade", and instantly seeing the two clips fluidly blend into one another during playback.
- **Doesn't Work ❌**: Glitchy, abrupt jumps disguised as transitions. Transition menus that completely stutter the video player when you attempt to preview the overlap point.

### Stage 1: Intersection Node Injection
- **Step 1.1**: Inject a small, hovering hit-node block `(+)` directly onto the visual stitching intersection coordinate of two distinct sequences on the main track.
- **Step 1.2**: Tie the node into an Action Sheet overlay allowing selection of transition styles.
- **Step 1.3**: Append a custom `TransitionData` struct containing duration limits to the trailing edge of the first clip.

### Stage 2: Composition Duration Re-Mapping
- **Step 2.1**: When a transition is applied, recalculate the global timeline master duration.
- **Step 2.2**: Execute mathematical shifts since drawing a 1-second overlap physically steals `-0.5` seconds from BOTH clips.

### Stage 3: Smooth Interpolation Engine
- **Step 3.1**: Manipulate the `AVMutableVideoCompositionInstruction` loop directly inside the `StitchingService`.
- **Step 3.2**: Inject precise programmatic `opacity` ramping instructions over the transition boundary timeframe.
- **Step 3.3**: The timeline UI natively shifts the block graphics closer together to visually indicate clip overlap loss to the user.

### Stage 4: Duration Constraint Safety Check
- **Step 4.1**: Create preventative checks ensuring users cannot attempt to apply a 2-second transition over a 1-second physical video clip.
- **Step 4.2**: Forcefully clamp transition duration bounds statically to `min(clip.duration)` limits.


---


## Phase 10: Export Pipeline & Background Threading

**Objective**: 
Process and save the final edited video rapidly on a background thread while displaying a polished progress wheel, ensuring the user's interface remains highly responsive and never freezes.

**Market UX Standards**:
- **Works ✅**: An elegant progress ring showing exactly what percentage of the video is rendered, allowing the user to cancel the process safely if they change their mind.
- **Doesn't Work ❌**: Hard-locking the app's entire interface during an export. "Silent" rendering crashes that offer no explanation as to why the MP4 failed to save.

### Stage 1: Extreme Thread Segregation
- **Step 1.1**: Extract the compilation core and export execution command completely out of the UI Thread.
- **Step 1.2**: Explicitly bind the renderer to an independent `DispatchQueue.global(qos: .userInitiated)`.

### Stage 2: Export Progress View
- **Step 2.1**: Hook a native `Timer.publish` on a `0.1s` interval loop to actively poll floating point changes on `exportSession.progress`.
- **Step 2.2**: Feed the float into a heavily polished circular status ring overlay.
- **Step 2.3**: Expose an explicit "Cancel" hit zone bound to `exportSession.cancelExport()`.

### Stage 3: Destination Sink Configuration
- **Step 3.1**: Store the raw compiled MP4 physically in the device's local App Temporary Directory before passing it to the user.
- **Step 3.2**: Set up an active memory cleanup function that flushes leftover or failed export payloads automatically upon app-launch to prevent storage bloat.

### Stage 4: Native Share Sheet UI Wrap
- **Step 4.1**: Map successful rendering returns safely into the native iOS `UIActivityViewController` Share Sheet wrapper.
- **Step 4.2**: Prevent dismissing the loading circular overlay absolutely until the Share Sheet is explicitly confirmed active.

### Stage 5: Emergency Encoding Fallback Protocol
- **Step 5.1**: Identify if `AVAssetExportSession` fails sequentially due to an unhandled device memory panic constraint.
- **Step 5.2**: Build a secure fallback method utilizing `AVAssetWriter` block-by-block frame extraction if necessary.


---


## Phase 11: Color Grading & CoreImage Pipeline

**Objective**: 
Provide users the ability to perform basic color correction (adjusting brightness, contrast, and saturation) with real-time preview sliders that apply effects visually without lagging the entire editing suite.

**Market UX Standards**:
- **Works ✅**: Smooth, continuous slider handles mapping directly to vivid color changes on the preview frame without buffering pauses.
- **Doesn't Work ❌**: Destructive video compression rendering applied on every slider tick, causing the interface and video preview to physically lock up in real-time.

### Stage 1: UI Aesthetic Slider Integration
- **Step 1.1**: Build a dedicated Color Parameter menu consisting of horizontal continuous scale layout sliders targets (-100 to 100).
- **Step 1.2**: Bind the physical sliders with an inherent internal `.debounce(for: 0.1)` property. This prevents the `AVPlayer` rendering context from reloading 100 times a second while the user slides their finger aggressively.

### Stage 2: State Persistence Models
- **Step 2.1**: Map float values directly into a localized struct `ColorParams` attached explicitly inside `VideoSegment` profiles natively.
- **Step 2.2**: Allow explicit "Reset Custom Settings" capability tied back into baseline 0.0 floats.

### Stage 3: CIImage Mapping Framework
- **Step 3.1**: Extend the main composition pipeline by wrapping the `AVMutableVideoComposition` inside an optimized custom subclass conforming to `AVVideoCompositing`.
- **Step 3.2**: Programmatically attach precise `CIImage` context instructions specifically at runtime for passing parameters into `CIFilter.colorControls()`.

### Stage 4: GPU Resource Protection
- **Step 4.1**: Prevent highly destructive iterative memory faults by initiating a single centralized `CIContext()` variable tied natively into `MTLCreateSystemDefaultDevice()`.
- **Step 4.2**: Force the entire application to share the solitary image context across every frame rendered.


---


## Phase 12: Visual Effects (VFX) & Multi-Layer Overlays

**Objective**: 
Enable users to layer images, stickers, and secondary video feeds directly over their primary video, letting them drag and resize the assets visually on the preview screen.

**Market UX Standards**:
- **Works ✅**: Picture-in-Picture logic where tapping an image overlay brings up draggable corner hitboxes. It acts entirely independently of the global video layout.
- **Doesn't Work ❌**: Layers strictly attaching to a clip's boundaries so you can't have an overlay persist across a hard cut on the primary timeline track.

### Stage 1: Secondary Uncoupled Tracking Data
- **Step 1.1**: Create a master `[OverlayItem]` list fundamentally decoupled from the centralized primary `[VideoSegment]` spine pipeline.
- **Step 1.2**: Allow these overlapping overlays to maintain native timing durations completely disconnected from master timeline cut boundaries.

### Stage 2: Direct Interactive View Modifiers
- **Step 2.1**: Construct logic to allow users to translate `OverlayItem` boxes directly by sliding their fingers natively across the `VideoPlayerRepresentable` UI layer.
- **Step 2.2**: Use specialized geometry scale division mapping to accurately convert generic SwiftUI user screen touches deep into rigid 1080p target `renderSize` matrices.

### Stage 3: Isolated Timestamp Rendering Arrays
- **Step 3.1**: Pipe native `OverlayItem.startTime` boundaries safely into `StitchingService`.
- **Step 3.2**: Execute active bounds-checking during compilation so hidden off-screen elements do not continuously eat into standard hardware graphics bounds limits.

### Stage 4: Transform Matrix Manipulation
- **Step 4.1**: Build dedicated layout constraints applying mathematically calculated translations natively converting scale integers into raw `CGAffineTransform` inputs.


---


## Phase 13: Canvas Formatting & Watermarks

**Objective**: 
Give users simple toggles to change the global orientation of their video (TikTok vertical vs Instagram square), and apply persistent brand logos floating on top of all the timeline content.

**Market UX Standards**:
- **Works ✅**: Pressing a single layout toggle and watching the global video timeline smoothly center itself and inject black background padding intelligently to preserve content.
- **Doesn't Work ❌**: Hardcoded aspect ratios physically squishing actors in the video down, forcing users to undergo tedious manual re-cropping logic over every single clip.

### Stage 1: Project Canvas Control UI
- **Step 1.1**: Configure a highly accessible format options layout menu (9:16, 1:1, 16:9 ratios).
- **Step 1.2**: Intercept selection touches and force real-time scaling modifiers on the master `VideoPlayerRepresentable`.
- **Step 1.3**: **Canvas Centering Protocol**: Ensure that whenever the aspect ratio changes, the footage is explicitly centered to begin with. Eliminate any unpredictable or "weird" offsets, rigidly anchoring the video dead-center in the newly selected bounding box.

### Stage 2: Generative Padding Architecture
- **Step 2.1**: Bind modifications to the core `StitchingService` `renderSize` base structurally explicitly utilizing the active global array bounds value.
- **Step 2.2**: Integrate scale-to-fit mathematical mappings evaluating width vs height to automatically insert `.black` letterboxing elements seamlessly without stretching source pixels.

### Stage 3: Persistent Branding Hierarchy
- **Step 3.1**: Build explicit override injection points guaranteeing native `CALayer` layout overlays render exclusively *after* primary Letterboxing aspect shifts.
- **Step 3.2**: Tie static logo PNG assets tightly to coordinate corners globally independent of shifting timeframes.


---


## Phase 15: Primary Segment Canvas Transforms & Fluid Timeline Navigation

**Objective**: 
Allow users to directly interact with the primary video footage on the canvas to execute scale, pan, and rotate transformations (enabling easy visual sub jump-cuts), while drastically improving the fluidity and reliability of scrolling back and forth across the physical timeline UI.

**Market UX Standards**:
- **Works ✅**: Tapping a clip on the timeline, then pinching the main video preview directly to zoom in on an actor's face for a dramatic jump cut. Dragging left/right on the timeline cleanly and instantly without fighting vertical scroll gestures.
- **Doesn't Work ❌**: Only secondary overlays being scalable. Attempting to scroll the timeline horizontally but the app stutters or interprets the swipe as an invalid gesture.

### Stage 1: Segment Transform Data Model
- **Step 1.1**: Append strict layout properties (`scale`, `offsetX`, `offsetY`, `rotation`) natively into the `VideoSegment` struct model.
- **Step 1.2**: Ensure these values default cleanly (Scale 1.0, Offsets 0.0, Rotation 0.0) so untouched clips render neutrally.

### Stage 2: Canvas Hit-Testing & Direct Manipulation
- **Step 2.1**: Hook `MagnificationGesture`, `DragGesture`, and `RotationGesture` simultaneously onto the primary `VideoPlayerRepresentable` preview canvas.
- **Step 2.2**: Filter inputs to only apply mutations to the active *selected* `VideoSegment` at the current playhead.
- **Step 2.3**: Prevent conflicting gesture states by requiring explicit selection validation before arbitrary touches transform the underlying clip.

### Stage 3: AVFoundation Transform Wrapping
- **Step 3.1**: Intercept the target clip's `AVMutableVideoCompositionInstruction` inside `StitchingService`.
- **Step 3.2**: Compile the mathematical transformations converting user offset/scale values into a compounded `CGAffineTransform` applied safely to the composition layer.
- **Step 3.3**: Ensure the transformation accounts for the base canvas resolution boundaries so video doesn't skew unexpectedly.

### Stage 4: Enhanced Timeline Scroll Fluidity
- **Step 4.1**: Overhaul the primary `ScrollView` containing the timeline segments to ensure horizontal panning vectors completely dominate the interaction hierarchy.
- **Step 4.2**: Refine "press, click, and scroll" hit zones on the timeline to eliminate friction. Increase interactive deadzones for vertical jitter so users can drag sideways rapidly without accidental detaches.


## Phase 14: AI Export HUD & Intelligent Rendering Constraints

**Objective**: 
Construct an intelligent overview screen containing crucial export estimations (size, quality, framerate) allowing users to safely verify parameters prior to executing heavy rendering jobs.

**Market UX Standards**:
- **Works ✅**: Providing explicit visual cues that setting a video to 4K / 60 FPS is going to consume over 1 Gigabyte of storage space before the user commits to waiting 3 minutes for it to save.
- **Doesn't Work ❌**: A single opaque "Export" button containing zero user parameter configuration rights.

### Stage 1: Export Configuration Settings
- **Step 1.1**: Draw a cleanly animated popup `VStack` Action Sheet featuring segmented control toggles for target Resolutions (720, 1080, 4K) & target Frame Rates (24, 30, 60).
- **Step 1.2**: Pass layout selections to construct specialized preset string overrides evaluating the final render `presetName`.

### Stage 2: Real-time File Computation Engine
- **Step 2.1**: Incorporate global total timeline duration variables alongside the selected profile to actively parse potential data density outputs.
- **Step 2.2**: Display the resulting mathematical string (e.g. `Est. Output: ~185 MB`) visibly recalculating anytime the user swaps target dropdown selections.

### Stage 3: Hardware Verification Fallbacks
- **Step 3.1**: Execute native `AVAssetExportSession.allExportPresets()` calls validating `.isHEVCSupported` physical boundaries.
- **Step 3.2**: Forcefully restrict and lock out physical 4K dropdown boundaries explicitly preventing process panics on older hardware implementations lacking enough unified memory.

### Stage 4: Final Rendering Guardrails
- **Step 4.1**: Connect to iOS structural `FileManager` tracking system attributes evaluating the user's available physical device space.
- **Step 4.2**: Interrupt execution explicitly prior to launch via pop-up alerts if physical device storage is actively blocked from receiving the final MP4.
