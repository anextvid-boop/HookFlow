# HookFlow V2 - Master Execution Checklist

## Phase 1: Project Generation & Scaffolding (In Progress)
- [x] Repository Isolation (`v2-rebuild` branch created)
- [x] Project Generation (Xcode 15+ iOS App Template, iOS 17.0+ Target) - *Requires user to map Xcode target to directory*
- [x] Clean Gitignore Injection
- [x] Scaffold `/App` (HookFlowApp, AppRouter, DependencyRegistry)
- [x] Scaffold `/Entities` (HFProject, Script, VideoSegment)
- [x] Scaffold directory structure for `/Services`, `/Features`, `/DesignSystem`
- [x] Baseline Validation (Zero Warnings, Zero Errors in Xcode)

## Phase 2: The Data & Entity Layer
- [x] Explicitly mark `VideoSegment`, `RecordingQuality`, and `ExportSettings` as `: Sendable`.
- [x] Reconstruct SwiftData `HFProject` schema to strictly store relative string paths (No `Data` media blobs) to support unlimited drafts.
- [x] Architect a strict `Cascade` delete rule tying `Script` data directly to projects.
- [x] Implement `actor StorageManager` with **Draft Sandboxing**: dynamic directory routing forcing each draft into its own isolated bucket so projects never overwrite each other.
- [x] Implement isolated cache cleanup in `StorageManager` to purge temp files before/after recording.
- [x] Inject `ModelConfiguration(isStoredInMemoryOnly: false)` safely via `DependencyRegistry`.
- [x] Validation: Run dummy `HFProject` persistence tests and verify Memory Graph is clear of relations-leaks.

## Phase 3: The Deep Services Engine
- [x] Build `globalActor VideoCaptureActor` with a custom high-priority executor queue.
- [x] Define `AVCaptureSession` buffer lifecycle strictly within `VideoCaptureActor`.
- [x] Establish `AVAssetWriter` concurrent execution logic so writing chunks does not pause preview.
- [x] Implement `ThumbnailGenerationService` relying purely on `AVAssetImageGenerator` utilizing `.generateCGImagesAsynchronously`.
- [x] Implement `AVQueuePlayer` and `AVPlayerLooper` bindings for the Editor Timeline.
- [x] Validation: Run AVFoundation strict-concurrency warnings build check.

## Phase 4: The Design System (1000x Architecture)
- [x] Construct `DesignTokens.swift` implementing the absolute spacing grid (4px increments).
- [x] Abstract semantic `Color` extensions (e.g., `.hfSurface`, `.hfBackground`, `.hfAccent`).
- [x] Architect `Typography.swift` leveraging native `Font.custom` combined with `@ScaledMetric`.
- [x] Establish custom `ViewModifiers` for recurring glassmorphic treatments (`.ultraThinMaterial` overlay).

## Phase 5: Feature Modules & State Routing (Editor Safety Priority)
- [x] Architect the centralized `@Observable AppRouter` utilizing purely Enum-driven `NavigationPath` structures.
- [x] Bind strictly one active `OverlaySheet` and `FullScreenCover` logic to eliminate visual overlap bugs.
- [x] **StudioFeature Isolation:** Strip all state references off the camera hardware; map taps purely to background callbacks.
- [x] **EditorFeature Safeguards (CRITICAL):** 
    - [x] Decouple playback state from the physical video file. Bind timeline scrubbing exclusively to the JPEG thumbnail cache to prevent locking AVFoundation.
    - [x] Force exact native track boundary loading (`try await assetVideo.load(.timeRange)`) to permanently fix the `CMTimeRange` start-time crashes from V1.
    - [x] Render captions as a separated Z-Stack layer (or Canvas) sitting passively over the player so edits do not trigger heavy player `UIViewRepresentable` redraws.
    - [x] Mandate that every edit action (Trim, Delete, Reorder) operates on pure struct arrays in memory before triggering background service commits. No silent failures.
- [x] **ScriptFeature Isolation:** Bind keystrokes in the Teleprompter builder locally to prevent upstream navigation recalculations.
- [x] Validation: Tested aggressive scrubbing and editing loops natively. Editor dependencies resolved.

## Phase 6: The UI Reconstruction (Design Excellence)
- [x] Establish `Theme.swift` (strict spatial layout padding/radii) and `Typography.swift` (scaled metrics). (Partially Done via Design System)
- [x] **Dashboard Hub:** Fetch `HFProject` arrays asynchronously via `@Query(sort: \.creationDate, order: .reverse)`.
- [x] Introduce "Ambient Aura Lighting": heavily blurred radial gradients using the brand accent color behind scroll views.
- [x] Construct the "Glassmorphic Project Cards" using native `.ultraThinMaterial` and inner 1pt transparent gradient strokes.
- [x] Implement generic horizontal scrolling timeline bars mapped 1:1 with the playback engine in the Editor.
- [x] Execute programmatic "Neural Masking": Deploy `.ultraThinMaterial` opacity fades during moments of high background compute (e.g. lens transitions).

## Phase 7: Verification & Cutover
- [x] Run the Side-by-Side Application Stress Protocol (Record 4K + scroll teleprompter simultaneously) on physical silicon.
- [x] Build & Archive for TestFlight Sandbox validation (Checking RevenueCat paywalls and Privacy manifest strings).
- [x] Rename the `HOOKFLOW_V2.xcodeproj` to `HOOKFLOW.xcodeproj` using Xcode Refactoring.
- [x] Swap the directories completely and delete the legacy V1 `.git` history bloat if necessary.
- [x] The Final Compile: Verify Zero Errors, Zero Warnings, and ship.

## Phase 8: Pending UI Flaws & Bug Fixes (Logged from Review)
- [ ] Fix Launch Screen "HookFlow" title layout (prevent line wrapping, scale text to fit).
- [ ] Rebalance User Profile screen layout (stack elements symmetrically).
- [ ] Setup Paywall in Onboarding sequence (2-3 tiers + 7-day free trial).
- [ ] Fix Recording Mode mobile layout (re-anchor buttons, fix spacing, prevent cropping).
