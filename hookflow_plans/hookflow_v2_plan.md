# HOOKFLOW_V2: Master Implementation Plan

This document outlines the systematic, "bird's eye view" approach to completely rebuilding the `HOOKFLOW` application into a parallel `HOOKFLOW_V2` Xcode project. 

Our core objective is to achieve a **300% to 500% efficiency and stability improvement** by establishing a strict, compartmentalized architecture that leverages modern Swift Concurrency (Actors) and Feature-Driven scaffolding, while using the original V1 codebase strictly as a reference for mathematical logic and design tokens.

---

## 1. Phase 1: Project Generation & Scaffolding (Maximum Efficacy Plan)
**Goal:** Generate a pristine, highly-optimized baseline completely insulated from legacy constraints and "scaffolding fatigue". We are aiming for a zero-warning, fully configured shell before writing any logic. This phase will be executed with absolute precision to ensure the highest possible foundation.

### 1.1 Parallel Project Creation & Source Control Isolation
*Execution will be precise to guarantee no cross-contamination with V1, ensuring a flawless compilation environment.*
- [x] **Action - Repository Isolation:** Initialize a new branch (`v2-rebuild`) or use isolated staging to ensure `HOOKFLOW_V2` exists parallel to V1 without triggering mono-repo merge conflicts.
- [ ] **Action - Project Generation:** Create the project using the native Xcode 15+ iOS App template. 
  - **Organization Identifier:** `com.boldest` (or existing identifier).
  - **Interface:** SwiftUI. 
  - **Language:** Swift. 
  - **Storage:** None (We will manually inject `SwiftData` to prevent Xcode's boilerplate from dictating our architecture).
- [ ] **Action - Target Configuration:** Strictly peg the `IPHONEOS_DEPLOYMENT_TARGET` to **iOS 17.0**. This is non-negotiable as it guarantees native `@Observable` macro support and the modern `SwiftData` API, eliminating outdated `Combine` fallbacks.
- [x] **Action - Clean Gitignore:** Inject a flawless `.gitignore` specialized for Swift development. Ignore `.DS_Store`, `DerivedData`, `xcuserdata`, `.build`, and Swift Package Manager resolution caches.

### 1.2 Surgical Directory Injection & Architecture Scaffolding
*We will not rely on Xcode's flat hierarchy. We will execute exact terminal `mkdir` commands to build a strict, physical on-disk Feature-Driven Architecture that maps perfectly to the `.xcodeproj` groups.*
- [x] **Action - `/App` (The Brain):**
   - Create `HookFlowApp.swift`: The `@main` entry point. It will *only* contain the `WindowGroup` and inject the global `ModelContainer` and `AppRouter`.
   - Create `AppRouter.swift`: A strict `NavigationPath` wrapper ensuring views do not dictate global navigation manually.
   - Create `DependencyRegistry.swift`: A centralized factory to cleanly provide instances of our background Actors (Services) without messy singletons.
- [x] **Action - `/Entities` (The Data Schema):**
   - **Strict Rule:** Any file in this folder containing `import SwiftUI` will fail the build. It must solely import `Foundation` and `SwiftData`.
   - Scaffold the foundational schemas: `HFProject.swift`, `Script.swift`, `VideoSegment.swift`.
- [ ] **Action - `/Services` (The Concurrency Engines):**
   - **Strict Rule:** All services must be `actor` types or `final class` executing on Background Tasks. They will never block the Main Thread.
   - Scaffold `VideoRecordingService.swift` (AVFoundation hardware wrapper).
   - Scaffold `StitchingService.swift` (Background video merging).
   - Scaffold `CaptionService.swift` (Speech-to-text processing).
   - Scaffold `StorageManager.swift` (Disk I/O).
- [x] **Action - `/Features` (The Modular UI):**
   - Scaffold precise directories: `Studio/`, `Editor/`, `Dashboard/`, `Teleprompter/`. Each module houses its own Views and ViewModels locally, stopping app-wide spaghetti code.
- [ ] **Action - `/DesignSystem` (The Premium Polish):**
   - Scaffold `Theme.swift` (Global layout constants).
   - Scaffold `Colors+Extensions.swift` (Programmatic dynamic color tokens).
   - Scaffold `Typography.swift` (Scalable font protocols).

### 1.3 Dependency Optimization (Zero CocoaPods)
*We banish CocoaPods to guarantee lightning-fast build times. All dependencies go through Native SPM.*
- [ ] **Action:** Inject dependencies purely through Swift Package Manager (`File -> Add Package Dependencies...`).
- [ ] **Packages to Pre-Link:** Only essential, verified packages (e.g., RevenueCat for purchases, trusted Analytics SDKs). We will avoid heavy UI libraries to maintain pure control.

### 1.4 Absolute Environment & Security Configuration
*Ensuring the OS never silently blocks a process due to missing permissions.*
- [ ] **Action - App Entitlements:** Enable `Background Modes` gracefully for `Audio, AirPlay, and Picture in Picture`. This is critical so if the user minimizes the app during a 4K export, iOS doesn't kill the process.
- [ ] **Action - Info.plist Manifest:** Inject premium, human-readable privacy strings. iOS requires these or the camera will instantly crash on open.
  - `NSCameraUsageDescription`: "Capture cinematic, high-fidelity video directly in HookFlow Studio."
  - `NSMicrophoneUsageDescription`: "Record professional audio for automatic, precise captions."
  - `NSPhotoLibraryUsageDescription`: "Save your finalized masterpieces straight to your Camera Roll."
  - `NSSpeechRecognitionUsageDescription`: "Transcribe your voice into dynamic teleprompter scripts in real-time."

### 1.5 The Baseline Validation (Zero-Tolerance Policy)
*A project is only ready when it compiles perfectly. We do not accept "good enough" at the scaffolding stage.*
- [ ] **Action - Deep Clean Matrix:** Execute deep clean (`⇧⌘K`), clear DerivedData completely via terminal or Xcode.
- [ ] **Action - Build Execution:** Compile (`⌘B`) targeting an iOS 17+ Simulator (e.g., iPhone 15 Pro).
- [ ] **Action - The Audit:** Scan the Xcode Issue Navigator. We enforce a **Zero Warnings, Zero Errors** rule. If a warning exists (such as a swiftlint or unused variable warning), it must be resolved *before* proceeding to Phase 2.

**SAVE POINT:** We now possess a titanium-grade chassis. The architecture is perfectly compartmentalized. The compiler is lightning fast, zero warnings exist, and the OS permissions are locked in. The foundation is mathematically optimal and ready to receive the V1 logic.










---

## 2. Phase 2: The Data & Entity Layer (Maximum Efficacy Plan)
**Goal:** Establish a bulletproof, concurrent-safe data foundation using isolated `SwiftData` containers and `Sendable` value types. This ensures 100% thread safety and zero Main Thread blocking when reading/writing large video segments.

### 2.1 Struct & Value Type Consolidation (Sendable Compliance)
*We must ensure all data passed between background video processing and the UI is thread-safe.*
- [ ] **Action:** Port `VideoSegment`, `RecordingQuality`, `RecordingState`, `ExportSettings`.
- [ ] **Action:** Explicitly mark every single struct as `: Sendable`. If the compiler throws an error, refactor the struct until it is purely immutable or uses safe wrappers.
- [ ] **Action:** Strip away any V1 `@Published` or `ObservableObject` dependencies from these raw data types. They must be pure Swift structs.

### 2.2 SwiftData Schema Reconstruction & Infinite Draft Storage
*Moving away from any legacy CoreData or ambiguous property wrappers to pure modern SwiftData, with a strict ban on storing media blobs to guarantee users can create unlimited drafts without crashing.*
- [ ] **Action:** Define `@Model final class HFProject`. **Ban** the use of `Data` types for thumbnails or video. The database must remain microscopic. Store *only* relative `String` file paths (e.g., `/Documents/Project123/thumb.jpg`), and delegate actual file reading entirely to the `StorageManager` actor.
- [ ] **Action:** Define `@Model final class Script`. Create a strict `[Relationship(deleteRule: .cascade)]` ensuring when a project is deleted, the script metadata is purged instantaneously.
- [ ] **Action:** Define an explicit `Schema` version (e.g., `Schema(version: 1, models: [HFProject.self, Script.self])`) so we are ready for future App Store migrations without user data loss.

### 2.3 The Isolated StorageManager Actor (Multiple Draft Safety)
*Disk I/O is the #1 cause of dropped frames, and improper pathing corrupts overlapping drafts. We fix this completely.*
- [ ] **Action:** Create `actor StorageManager`. 
- [ ] **Action:** **Draft Sandboxing:** Implement secure document directory routing that forces *each unique project* into its own isolated directory bucket (e.g., `/Documents/ProjectID_123/`). This guarantees users can actively edit 50 different drafts simultaneously without a single video frame accidentally overwriting another draft's data.
- [ ] **Action:** Implement isolated cache cleanup: `func purgeTemporaryFiles() async throws`. This runs silently before a recording session starts and after an export finishes to keep iPhone storage light, ensuring users have disk space to start new drafts.

### 2.4 Decoupled ModelContainer Injection
*The UI will never instantiate the database directly.*
- [ ] **Action:** In `/App/DependencyRegistry.swift`, configure the exact `ModelContainer` and `ModelConfiguration`.
- [ ] **Action:** Inject the `ModelContainer` exclusively via the `.modelContainer(for: ...)` modifier at the root `HookFlowApp.swift` level.
- [ ] **Action:** Add a `isStoredInMemoryOnly: true` toggle ready for instant Unit Testing without destroying live V1 disk data.

### 2.5 Validation Checkpoint
*Data must be proven perfect before the UI is allowed to touch it.*
- [ ] **Action:** Write a temporary `StorageManager` test function in `HookFlowApp` to instantiate dummy `HFProject` items, save to disk, and retrieve them back natively on a background thread.
- [ ] **Action:** Build and observe the Memory Graph to ensure no retain cycles exist with the SwiftData relations.

**SAVE POINT:** The SwiftData engine is completely assembled. Data writes occur asynchronously without ever freezing the UI, and large model assets are stored exactly as `Sendable` types.










---

## 3. Phase 3: The Deep Services Engine (Maximum Efficacy Plan)
**Goal:** Deconstruct V1's bottleneck engines (AVFoundation handling) and rebuild them purely in modern Swift Concurrency. This is the explicit engine room where the 300%–500% performance increase is realized. Thread stalling and dropped frames become mathematically impossible.

### 3.1 Advanced `VideoRecordingService` & Memory Pooling
*V1 suffered from memory churn and UI locks due to manual `DispatchQueue` structures. We eliminate this entirely.*
- [ ] **Action:** Create `globalActor VideoCaptureActor` utilizing a strict **Custom Executor** mapped to a high-priority dispatch queue. Audio/Video tasks must jump the line ahead of standard OS background operations.
- [ ] **Action:** Enforce a strict **`CVPixelBufferPool`**. Instead of allocating new RAM for every single 4K frame captured, recycle a fixed pool of memory addresses. This drops memory allocation churn to near 0% during active recording.
- [ ] **Action:** Isolate Lens Switching. Changing lenses natively stutters hardware (`session.beginConfiguration()`). We execute this in the Actor, exposing only an `isSwitchingLenses` boolean to the UI to trigger a cinematic crossfade.

### 3.2 The GPU-Accelerated `StitchingService` & Export Masking
*Exporting 4K clips via CPU is incredibly slow, and direct camera-roll saving in V1 caused fatal UI deadlocks. We fix both.*
- [ ] **Action:** Encapsulate `AVMutableComposition` logic inside a completely isolated `Task`.
- [ ] **Action:** Force hardware acceleration. Mandate that any scaling, filtering, or stitching uses `CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)`. Forcing the Metal pipeline drops computation times drastically.
- [ ] **Action:** Mandate HEVC Encoding. Final video writes must use `AVVideoCodecKey: AVVideoCodecType.hevc` with `.hw` acceleration flags to slash final file sizes while maintaining pristine quality.
- [ ] **Action:** **V1 BUG FIX (Camera Roll Crash):** Execute `PHPhotoLibrary.shared().performChanges` strictly inside a background actor. The UI must only render a decoupled "Saving..." overlay, removing any possibility of the main thread stalling and crashing the app during a direct save.
- [ ] **Action:** Parallelize track processing using concurrent `TaskGroup` arrays, streaming progress back to the UI via an `AsyncStream<Double>`.

### 3.3 The Fast-Scrub `ThumbnailGenerationService`
*Scrubbing 4K video natively destroys UI frame rates. We bypass the video file entirely during timeline interaction.*
- [ ] **Action:** Create an asynchronous `ThumbnailGenerationService` that executes silently the moment a recording stops.
- [ ] **Action:** Extract and cache ultra-low-res JPEG frames. When a user scrubs the timeline, they are flipping through cached image arrays instantly instead of uncompressing actual video, guaranteeing 120 FPS editor fluidity.

### 3.4 The Teleprompter `CaptionService` Decoupling
*Timestamp math and continuous speech recognition require constant CPU cycling.*
- [ ] **Action:** Re-implement `SFSpeechRecognizer` mathematically completely off the UI domain. 
- [ ] **Action:** Calculate Word-Per-Minute (WPM) and auto-scroll speed intervals rigorously within this service. 
- [ ] **Action:** Expose only single data points (like `currentScrollSpeed` or `highlightedWordIndex`) via a designated `MainActor` safe-wrapper. This enables flawless 120Hz smooth scrolling on ProMotion displays.

### 3.5 Deep Verification (Xcode Instruments Profile)
*We do not simply assume the performance is better; we prove it mathematically.*
- [ ] **Action:** Run the Xcode **Time Profiler** on a physical device. We explicitly verify that the Main Thread graph looks flat (empty) while a heavy recording or stitching session is running.
- [ ] **Action:** Run the Xcode **Allocations & Memory Leaks** instrument. Real-time video buffers (`CMSampleBuffer`) can leak fast. Ensure the memory graph purges flawlessly after every recording chunk is saved and cleared, prioritizing the `CVPixelBufferPool` lifecycle.

**SAVE POINT:** The AVFoundation engine executes flawless lens/microphone capturing, seamless heavy multi-track stitching, and speech logic behind the scenes, all with a proven, zero-impact flat-line on the Main Thread performance profile.










---

## 4. Phase 4: Feature Modules & State Routing (Maximum Efficacy Plan)
**Goal:** Completely eliminate the "God-ViewModel" anti-pattern and spaghetti navigation loops from V1. We will establish ultra-tight state boundaries using native `@Observable` macros and a strict `NavigationPath` hierarchy ensures views render at 120Hz without cascading invalidations.

### 4.1 The Centralized `AppRouter`
*V1's `AppState.swift` relied on scattered boolean flags (`isShowingStudio`, `showExport`), leading to overlapping sheets and memory leaks when dismissing. We eradicate this.*
- [ ] **Action:** Architect a global `@Observable final class AppRouter`.
- [ ] **Action:** Implement a pure `NavigationPath` stack for standard depth navigation.
- [ ] **Action:** Create strict Enums for presentation states: `enum AppRoute`, `enum FullScreenCover`, and `enum OverlaySheet` to guarantee only one isolated overlay can exist at any given time mathematically.
- [ ] **Action:** Inject the `AppRouter` directly at the `.environment()` root. Views simply declare `router.push(.studio)` or `router.dismiss()`, completely removing parent-to-child `@Binding` chains.

### 4.2 Deconstructing the `StudioFeature` ViewModel
*V1's CameraViewModel tracked hardware, UI, navigation, and script data simultaneously. We split this completely.*
- [ ] **Action:** Create `@Observable final class StudioFeature`. This class exclusively tracks local UI state (e.g., is the record button pressed, is the flash icon active).
- [ ] **Action:** Inject the isolated `VideoRecordingService` into this feature. The feature acts strictly as a middle-man, routing user taps instantly to the background service and updating its UI variables based on the service's callbacks.

### 4.3 The Non-Destructive `EditorFeature` (Strict Interaction Policy)
*Timeline scrolling must be buttery smooth, and unlike V1, button actions must not silently fail. We enforce absolute state feedback.*
- [ ] **Action:** Create `@Observable final class EditorFeature`.
- [ ] **Action:** Bind timeline scrub offsets strictly to the `ThumbnailGenerationService` cache. Moving the playhead interacts solely with RAM-cached JPEGs, never forcing AVFoundation to seek the raw 4K `.mov` file dynamically.
- [ ] **Action:** Overlay captions dynamically without triggering a complete redraw of the video preview player beneath it using `<Canvas>` or separated Z-stack layers.
- [ ] **Action:** **V1 BUG FIX (Dead Editor Actions):** Eradicate silent failure of timeline controls. Every action (Trim, Caption Edit, Save) must trigger an immediate, synchronous state mutation in `EditorFeature` that guarantees a pushed UI render or throws a visible debug alert. No action is permitted to "swallow" an intent.

### 4.4 The Teleprompter `ScriptFeature` Isolation
*Typing into a text editor should not reload the entire app screen.*
- [ ] **Action:** Create `@Observable final class ScriptFeature`.
- [ ] **Action:** Bind `TextField` typing events exclusively to this localized feature to prevent keystroke latency. Any heavy character-count processing or macro updates are dispatched asynchronously.

### 4.5 Validation Checkpoint (Instrumenting the UI)
*Proving the state does not leak.*
- [ ] **Action:** Open Xcode Instruments and launch the **SwiftUI Profiler**. 
- [ ] **Action:** Verify that typing locally in the Script Builder does not trigger unwanted body recalculations in the parent Home or Navigation views.
- [ ] **Action:** Trigger deep navigation (Home -> Studio -> Editor -> Export) and force-dismiss back to root. Check the memory graph to ensure 100% of the child ViewModels were immediately deallocated.

**SAVE POINT:** The application features exist logically. Navigational overlap is impossible by strict Enum design. Keystrokes, scrolls, and sheet transitions occur flawlessly at maximum frame rate with zero over-drawing.










---

## 5. Phase 5: The UI Reconstruction (Maximum Efficacy Plan)
**Goal:** Construct the visual exterior to match the exact premium specifications of V1 natively in SwiftUI for iOS 17+. We will rely purely on the underlying `StudioFeature`, `EditorFeature`, and `AppRouter` engines we built, ensuring the UI remains solely a reflection of state, completely untethered from data-processing logic.

### 5.1 The Master Design System (`/DesignSystem`)
*V1 had scattered color hexes and hardcoded font sizes. We move to a rigid, mathematical, and programmatic design system.*
- [ ] **Action:** Create `Theme.swift` to establish strict spatial constants (`Theme.padding.large`, `Theme.radius.corner`).
- [ ] **Action:** Architect `Typography.swift` leveraging native `Font.custom` combined with `@ScaledMetric` to guarantee that text scales fluidly with iOS Dynamic Type while maintaining pixel-perfect premium design proportions.
- [ ] **Action:** Establish custom `ViewModifiers` for recurring glassmorphic treatments. Create a strict `.ultraThinMaterial` overlay modifier for floating HUD elements, standardizing our blur intensity globally.

### 5.2 Dashboard & Drafts Hub (SwiftData Bound)
*The Home view must load instantaneously regardless of the number of heavy video projects stored on disk, allowing for endless multiple drafts.*
- [ ] **Action:** Use `@Query(sort: \.creationDate, order: .reverse)` to build the project feed, fetching metadata entirely on the background to prevent main-thread hitching upon initial launch.
- [ ] **Action:** **Draft State Separation:** Abstract the UI into isolated component files (`ProjectFeedCard`, `CreateProjectButton`). Draft thumbnails must load lazily from their isolated URL buckets via `StorageManager` so memory usage remains perfectly flat whether the user has 1 draft or 100 drafts.

### 5.3 Studio View (The Command Center)
*The camera recording interface requires absolute spatial certainty—preventing UI shifting when devices rotate or notches are considered.*
- [ ] **Action:** Reconstruct the `ZStack` hierarchy layering. Level 1: Clean video preview layer. Level 2: Safe-Area-ignoring darkened cinema bars. Level 3: Interactive controls. 
- [ ] **Action:** Bind purely to `StudioFeature`. When a user taps record, the UI merely animates to the "Active" state and trusts the `VideoRecordingService` is handling it. 
- [ ] **Action:** Re-inject the Teleprompter text overlay using clear, high-contrast drop-shadows to ensure readability against any background.

### 5.4 The Timeline Editor Engine
*Rebuilding the non-destructive visual timeline.*
- [ ] **Action:** Construct the multi-track layout. Implement a generic `ScrollView` restricted horizontally, binding the offset to drive the background video playback exactly 1:1.
- [ ] **Action:** Construct the Captions Editor UI. Ensure individual word editing triggers isolated state updates to avoid reloading the heavy video player sitting underneath.
- [ ] **Action:** Implement the "Export" modal presentation strictly through our `AppRouter`'s `OverlaySheet` enumeration to prevent stacking dual-exports visually.

### 5.5 Animation & Polish (The Neural Masking)
*If hardware latency (like heavy lens switching) occurs, we obscure it utilizing targeted motion.*
- [ ] **Action:** Implement explicit `withAnimation(.spring(response: 0.3, dampingFraction: 0.8))` constants to enforce uniform momentum scrolling across the entire app.
- [ ] **Action:** Whenever `StudioFeature.isSwitchingLenses` turns true, trigger a native `<Rectangle>().fill(.ultraThinMaterial)` crossfade to transition seamlessly without revealing hardware-stuttering behavior underneath.

**SAVE POINT:** The application looks, feels, and operates as intended at an elite benchmark. The engine is running, the chassis is bolted on, and the visual presentation is locked to 120 FPS. The "car has been built."










---

## 6. Phase 6: Verification & Cutover (Maximum Efficacy Plan)
**Goal:** Execute a flawless, surgical replacement of the V1 codebase. We will prove undeniable superiority in frame-rate, memory usage, and stability through strict physical device benchmarking before allowing V2 to officially assume the primary repository identity. 

### 6.1 The Side-by-Side Stress Test
*Simulators hide hardware constraints. True validation only happens on physical silicon.*
- [ ] **Action:** Deploy both `HOOKFLOW` (V1) and `HOOKFLOW_V2` to the same physical test device (e.g., iPhone 15 Pro). 
- [ ] **Action:** Execute the "Stress Protocol": Record a 3-minute 4K video while simultaneously scrolling a 200-word teleprompter at maximum speed, tapping the screen to focus rapidly.
- [ ] **Action:** Immediately trigger an export. V2 must not drop a single UI frame during export initialization, and the final metadata must be written instantaneously to the SwiftData database.

### 6.2 Pre-Cutover App Store Validation
*We must ensure Apple will accept the new architectural footprint without rejection.*
- [ ] **Action:** Archive V2 and upload to TestFlight as a completely separate test bundle.
- [ ] **Action:** Verify that all `Info.plist` privacy manifests pass automated App Store Connect processing without warnings regarding Missing Purpose Strings or deprecated API usage.
- [ ] **Action:** Validate the RevenueCat or IAP environment natively in the TestFlight sandbox before cutover.

### 6.3 The Repository Swap & Deletion
*A clean break is required. No legacy code will survive the migration.*
- [ ] **Action:** Create the ultimate commit: `git commit -m "End of Line V1"`.
- [ ] **Action:** Delete the entire original `HookFlow` directory (V1) from the filesystem. We do not keep "old files" around cluttering the repository.
- [ ] **Action:** Move the `HOOKFLOW_V2` contents precisely into the root path directory where the old project existed.

### 6.4 Project Identity Morphing
*V2 now becomes the canonical V1.*
- [ ] **Action:** Rename the `HOOKFLOW_V2.xcodeproj` simply to `HOOKFLOW.xcodeproj`. Use the native Xcode rename refactoring tool to catch nested target discrepancies. 
- [ ] **Action:** Update the `PRODUCT_BUNDLE_IDENTIFIER` to the exact original App Store live identifier.
- [ ] **Action:** Verify the final build pipeline. Run a deep clean (`⇧⌘K`), rebuild, and ensure the renamed project yields our established standard: **Zero Errors, Zero Warnings.**

**SAVE POINT:** The migration is mathematically complete. The legacy constraints have been atomized. `HookFlow V2` is now the sole, definitive application, and the ultimate `v2-rebuild` branch is merged into `main`. The era of high-performance architecture has begun.
