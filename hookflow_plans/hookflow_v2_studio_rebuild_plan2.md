# Ghost UI Minor Adjustments Plan

## Assessment of Remaining Issues
1. **Off-Center Record Button:** 
   *Diagnosis:* In the bottom HUD `HStack`, the left node (the Discard button) is bound to a frame width of `80px`, but the right node (Editor/Save buttons) takes up `140px`. Because the sides are uneven, the SwiftUI `Spacer()` pushes the main Record button slightly to the left.
   *Fix:* Give both the left and right outermost nodes an identical `frame(width: 140)` so that the Record button sits absolutely dead-center mathematically.

2. **White Text Blending into White Buttons:**
   *Diagnosis:* Before the camera starts rolling (when the buttons are still visible), the white teleprompter text scrolls directly underneath the white right-rail icons, making the text unreadable and visually muddy. 
   *Fix:* Inject a sleek, `.black.opacity(0.3)` capsule or rounded rectangle directly behind the vertical rail of buttons (`Flip`, `Flash`, `Script`, `Rewind`, `AA`). This creates a translucent "dock" for the tools, providing the perfect contrast separation so the text is cleanly readable when passing underneath it, without needing to change the default text color away from crisp white.

## Execution Checklist
- [ ] Edit `StudioControlsOverlay.swift` HUD layout: change the left node's `width` to `140` to match the right node and perfectly center the Record ring.
- [ ] Edit `StudioControlsOverlay.swift` Trailing Rail: add `.background(Capsule().fill(Color.black.opacity(0.3)))` and `.padding(.vertical, 16)` behind the vertical trailing `VStack` tools to create the separation panel.
