# HookFlow V2 Teleprompter Implementation Checklist

> **Objective:** To track the execution of the 9-Phase Teleprompter Plan flawlessly, ensuring that performance constraints (Rebuild Protocol) and UI safety precautions are consistently enforced at every level. Check these off using `[x]` as we successfully finish testing each step natively.

---

### Phase 1: Preemptive Complication Prevention (UI Reliability)
- [x] **Stage 1: The Dummy Build-Out (Visual Anchors)**
  - [x] Step 1.1: Initialize static SwiftUI bounds using hyper-visible contrast colors.
  - [x] Step 1.2: Inject massive 5000+ word dummy strings to explicitly test horizontal overflow, multiline wrapping.
  - [x] Step 1.3: Implement a boolean `debugShowBounds` toggle to rapidly switch between the dummy layout and the real transparent UI.
  - [x] Step 1.4: Render absolute position overlays mapping exact `GeometryReader` coordinate spaces.
- [x] **Stage 2: Z-Index & Layer Resolution**
  - [x] Step 2.1: Establish a global enum for `ZIndexProtocols` (Camera=0, Gradient=1, Text=2, UI_Controls=3, BottomSheet=4).
  - [x] Step 2.2: Apply explicit `.zIndex()` modifiers to every distinct view component.
  - [x] Step 2.3: Inject `.ignoresSafeArea(.keyboard)` explicitly on the camera layer.
  - [x] Step 2.4: Perform manual stack tests simulating sudden keyboard activations.
- [x] **Stage 3: Hit-Testing & Gesture Isolation**
  - [x] Step 3.1: Define `.contentShape(Rectangle())` explicitly on all invisible padding zones surrounding interactive buttons.
  - [x] Step 3.2: Isolate native ScrollView gestures from custom slider logic using `.simultaneousGesture` intercepts.
  - [x] Step 3.3: Verify dragging a settings slider does not accidentally trigger the scroll physics.
  - [x] Step 3.4: Ensure tapping the camera "focus" area explicitly avoids any hidden bounds of the teleprompter read frame.
- [x] **Stage 4: Layout Constraints & Device Responsiveness**
  - [x] Step 4.1: Launch simulator tests actively cycling from iPhone SE minimums to Pro Max maximum scale thresholds.
  - [x] Step 4.2: Verify hardware orientation locks by setting `UIInterfaceOrientationMask.portrait` globally.
  - [x] Step 4.3: Anchor floating action buttons (Record, Mirror, Settings) to rigid bottom anchors that scale mathematically across screen heights.
- [x] **Stage 5: State Decoupling Pre-flight**
  - [x] Step 5.1: Audit pure UI components to ensure bindings don't force parent-level `body` re-evaluations continuously.
  - [x] Step 5.2: Inject `@Observable` view models strictly designated for UI logic.
  - [x] Step 5.3: Extrapolate the live camera preview block into an explicitly isolated `UIViewRepresentable` wrapper.
  - [x] Step 5.4: Run SwiftUI Instruments physically monitoring view-tree updates.

### Phase 2: UI Principles & Aesthetic Guidelines
- [x] **Stage 1: Typography & Contrast Matrix**
  - [x] Step 1.1: Adopt heavy, rounded font families via `.system(.rounded, design: .rounded)`.
  - [x] Step 1.2: Implement mandatory `.shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)` across all active text.
  - [x] Step 1.3: Provide user-customizable text foreground colors (White, Yellow, Neon Green).
  - [x] Step 1.4: Define extreme Kerning/Tracking rules dynamically widening letter spacing.
- [x] **Stage 2: Native Material & Overlays**
  - [x] Step 2.1: Utilize native `Material.ultraThinMaterial` across the settings console.
  - [x] Step 2.2: Implement high-radius `.clipShape(RoundedRectangle(cornerRadius: 24))` across all floating module containers.
  - [x] Step 2.3: Hardcode `.allowsHitTesting(false)` on pure visual overlay masks.
