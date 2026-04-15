# HookFlow V2 UI & UX Execution Checklist

This checklist breaks down the `HookFlow_V2_UI_and_UX_Plan.md` into highly granular, bite-sized tasks. These serve as save points and execution chunks to ensure maximum efficiency, isolation of problems, and rapid momentum.

## Phase 1: Studio Controls Overlay (UI Scaffold)
- [ ] **1.1 Architecture & ZStack Foundation**
  - [ ] Define `StudioControlsOverlay` view.
  - [ ] Wrap with `ZStack { }` and `.ignoresSafeArea()`.
  - [ ] Inject `@Binding var isRecording: Bool` and `let lastRecordedURL: URL?`.
  - [ ] Structure horizontal layout (Top HUD in VStack, Bottom HUD isolated with Spacer).
- [ ] **1.2 Top HUD Navigation Header**
  - [ ] Construct `HStack` container (`.padding(.horizontal, 24)`, `.padding(.top, 48)`).
  - [ ] Build "Close" and "Script" buttons.
  - [ ] Build "Editor" button (conditionally wrapped safely with `if lastRecordedURL != nil`).
  - [ ] Apply `.opacity(isRecording ? 0.0 : 1.0)` to header wrapper.
- [ ] **1.3 Bottom HUD Record Footer**
  - [ ] Construct nested `ZStack` anchored (`.padding(.bottom, 24)`).
  - [ ] Build static background ring (`.frame(width: 84, height: 84)`).
  - [ ] Build morphing foreground geometry (toggle between `68x68` and `36x36` based on `isRecording`).
- [ ] **1.4 Animation Pipeline**
  - [ ] Bind `isRecording` state toggle with `.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)`.

## Phase 2: Studio State & Camera Interactivity
- [ ] **2.1 View Properties & Hooks**
  - [ ] Inject `@State private var lastRecordedURL: URL?` into `StudioView`.
  - [ ] Wrap `StudioControlsOverlay` over the camera feed frame in `StudioView`.
- [ ] **2.2 Closure Execution Blocks**
  - [ ] Update Record button trigger to handle async closure: `Task { if let url = await captureService.stopRecording() { ... } }`.
  - [ ] Route the returned URL back to the MainActor safely to update `lastRecordedURL`.
- [ ] **2.3 Service API Modification**
  - [ ] Refactor `VideoCaptureService.stopRecording()` to `async -> URL?`.
  - [ ] Ensure `movieFileOutput` completes sandbox write before resolving termination continuation.

## Phase 3: Root App Routing & Onboarding Scaffold
- [ ] **3.1 Global Gatekeeper Initialization**
  - [ ] Inject `@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false` in `ContentView`.
- [ ] **3.2 Routing Switch Logic**
  - [ ] Apply `ZStack { if !hasCompletedOnboarding { OnboardingView() } else { AppRouterView() } }`.
  - [ ] Apply explicit opacity transitions between the two paths.
- [ ] **3.3 Onboarding Shell Construction**
  - [ ] Create `OnboardingView.swift`.
  - [ ] Use `TabView(selection: $currentStep)` without default dots, ignoring safe areas.

## Phase 4: Onboarding Components & Permissions Flow
- [ ] **4.1 The Identity Component (Tag 0)**
  - [ ] Build initial splash screen with `.black` / `.rounded` font, size 64, kerning 6.
  - [ ] Implement async auto-advance (`Task.sleep` for 2.5 seconds) to move to permissions gateway.
- [ ] **4.2 Permissions Gateway Construction (Tag 1)**
  - [ ] Layout `VStack(spacing: 32)` with camera and mic iconography.
  - [ ] Build button to trigger permissions check.
- [ ] **4.3 AVFoundation Logic Engine**
  - [ ] Pre-fetch `AVCaptureDevice.authorizationStatus(for: .video)`.
  - [ ] Handle 'denied' status gracefully (redirect user to Settings via `UIApplication.openSettingsURLString`).
