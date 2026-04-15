# HookFlow V2 Studio - TikTok Layout Execution Checklist

## Phase 1: Ghost UI Bounds Lockdown
- [x] 1. Edit `StudioControlsOverlay.swift` to remove the horizontal `HStack` Top Navigation completely.
- [x] 2. Move `Close (xmark)` button to an isolated `.overlay(alignment: .topLeading)` wrapper so it sits strictly in the top-left corner.
- [x] 3. Create a Trailing Vertical Rail: Group Flip Camera, Flash, Script, Rewind, and Text Size tools into a sleek `VStack(spacing: 24)` using `.overlay(alignment: .trailing)` or safely tucked on the right edge.
- [x] 4. Edit `StudioControlsOverlay.swift` bottom HUD `.safeAreaInset(edge: .bottom)`. Simplify the container to: Discard (bottom-left), Record (centered), and Editor/Save (bottom-right).

## Phase 2: Teleprompter Safe Zone Isolation
- [x] 1. `.ignoresSafeArea()` has been removed from `LiveTeleprompterView` in `StudioView`.
- [x] 2. Excessive `0.8` screen percentage padding has been removed inside `LiveTeleprompterView` and replaced with standard vertical spacing, releasing the bounds to scroll fluidly.

## Phase 3: Final Verification
- [x] 1. Run full SwiftUI layout pipeline validation natively (`xcodebuild`) to guarantee no compilation errors. -> **BUILD SUCCEEDED**