- [x] **Stage 3: Gradient Fades & Visual Hierarchy**
  - [x] Step 3.1: Instantiate `LinearGradient` logic spanning vertically across the scrolling view.
  - [x] Step 3.2: Set the visual focus indicator at the top 20% mark, fading linearly from 100% to 0%.
  - [x] Step 3.3: Anchor the "Reading Indicator" color accent mechanically aligned to the 100% gradient origin point.
  - [x] Step 3.4: Hook the visual indicator to the global branding colors (HookFlow premium tones).
- [x] **Stage 4: Environment Context Adaptability**
  - [x] Step 4.1: Override the environment natively using `.preferredColorScheme(.dark)` locally.
  - [x] Step 4.2: Prevent iOS from auto-switching text to pure black during light-mode system detection.
  - [x] Step 4.3: Ensure dark-mode enforcement applies to child modules for continuous continuity.

### Phase 3: Core Engine & Position State Management
- [x] **Stage 1: Scroll Offset Decoupling (Architecture)**
  - [x] Step 1.1: Deprecate logic relying entirely on `@State` frame padding shifts.
  - [x] Step 1.2: Construct a deterministic logic loop instantiating a localized `CADisplayLink`.
  - [x] Step 1.3: Store `currentYOffset` in a dedicated `@Observable` class `TeleprompterEngine` decoupled from the UI.
  - [x] Step 1.4: When pause fires, explicitly invalidate the `CADisplayLink` memory holding `currentYOffset` intact globally.
- [x] **Stage 2: Rendering Performance & Constraints**
  - [x] Step 2.1: Wrap the main scrolling `Text` container in a static `.drawingGroup()` forcing Metal GPU acceleration.
  - [x] Step 2.2: Utilize explicit `.offset(y: engine.currentYOffset)` bypassing internal `ScrollView` coordinate recalculations.
  - [ ] Step 2.3: Structure the data payload rendering only explicit `AttributedString` chunks.
  - [ ] Step 2.4: Profile memory usage verifying scrolling speeds at Level 10 do not drop CPU cycles below bounds.
- [x] **Stage 3: Intentional Restart Logic (UX)**
  - [x] Step 3.1: Build a dedicated "Rewind to Top" icon mapped directly to resetting `teleprompterEngine.currentYOffset = 0`.
  - [x] Step 3.2: Hook into the `isRecording` observer firing a 3-second animated UI countdown.
  - [x] Step 3.3: Suspend the `CADisplayLink` from firing until the exact frame the countdown resolves.
  - [x] Step 3.4: Integrate a soft-start interpolation algorithm slowly ramping the scroll speed.
- [x] **Stage 4: Hardware Recording Synchronization**
  - [x] Step 4.1: Bind the teleprompter loop explicitly via `Combine` publishers to the `AVCaptureSession` physical write-state.
  - [x] Step 4.2: Prevent the teleprompter from advancing if the camera hardware fails to lock initial focus or allocate storage limits.
  - [x] Step 4.3: Integrate `ScenePhase` observers terminating both the camera writer and `CADisplayLink` cleanly.
- [x] **Stage 5: Live Gesture Interruption (Manual Override)**
  - [x] Step 5.1: Hook a `DragGesture()` observer specifically targeting the active text layer natively detecting human touch.
  - [x] Step 5.2: Halt the display link loop instantaneously the moment an explicit finger drag delta is registered.
  - [x] Step 5.3: Translate the user's physical drag translation directly into `TeleprompterEngine.currentYOffset` dynamically.
  - [x] Step 5.4: Await explicit user instruction before re-initializing the display link velocity sequence.

### Phase 4: Eye-line Alignment & UI Positioning
- [x] **Stage 1: Geometry-Anchored Reading Zones**
  - [x] Step 1.1: Initialize `GeometryReader` around the absolute screen container.
  - [x] Step 1.2: Calculate the exact Y-bounds for the top 20% to 35% frame.
  - [x] Step 1.3: Build the "Eye-line Marker" UI component rendering horizontally parallel to the front-facing camera lens.
  - [x] Step 1.4: Lock the starting Y-offset of the text block mathematically aligned to this exact marker.