- [ ] **4.4 Active Hardware Detached Check**
  - [ ] Wrap actual permission prompts (`requestAccess`) safely in `Task.detached { }` to prevent UI freezing.

## Phase 5: Dashboard Grid & Data Binding
- [ ] **5.1 Navigation Base**
  - [ ] Ensure dashboard utilizes `NavigationStack(path: $router.path)` mapped by AppRouter.
- [ ] **5.2 SwiftData Invocation & Query Maps**
  - [ ] Execute extraction: `@Query(sort: \HFProject.updatedAt, order: .reverse) private var projects: [HFProject]`.
- [ ] **5.3 Layout & Scrolling Mechanics**
  - [ ] Build `ScrollView` encapsulating a `LazyVGrid` for memory-strict performance.
  - [ ] Loop over models to map out `DraftCardComponent` placeholders.
- [ ] **5.4 Floating Action Button (FAB)**
  - [ ] Overlay hero create button at bottom center.
  - [ ] Build Capsule shape styled with `.hfAccent`.

## Phase 6: Draft Cards & Async Thumbnails
- [ ] **6.1 Card Dimensions & Layout**
  - [ ] Lock `DraftCardComponent` to 9:16 aspect ratio (`.aspectRatio(9/16, contentMode: .fill)`).
- [ ] **6.2 Thumbnail Extraction Engine**
  - [ ] Bound maximum extraction geometry (`generator.maximumSize = CGSize(width: 300, height: 300)`).
  - [ ] Extract thumbnail image in async `.task` block on card appearance.
- [ ] **6.3 Fallback & Deletion Sequences**
  - [ ] Bind row swipe/delete interaction.
  - [ ] Pop model immediately via `.delete()`. Sub-thread the file deletion via `StorageManager.shared.delete(id:)`.

## Phase 7: Editor UI Scaffold
- [ ] **7.1 View Structure Constraints**
  - [ ] Define root `ZStack(alignment: .center)` using `.ignoresSafeArea()`.
- [ ] **7.2 Background Video Binding**
  - [ ] Integrate lightweight `VideoPlayer` instance mapping `.allowsHitTesting(false)`.
- [ ] **7.3 The Control Overlay Layer**
  - [ ] Scaffold `VStack { Spacer(); GlassPanel { ... } }` directly over the video layer securely.
  - [ ] Implement `.ultraThinMaterial` backdrops.
- [ ] **7.4 Teleprompter Toggle Engine**
  - [ ] Conditionally render teleprompter text HUD layers via distinct `.transition(.asymmetric(...))` mappings to avoid layout tearing.

## Phase 8: Custom Scrubber & AVPlayer Sync
- [ ] **8.1 Memory Bounds Configuration**
  - [ ] Build track geometry leveraging `GeometryReader` around the track structure.
- [ ] **8.2 Clock Thread Observer**
  - [ ] Hook `player.addPeriodicTimeObserver(forInterval: 0.05, timescale: 600)`.
  - [ ] Map observer logic to UI position ratio in RAM safely.
- [ ] **8.3 Drag Gestures Math Translations**
  - [ ] Build custom `.gesture(DragGesture())` binding.
  - [ ] Rate-limit seek execution, pausing playback on drag, calculating geometry bounds securely.
- [ ] **8.4 Application Layer Termination Map**
  - [ ] Aggressively inject memory termination on exit (`.onDisappear { removeTimeObserver(); replaceCurrentItem(with: nil) }`).

## Phase 9: Trimming Physics & Time Boundaries
- [ ] **9.1 Constant Boundary Limits**
  - [ ] Establish logical dual boundaries `@State var startTrimRatio` and `@State var endTrimRatio` safely tracking isolated double offsets.
- [ ] **9.2 Marker Structural Coordinates**
  - [ ] Render dual white marker handles anchored explicitly left and right on track positions.
