# Studio Canvas Export Re-Architecture Plan

## Assessment of the "Raw Dump" Crash
1. **The Core Crash Mechanism:** Right now, when you click the "Save" (Download) button directly inside the recording viewport, the app executes a hard, raw dump of the temporary `AVAssetWriter` `.mov` file straight into the iOS Photos library. Because these are raw, uncompressed internal camera chunks, they often lack proper flattening data or presentation profiles. iOS Photos frequently rejects these un-muxed files, which crashes the UI thread instantly.
2. **The Editor's Stability:** The reason it *doesn't* crash when you export from the Editor space is because the Editor passes everything through our custom `StitchingService` via `AVAssetExportSession`, which natively compresses, re-encodes, and flattens your segments into a perfectly standardized iOS format.

## Proposed Strategy: Engine Porting
To eliminate this crash permanently and provide a much richer flow, I agree completely with your intuition. We shouldn't dump raw settings. We must port the exact export engine from the Editor over to the Recording space!

**Execution Steps:**
1. **Remove Raw Dump:** I will strip the direct `saveToCameraRoll` trigger out of the "Save" button in `StudioControlsOverlay`.
2. **Port Export HUD:** I will bind the "Save" button to trigger the same exact `ExportSettingsView` modal that the Editor uses, allowing you to select your target Resolution and Framerate right there in the recording space.
3. **Port Stitching Render Pipeline:** I will inject the `isExporting` circular progress ring and the `StitchingService` engine directly into `StudioView`. When you tap Export, it will take your newly recorded clip, render it properly through AVFoundation, and securely deliver the finalized video to the Camera Roll cleanly!