- [x] **Stage 2: Gradient Transparency Culling**
  - [x] Step 2.1: Implement a vertical `.mask(LinearGradient(...))` physically containing the entire text rendering block.
  - [x] Step 2.2: Define explicitly smooth color stops `[.clear, .black, .clear]`.
  - [x] Step 2.3: Prevent reading fatigue by maintaining 100% opacity precisely where the user is focused and rapidly dropping to 0%.
  - [x] Step 2.4: Run visual tests across multi-line paragraphs ensuring word tails do not awkwardly clip against the gradient map.
- [x] **Stage 3: Safe Area Collision & Notch Avoidance**
  - [x] Step 3.1: Dynamically extract `safeAreaInsets.top` inside the geometry configuration.
  - [x] Step 3.2: Add explicit padding offsets compensating for devices with the deeper Dynamic Island cutouts locally.
  - [x] Step 3.3: Assure the topmost fade logic mathematically sits completely underneath the physical bezel notch.
  - [x] Step 3.4: Build physical layout preview permutations against older iPhone generations preventing text-clipping.
- [x] **Stage 4: Camera Field-of-View Hardware Offsets**
  - [x] Step 4.1: Analyze the physical X-axis front-facing camera lens position natively (usually right-centered).
  - [x] Step 4.2: Shift the primary reading zone horizontally via `.offset(x:)` guiding the user slightly off-center.
  - [x] Step 4.3: Prevent horizontal text lines from extending widely to the edges guaranteeing their eye sweep radius remains tight.

### Phase 5: Advanced Settings & Customization
- [x] **Stage 1: The Settings Bottom-Sheet**
  - [x] Step 1.1: Build `TeleprompterSettingsConsole` layered strictly above the camera preview natively in the exact navigation stack.
  - [x] Step 1.2: Implement custom slider assets representing Speed, Font Size, and Margin Width manipulating `TeleprompterEngine`.
  - [x] Step 1.3: Structure the console using an interactive `.presentationDetents()` or custom drag-to-dismiss overlay wrapper.
  - [x] Step 1.4: Provide absolute minimum and maximum floating point bounds on the sliders avoiding engine crashes.
- [x] **Stage 2: Real-Time Debouncing & Physics**
  - [x] Step 2.1: Map slider inputs through `Combine` `.debounce(for: 0.1)` preventing millions of engine updates per interaction second.
  - [x] Step 2.2: Decouple the underlying `CADisplayLink` timing loop from localized variable reads dynamically matching state adjustments immediately.
  - [x] Step 2.3: Verify drag events across "Font Size" recalculate text wrapping bounding boxes synchronously without visually jittering on screen.
- [x] **Stage 3: Haptic Feedback Loops**
  - [x] Step 3.1: Integrate `UISelectionFeedbackGenerator().selectionChanged()` responding intelligently immediately as the slider ticks.
  - [x] Step 3.2: Generate `UINotificationFeedbackGenerator(type: .success)` dynamically when closing the settings confirming saving.
  - [x] Step 3.3: Ensure haptic events compile successfully across devices holding `hapticsEnabled` system safeguards mechanically avoiding background thread panics.
- [x] **Stage 4: Persistent Configuration & Context**
  - [x] Step 4.1: Create `AppStorage` logic wrapping the `Speed`, `FontSize`, and `Margin` user values securely.
  - [x] Step 4.2: Implement `onAppear` lifecycle parsing injecting persistent values into the Engine instantly bypassing default variable settings.
  - [x] Step 4.3: Store settings locally on a globally scoped singleton avoiding propagation latency when re-entering the prompter context repeatedly.
