# Comprehensive HookFlow V2 Home Page Plan

This document outlines the granular execution strategy for transitioning from a basic Drafts list to a fully-featured, dynamic Home Page Hub. This serves as the structural blueprint for development.

## Execution Doctrine: Global Aesthetic & Functional Parity
**Rule of Engagement**: The Home Page is the very first interactive surface the user sees post-onboarding. It must retain the exact premium aesthetics (animated gradients, glassmorphism, heavy-weight typography) established in the onboarding flow. No default iOS UI aesthetics (like standard grey List backgrounds or default navigation bars) are allowed if they break immersion. 

---

## Phase 1: Core Shell & Navigation Engine (The Switch Tab)

**Objective**: Establish the foundation of the Home Hub by migrating away from a standard `NavigationView` stack to a custom, bottom-anchored tab bar that controls the primary state of the Left, Middle, and Right views.

### Stage 1: UI Tab Router Architecture
- **Step 1.1**: Define an `@Observable` `HomeRouterManager` responsible for managing the active view state (`.templateBuilder`, `.creationHub`, `.userProfile`).
- **Step 1.2**: Implement a custom pill-shaped bottom tab controller utilizing `Material.ultraThinMaterial`.
- **Step 1.3**: Assign explicit explicit dimensions and padding so the tab bar floats securely above the safe area, allowing the background gradient to pass underneath.
- **Step 1.4**: Inject spring animations (`.spring(response: 0.3, dampingFraction: 0.7)`) to handle transitions flawlessly between the selected modes.

### Stage 2: Dynamic Gradient Backgrounds
- **Step 2.1**: Implement a global background `<MeshGradient>` or `<LinearGradient>` loop that animates natively, utilizing the HookFlow brand colors (rich purples, blues).
- **Step 2.2**: Ensure this background is rendered on the lowest Z-Index (`ZIndex(0)`) behind all active tab views so that the environment feels contiguous and "alive" across all tabs.

### Stage 3: Hit-Testing & Safe Area Isolation
- **Step 3.1**: Explicitly pad the bottom of all scrollable content (like the Template Builder list) by exactly the height of the custom floating tab bar so layout clipping does not occur.
- **Step 3.2**: Utilize `.ignoresSafeArea(.keyboard)` explicitly, avoiding bottom-tab crush when the user opens the keyboard on the Profile tab.

---

## Phase 2: Left Hand Side (Template Builder)

**Objective**: Create a visually compelling list of pre-built script frameworks that the user can explore and launch instantly.

### Stage 1: Template Data Modeling
- **Step 1.1**: Define a `ScriptTemplate` struct containing metadata: `id`, `title`, `description`, `category` (e.g., "UGC", "Direct Response"), and the raw `bodyPath` (the script structural blueprint with bracketed variables like `[USER_NICHE]`).
- **Step 1.2**: Pre-load a distinct array of default, high-converting HookFlow script frameworks into the local Swift architecture.

### Stage 2: Aesthetic Card UI
- **Step 2.1**: Construct the `TemplateCardView` utilizing heavy `.system(.rounded)` typography for the titles.
- **Step 2.2**: Implement glassmorphism or high-contrast opaque cards (`cornerRadius: 16`, `.shadow(color: .black.opacity(0.1), radius: 8)`) for distinct interactable components.
- **Step 2.3**: Inject `.contentShape(Rectangle())` to guarantee massive hit-boxes across the cards for easy selection.

### Stage 3: Action Delegation
- **Step 3.1**: Wire the tap action on the template card to immediately pipe the template text into the `ScriptBuilder` or the newly defined pipeline.
- **Step 3.2**: Ensure pre-loading the variables from the logic established in Phase 4.

---

## Phase 3: Middle (The Creation Hub / Record Action)

**Objective**: Serve as the focal point of the application, driving users directly to the actual recording interface effortlessly.

### Stage 1: The Floating Action Core
- **Step 1.1**: Instead of functioning strictly as a tab, the Middle "Record" button acts as a primary Floating Action Button (FAB) nested securely within the central quadrant of the Tab Bar.
- **Step 1.2**: Apply high-contrast brand coloring to the Record button (e.g., `.hfAccent`) to distinguish it from the standard tab navigation icons.

### Stage 2: Micro-Animations & Interactivity
- **Step 2.1**: Implement a subtle "breathing" scale animation (`.scaleEffect` from `1.0` to `1.05`) acting as a visual magnet to draw the user's eye towards creation.
- **Step 2.2**: Implement `UIImpactFeedbackGenerator(style: .heavy).impactOccurred()` on tap for intense physical satisfying interaction.

### Stage 3: Direct Pipeline Bridge
- **Step 3.1**: Connect the Record action directly to an empty `ScriptSelection` or `TeleprompterStudio` initialization pipeline, seamlessly pushing into the editor environment.

---

## Phase 4: Right Hand Side (User Profile & Intelligence)

**Objective**: Build a structured control center where users insert persistent metadata (Niche, Business Name, etc.) that the app intelligently uses to auto-populate the templates from Phase 2.

### Stage 1: The Persistent Profile Schema
- **Step 1.1**: Utilize `@AppStorage` or a lightweight `UserProfileManager` (`@Observable`) to definitively store variables globally: `businessName`, `targetNiche`, `coreOffer`, `painPoints`.

### Stage 2: Seamless UI Forms
- **Step 2.1**: Build distinct, clean `TextField` layers wrapped in custom structural layouts. Avoid default `Form` lists if they look visually jarring against the app's aesthetic.
- **Step 2.2**: Use custom neon/accent colored cursors and text highlights to match brand identity during typing insertion.

### Stage 3: Auto-Population Pipeline
- **Step 3.1**: Build a universal string extension `String.applyProfileVariables(profile: UserProfile)` that parses through the raw `ScriptTemplate` models.
- **Step 3.2**: Execute `replacingOccurrences(of: "[USER_NICHE]", with: profile.targetNiche)` precisely to reconstruct the templates in real-time.
- **Step 3.3**: Ensure that if a user leaves a variable blank in their Profile, the engine elegantly handles the fallback (e.g., keeps the bracket or removes the sentence gracefully).

---

## Final Verification Gates
- **Gate 1**: Switching between tabs must NOT stall or stutter. State memory must be preserved (e.g., scrolling down the Template Builder, switching to Profile, then back, remembers scroll offset).
- **Gate 2**: Template instantiation accurately maps all global intelligent variables.
- **Gate 3**: Layout scales functionally down to 4-inch devices (SE) without bottom-tab text clash.