- [ ] **9.3 Minimum Scale Math Constraints**
  - [ ] Instate geometry guardrails forcing `startTrimRatio <= endTrimRatio - threshold` to intercept invalid logical overlaps securely in RAM.

## Phase 10: Export Pipeline & Post-Delivery Gateway
- [ ] **10.1 Rendering HUD Gate**
  - [ ] Attach `.disabled(isExporting)` blockades across active action targets.
  - [ ] Display an isolated, buttery-smooth loading foreground safely bounded.
- [ ] **10.2 AVFoundation Background Processing Map**
  - [ ] Execute actual file IO sequence `AVAssetExportSession` exclusively inside a `Task.detached` routine.
- [ ] **10.3 Post-Completion Export Trigger**
  - [ ] Spawn system `UIActivityViewController` sharing dialogue triggered by valid `session.outputURL` yields.
- [ ] **10.4 Dismiss Lockout**
  - [ ] Apply `.interactiveDismissDisabled(isExporting)` absolute wipeout ensuring uninterrupted render completion.

## Phase 11: Script Editor Modal
- [ ] **11.1 Presentation Structure**
  - [ ] Setup `TextEditor(text: $script.bodyText)` wrapped within a modular `.sheet` isolated constraint wrapper.
- [ ] **11.2 Modifier Maps**
  - [ ] Restrict visual boundaries padding with `.contentMargins(.all, 24)`.
- [ ] **11.3 Dynamic Focus Manipulation State**
  - [ ] Auto-summon text keyboard securely via `@FocusState` toggled instantly via `.onAppear`.
- [ ] **11.4 Toolbar Safety Bounds**
  - [ ] Construct custom escape `.toolbar { ToolbarItemGroup(placement: .keyboard) { Button("Done") } }` element strictly defined.

## Phase 12: Teleprompter Console & Settings
- [ ] **12.1 UserDefaults Logic Wrapping**
  - [ ] Establish system memory persistence with `@AppStorage("teleprompterSpeed") var speed: Double`.
- [ ] **12.2 Overlay Layout Controls**
  - [ ] Link parameter UI `Slider(...)` into physical teleprompter rendering engine safely overlaid to retain live feed contexts.

## Phase 13: Final Polish & Launch Assets
- [ ] **13.1 Vector Manifest Mapping**
  - [ ] Finalize AppIcon configurations securely locking 1024x1024 limits cleanly.
- [ ] **13.2 Render Sequence Control**
  - [ ] Synchronize `LaunchScreen` definitions utilizing #000000 configurations minimizing UI jump tearing on application load execution maps.
- [ ] **13.3 Root Theme Restriction**
  - [ ] Clamp global constraint to map exclusively via `.preferredColorScheme(.dark)` across main `ContentView`.

## Phase 14: Pending UI Flaws & Bug Fixes (Logged from Review)
- [ ] **14.1 Launch Screen Typography & Layout**
  - [ ] Investigate "HookFlow" title wrapping issue on initial launch.
  - [ ] Scale down font size slightly to fit the full word smoothly on one line; prevent stray letters from wrapping to the next line.
- [ ] **14.2 User Profile Screen Symmetry**
  - [ ] Rebalance the layout containing the Profile picture, "Welcome back", "Intelligence Engine", "New Profile", etc.
  - [ ] Vertically stack these elements symmetrically so the screen looks balanced.
- [ ] **14.3 Onboarding Paywall & Pricing Structure**
  - [ ] Set up and inject a Pricing / Paywall view within the Onboarding sequence.
  - [ ] Implement a 2 or 3 tier pricing structure.
  - [ ] Include a CTA for a "7 days free trial" offer.
- [ ] **14.4 Recording Mode HUD Repositioning (Mobile Optimization)**
  - [ ] Fix unoptimized spacing/anchoring for buttons in Recording mode.
  - [ ] Relocate buttons from halfway up the screen to proper bottom HUD bounds.
  - [ ] Ensure full screen space is utilized without elements getting cropped off.