- [x] **Stage 5: Contextual Formatting Logic**
  - [x] Step 5.1: Develop interactive alignment controls rendering "Left", "Center", "Right" icons dynamically updating the `multilineTextAlignment` of the target string.
  - [x] Step 5.2: Attach the explicit `.padding(.horizontal, engine.marginValue)` dynamically responding to the Margin settings sliders actively isolating the active text boundary logic.
  - [x] Step 5.3: Ensure that shifting text alignment dynamically recalculates the visual bounding box smoothly without suddenly truncating word wrappings.
  - [x] Step 5.4: Introduce a specific "Line Spacing" control element allowing the presenter to physically pad out vertical space between dense paragraphs, actively easing cognitive reading load.
- [x] **Stage 6: The "Mirror Output" Protocol (Hardware Rig Compatibility)**
  - [x] Step 6.1: Inject a "Mirror Text" boolean toggle inside the settings console for users utilizing physical iPad beam-splitter teleprompter glass rigs.
  - [x] Step 6.2: Bind an explicit `.scaleEffect(x: -1, y: 1)` transformation specifically to the text reading layer natively.
  - [x] Step 6.3: Verify this mirrored rendering does not reverse internal layout bounding arrays negatively altering left-alignment reads.
  - [x] Step 6.4: Ensure the UI controls (Play, Pause, Settings) remain un-mirrored and fully interactive over the flipped text.

### Phase 6: Categorized Script Templates Engine
- [x] **Stage 1: The Taxonomy Data Architecture**
  - [x] Step 1.1: Architect `ScriptTemplate` protocol implementing unique UUIDs, localized `category` enums, and exact raw text arrays manually coded.
  - [x] Step 1.2: Establish structural schema isolating categories natively (e.g., "Business", "Social Media", "Educational").
  - [x] Step 1.3: Add visual metadata tags like `estimatedDuration` dynamically computing words-per-minute (WPM) assumptions natively into the schema payload.
  - [x] Step 1.4: Define exact arrays mapping the actual physical template lists.
- [x] **Stage 2: Visual Discovery UX Canvas**
  - [x] Step 2.1: Construct the `ScriptDiscoveryModal` wrapping a `LazyVGrid` and multiple horizontally swiping `ScrollView` collections locally.
  - [x] Step 2.2: Build reusable `TemplateCard` layouts applying specific visual icons indicating structural formats.
  - [x] Step 2.3: Implement immediate tap-to-expand preview functionality projecting the structure to the user without leaving the card context.
  - [x] Step 2.4: Attach `.buttonStyle(PlainButtonStyle())` explicitly to cards circumventing accidental row-rendering delays.
- [x] **Stage 3: Memory Safe Asynchronous Loading**
  - [x] Step 3.1: Refactor internal arrays preventing initialization of exact dense `rawContent` strings until explicitly requested by the UX cycle.
  - [x] Step 3.2: Offload massive text-block memory allocations to a `.global(qos: .userInitiated)` queue explicitly.
  - [x] Step 3.3: Ensure swiping rapidly between completely different category nodes sustains exactly 60FPS utilizing native lazy boundaries.
  - [x] Step 3.4: Cache localized rendered Template representations avoiding sequential layout recomputation delays entirely.
- [x] **Stage 4: Metadata Tagging & UI Badging**
  - [x] Step 4.1: Display visual badges referencing calculated "30 Sec", "60 Sec", "Long Form" tags using bright UI contrasting blocks.
  - [x] Step 4.2: Apply custom "Hook", "Story", "Call To Action" structural preview pills natively within the preview modal UI boundaries.
  - [x] Step 4.3: Integrate exact search bars or explicit category filtering buttons actively routing specific schema groups to the top hierarchy automatically.

### Phase 7: Custom Scripts & Group Management
- [x] **Stage 1: Active SwiftData Pipeline**
  - [x] Step 1.1: Architect `@Model class UserScriptGroup` mapping `id`, `name`, `creationDate`, and a relationship link natively against `@Relationship(deleteRule: .cascade) var scripts: [UserScript]`.
  - [x] Step 1.2: Build `@Model class UserScript` containing `id`, `title`, `content`, `lastEdited`, uniquely bound inside the container.
  - [x] Step 1.3: Initialize explicit `.modelContainer(for: ...)` injection locally against the core app lifecycle to prevent memory leakage bounds dynamically.
  - [x] Step 1.4: Define exact data migration schemas safeguarding against version mismatch faults actively upgrading internal relationships.
