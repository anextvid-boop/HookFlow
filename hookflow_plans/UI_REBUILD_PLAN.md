# HookFlow V2: UI & UX Dressing Plan

The V2 Architecture (the "Ferrari Engine") is securely built. This master plan outlines the exact sequence for bringing back all the missing interface elements, buttons, and aesthetics from V1 (the "Chassis") without corrupting our new strict-concurrency performance.

---

## The Master Sequence

### [ ] Phase 1: The Studio Interface (The Camera Overlay)
We need to give you control back over the camera without interfering with the 120 FPS Ghost UI underneath.
- [ ] Create `StudioControlsOverlay.swift` (a transparent, floating overlay placed securely above the `CameraPreviewLayer`).
- [ ] Add the Start / Stop Recording Button and link it to `VideoCaptureService.toggleRecording()`.
- [ ] Add the Save Video Directly Button and link it to the App Sandbox/Photos.
- [ ] Add the Edit Menu Button and re-route it to `Route.editor(projectId)` using the `AppRouter`.

### [ ] Phase 2: The Core Onboarding Sequence
Establishing the first-launch premium feel that was stripped away.
- [ ] Create `OnboardingView.swift` implementing the Logo Ident, permissions requests (Camera, Mic), and basic flow.
- [ ] Implement an `@AppStorage("hasCompletedOnboarding")` flag inside `HOOKFLOWApp.swift` to ensure it targets fresh installations properly.

### [ ] Phase 3: Dashboard & Project Management Polish
Styling the hub where you create and select Drafts.
- [ ] Modify `DashboardView.swift` to evolve from a barebones list into a premium fluid layout.
- [ ] Apply `DesignTokens` (Glassmorphism, typography).
- [ ] Polish the "New Draft" button with drop-shadows, haptic feedback, and fluid routing.

### [ ] Phase 4: Editor Hook-ups
Styling the editing tools.
- [ ] Update `EditorView.swift` to apply `hfGlassmorphic` modifiers to the sliders and export options.
- [ ] Ensure seamless stitching commands function natively with the UI.

