# HookFlow V2 Editing Window UI Checklist

This checklist isolates the *UI and UX specific* components from the `hookflow_v2_editing_window_plan.md`. It provides a granular task list focused entirely on layout, interactions, visual feedback, and interface scaffolding, deferring deep AVFoundation plumbing to later phases.

## Phase 0: The Rebuild Protocol (Execution Doctrine)
- [ ] **0.1 Pre-Execution Audit**
  - [ ] Before touching any existing component, audit its current efficiency and structure.
- [ ] **0.2 Zero Duct-Tape Policy**
  - [ ] Do **not** blindly append new features to existing code if it is inefficient. 
  - [ ] Completely *rebuild the specific component from scratch* if the underlying structure is rigid, ensuring it is 300%-500% more efficient than what would result from patching it.

## Phase 1: Core Engine & Timeline Magnification (UI)
- [x] **1.1 Timeline Container Bounds**
  - [x] Wrap the master track container in an overarching `scrollTargetBehavior` context.
  - [x] Define generic `minScale: 0.2` and `maxScale: 5.0` variables on the scope.
- [x] **1.2 Zoom Gesture Implementation**
  - [x] Inject `@GestureState private var gestureZoomScale` and `MagnificationGesture()`.
  - [x] Implement `currentScale` dynamic multiplier computation.
- [x] **1.3 Dynamic UI Dimensions**
  - [x] Apply physical `width` mappings (`duration * basePxPerSec * currentScale`) to segment blocks.
  - [x] Ensure placeholder and actual view structural frames update seamlessly.
- [x] **1.4 UI Zoom Feedback (HUD & Haptics)**
  - [x] Create a `Text(Zoom: %.1fx)` heads-up display overlay.
  - [x] Program 1-second `.opacity` fade out for the HUD.
  - [x] Trigger `.impactOccurred()` on boundary hits (0.2x and 5.0x).

## Phase 2: Advanced Track Mechanics (UI)
- [x] **2.1 Hierarchy & Hitboxes**
  - [x] Standardize `zIndex` across B-Roll vs Main tracks.
  - [x] Apply `.contentShape(Rectangle())` to fix dead tap zones.
- [x] **2.2 Selection Elevation Effect**
  - [x] Bind `.zIndex(isSelected ? 100 : 1)` on clip items.
  - [x] Add slight visual lift (shadow/scale) during `.onDrag`.
- [x] **2.3 Edge Snapping Feedback**
  - [x] Implement haptic "snip" triggered structurally during drag boundary overlaps.

## Phase 3: Player Behaviors (UI)
- [x] **3.1 Scrubber Sync State**
  - [x] Wire the timeline drag to immediately override the Play/Pause button UI to "Pause".
- [x] **3.2 Playback Boundaries**
  - [x] Build visual "End of Project" markers on the timeline UI.
  - [x] Map programmatic `.seek` snaps to timeline clip taps.

## Phase 4: Teleprompter vs. Captioning (UI)
- [x] **4.1 Caption Node Layer**
  - [x] Build `CaptionNodeView` as a draggable track object mapping to text.
  - [ ] Hook `onTapGesture` to summon the keyboard text-editor override.
- [x] **4.2 Styling Control Panel**
  - [x] Build sliding bottom sheet for Font, Color, Stroke Width, and Shadow handles.
- [x] **4.3 Direct Handles & Collision Limits**
  - [x] Append explicit left/right bounding drag expansion tabs on the node wrapper.

## Phase 5: Granular NLE Polish (UI)
- [x] **5.1 Visual Metronome Rulers**
  - [x] Utilize `Canvas` to draw 1s and 5s tick marks.
  - [x] Tie canvas spacing directly to the dynamic `currentScale`.
- [x] **5.2 Hitbox Optimization**
  - [x] Expand physical trim handle interactable areas to `44x44` minimum.
  - [x] Draw a central 4x4 visual physical anchor guiding line.
- [x] **5.3 Contextual Action Trays**
  - [x] Map state to swap out Global Toolbar with specific action toolbars (Split, Replace, Volume, Delete) instantly on tap.
  - [x] Attach `.transition(.move(edge: .bottom))` to contextual bar swapping.
- [x] **5.4 Glowing Selection State**
  - [x] Bind a 2pt yellow `.overlay` border exclusively onto the actively selected clip.
  - [x] Map generic `.opacity(0.4)` muting across unselected layers.

## Phase 6: Audio Engineering (UI)
- [x] **6.1 Waveform Dummy Generation**
  - [x] Create mock `Path` structures plotting generic visual amplitudes for UI layout validation.
  - [x] Theme waveforms dynamically (e.g., Green B-Roll, Blue Primary).
- [x] **6.2 Audio Deck Sliders**
  - [x] Render 0-100% Volume slider inside the Contextual Toolbar.
- [ ] **6.3 Visual Audio Fades**
  - [ ] Attach visual interactive UI markers in top corners of clips.
  - [ ] Overlay a bezier fade mapping gradient path when marker is dragged inward.

## Phase 7: Undo/Redo Engine (UI)
- [x] **7.1 Header Interface Construction**
  - [x] Implement physical UI Back/Forward curvature arrows in the top navigation region.
  - [x] Map active greyed-out visual states if rollback stacks are technically empty.

## Phase 8: Asset Library & Layout (UI)
- [x] **8.1 Media Swap Accessor**
  - [x] Connect the "Replace" toolbar button to a local `PhotosPicker` dialog constraint.
- [x] **8.2 Thumbnail Generation UI Strip**
  - [x] Lay out dummy placeholder images along the `width` of the timeline block, applying fades upon load resolution.

## Phase 9: Transitions Engine (UI)
- [x] **9.1 Intersection Node (+) Injection**
  - [x] Calculate and display the `(+)` hit-node overlay between primary segments.
- [x] **9.2 Style Action Sheet**
  - [x] Design the selection overlay for "Cross Dissolve", "Fade to Black", etc.
- [x] **9.3 Overlap Clip Rendering**
  - [x] Build UX representation of timeline blocks visually sliding together to account for transition time consumption.

## Phase 10 & 14: Export HUD & Quality Overlays (UI)
- [x] **10.1 AI Configurations Overlay**
  - [x] Display segmented choices (720, 1080, 4k / 24, 30, 60 FPS).
  - [x] Auto-calculate and display "Est. Output: ~X MB" text label.
- [x] **10.2 Progress Ring Interface**
  - [x] Build the circular progress visual with animated stroke paths.
  - [x] Encase within `.ultraThinMaterial` background to block active app states.
  - [x] Highlight a massive recognizable "Cancel" boundary.

## Phase 11: Color Grading (UI)
- [x] **11.1 Sliders Architecture**
  - [x] Develop dedicated `-100 to 100` visual sliders for Brightness, Contrast, Saturation.
  - [x] Link explicit "Reset" text-button interaction target.

## Phase 12 & 13: VFX & Canvas Formatting (UI)
- [ ] **12.1 PiP Translation Hits**
  - [ ] Ensure picture-in-picture overlaps display corner scalar bounds when highlighted.
- [x] **12.2 Global Aspect Ratio Options**
  - [x] Create toggles in header/toolbar to change active canvas (9:16, 1:1, 16:9).
  - [x] Represent `.black` boundaries shifting on the primary preview dynamically.