- [x] **Stage 2: CRUD Folder Interfaces**
  - [x] Step 2.1: Hook a standard "New Folder" `alert`-based UX capturing immediate `TextField` injections natively creating the SwiftData Group globally.
  - [x] Step 2.2: Parse empty-string prevention limits dynamically disallowing folder generation missing character bounds.
  - [x] Step 2.3: Map explicit "Swipe actions" exposing a `.destructive` "Delete" function physically verifying the action before wiping the memory schema natively.
  - [x] Step 2.4: Add custom list structures routing directly to a `NavigationLink` isolating the exact folder array context actively preserving system back tracking.
- [x] **Stage 3: Template Duplication System**
  - [x] Step 3.1: Build the programmatic bridge copying data arrays from static `ScriptTemplate` memory directly into the SwiftData `UserScript` allocation pipeline locally.
  - [x] Step 3.2: Execute explicit "Use Template" buttons that immediately save the result into a generic "My Scripts" folder safely.
  - [x] Step 3.3: Push the UI directly into the fully operative `ScriptEditorView` automatically post-save dynamically focusing the keyboard active state instantaneously.
  - [x] Step 3.4: Ensure duplicated records adopt explicit `isEditable = true` variables completely divorcing internal logic mapped from static default templates.
- [x] **Stage 4: Reordering & Organization Physics**
  - [x] Step 4.1: Configure explicit `.onMove(perform:)` callbacks mechanically mutating the `scripts` array mapping the order explicitly inside SwiftData records uniquely sorting by `orderIndex`.
  - [x] Step 4.2: Link long-press `contextMenu` functionality parsing native UI components extracting "Move to Folder" explicit commands instantly rendering a modal specifically returning absolute SwiftData Group selections safely mapping data blocks natively.
  - [x] Step 4.3: Create "Duplicate Script" context functions automating exact record cloning efficiently bypassing primary UI allocations natively storing exact metadata accurately locally.
  - [x] Step 4.4: Hook explicit `SwiftData` context `.save()` triggers directly at the physical tail end of the `.onMove` interaction ensuring sudden app closure does not violently revert custom structural ordering globally.

### Phase 8: Intelligent Script Editor & Instructional Text
- [x] **Stage 1: The Token Parsing Engine**
  - [x] Step 1.1: Define robust Regex configurations locally targeting explicitly `\[.*?\]` capturing exact boundary ranges mapped against character limits.
  - [x] Step 1.2: Establish structural token indexes separating the exact `String` natively into `RegularText` and `InstructionText` blocks immediately without mutating root variable limits natively bypassing array overlapping loops.
  - [x] Step 1.3: Execute exact edge-case logic mapping unclosed brackets `[Smile here...` explicitly disregarding them avoiding parsing logic panics immediately rendering safely.
  - [x] Step 1.4: Verify regex speed profiling avoiding blocking the main thread natively processing 10,000 character counts natively maintaining 60FPS.
- [x] **Stage 2: Rich Text Editor Rendering**
  - [x] Step 2.1: Refine `TeleprompterScriptEditorView` instantiating native `UITextView` integrations explicitly supporting native `NSAttributedString` formatting dynamically.
  - [x] Step 2.2: Override physical keystroke callbacks mapping to exact Regex loops rebuilding the entire `NSAttributedString` dynamically applying `.foregroundColor(.hookflowRed)` uniquely against instructional constraints natively within physical boundaries avoiding UI layout stutter loops.
  - [x] Step 2.3: Prevent physical cursor resets mechanically preserving absolute user position boundaries maintaining active insertion point arrays across memory recomputations accurately locally.
  - [x] Step 2.4: Attach real-time placeholder mechanics dynamically rendering "Start typing here..." efficiently circumventing blank string initialization logic mechanically rendering text securely locally.
- [x] **Stage 3: Live Teleprompter Muting Engine**
  - [x] Step 3.1: Feed the processed `NSAttributedString` locally bypassing standard `String` rendering natively onto the core teleprompter `CADisplayLink` bounds securely rendering precisely onto the actual prompt mechanism natively without recomputation delays inside the view model dynamically mapping format allocations safely inside memory boundaries natively accurately.
  - [x] Step 3.2: Execute localized `opacity` or specific visual color fades dimming the instructions aggressively natively forcing presenters explicitly dropping visual context against regular text structurally safely locally isolating performance mechanically.
  - [x] Step 3.3: Ensure physical line heights are preserved rendering the specific prompt visually accurately bypassing baseline scaling issues completely resolving variable text weights inherently locking safe limits dynamically correctly accurately natively.
  - [x] Step 3.4: Integrate a settings toggle "Hide Instructions During Recording"; if enabled, the parser physically extracts the `[ ]` blocks entirely from the visual render array specifically during play-mode ensuring a completely pristine reading plane natively.
- [x] **Stage 4: Character Layout Constraints & Safe Regions**
  - [x] Step 4.1: Hook a dynamically scaling `UIToolbar` wrapping explicit "Done" button arrays mapping inherently over global keyboards avoiding trapping the user physically securely ensuring exact navigation bounds.
  - [x] Step 4.2: Verify buffer capabilities physically preventing specific text strings explicitly scaling past absolute iOS limits bypassing OOM natively mechanically structurally accurately globally actively inherently.
  - [x] Step 4.3: Design explicit character count UI markers parsing current array totals mathematically validating script duration inherently natively locally perfectly accurately structurally inherently natively dynamically perfectly perfectly correctly.

### Phase 9: Universal UI Action & State Wiring (Precautionary Phase)
- [x] **Stage 1: The UI Button Matrix Audit**
  - [x] Step 1.1: Define a master ledger of all physical buttons required across the teleprompter.
  - [x] Step 1.2: Audit the live view hierarchy manually ensuring absolutely none of these critical buttons are hidden behind invisible `Spacer` elements.
  - [x] Step 1.3: Assign explicit `.accessibilityIdentifier("teleprompter_button_name")` tags to every single button ensuring they are explicitly tracked and verified during QA passes.
  - [x] Step 1.4: Visually render empty closure tests (`print("Button \(X) Tapped")`) on every button natively before attaching any core logic to computationally prove physical connectivity.
- [x] **Stage 2: Deep Environment Injection & Component Routing**
  - [x] Step 2.1: Audit the root-level `App` or parent `NavigationStack` ensuring the `@Observable TeleprompterEngine` is physically and correctly injected natively via `.environment()`.
  - [x] Step 2.2: Audit child views (Settings Console, Discovery Modal) ensuring they explicitly receive the exact same singleton engine, actively avoiding accidentally initializing a separate, duplicate engine which causes silent failures.
  - [x] Step 2.3: Verify explicit `.presentationDetents()` or `.sheet` closures are properly de-allocating memory and updating states when completely dismissed by the user.
  - [x] Step 2.4: Hard-test the "Exit" mechanism explicitly ensuring the user can physically back out to the main Studio window without stranding the global navigation stack.
- [x] **Stage 3: Live Hardware Action Firing & Safety Locks**
  - [x] Step 3.1: Physically hook the primary "Record" button uniquely to BOTH the physical `AVCaptureSession` recording state AND the teleprompter scrolling logic sequentially safely.
  - [x] Step 3.2: Hook the "Pause" button natively intercepting the recording stream safely and dynamically triggering the parallel `CADisplayLink` halt sequence.
  - [x] Step 3.3: Validate the "Rewind" button action inherently overwrites the physical Y-offset back to exactly 0 immediately, visually snapping the UI back natively.
  - [x] Step 3.4: Test concurrent edge-case states (e.g. attempting to press "Settings" while active recording is true) explicitly disabling `.disabled(isRecording)` or hiding conflicting buttons to securely lock the pipeline.
