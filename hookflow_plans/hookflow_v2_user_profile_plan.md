# Comprehensive HookFlow V2 User Profile Intelligence Plan

This document outlines the granular execution strategy for the Home Hub Right Tab (User Profile). Because the Template Builder relies implicitly on this data, the Profile serves as the direct intelligence backend for the entire application.

## Execution Doctrine
**Rule of Engagement**: Data entry on mobile is historically tedious. We must build a setting UI that does not look like standard iOS `Form` or `List` blocks. The Profile must feel premium, glassmorphic, and directly tied to the value of the templates they will unlock.

---

## Phase 1: Core Intelligence Architecture (Data Layer)

**Objective**: Establish lightning-fast data bindings to hold the user's business variables without forcing complex database schema migrations.

### Stage 1: Manager Singleton Integration
- **Step 1.1**: Define class `ProfileManager` observing `ObservableObject` protocol or utilize Swift's macro `@Observable`.
- **Step 1.2**: Inject the instantiated object into the overarching `App` entry point using `.environmentObject()`.
- **Step 1.3**: Map all internal class variables directly through the `@AppStorage` wrapper to guarantee persistent `UserDefaults` storage that survives application termination.

### Stage 2: Binding Specifications (Enhanced Commercial Parameters)
- **Step 2.1**: Define parameter `businessName: String` (e.g., "FitLife Pro").
- **Step 2.2**: Define parameter `industryNiche: String` (e.g., "B2B SaaS", "Fitness Coaching").
- **Step 2.3**: Define parameter `targetAudience: String` (e.g., "Busy moms", "Marketing executives").
- **Step 2.4**: Define parameter `customerPainPoint: String` (e.g., "No time to cook", "Low conversion rates").
- **Step 2.5**: Define parameter `coreOffer: String` (e.g., "14-Day Meal Plan", "AI Lead Conversion Tool").
- **Step 2.6**: Define parameter `brandTone: String` (e.g., "Professional", "Urgent & Hype", "Casual & Friendly").
- **Step 2.7**: Define parameter `primaryCallToAction: String` (e.g., "Click the link in bio", "Download the free guide").
*Note: Storing these extensive granular data points directly allows template and script AI to auto-populate content exponentially faster with rich context.*

### Stage 3: Default Nil Safety & Initialization
- **Step 3.1**: Initialize all variable defaults stringently with explicit empty strings `""` rather than Optionals `String?`. This prevents all downstream unwrap crashes when parsing into the Template Builder engine.
- **Step 3.2**: Write deterministic computed properties natively on the manager (e.g. `getNicheOrDefault()`) that evaluate `.isEmpty` and inject safe generic fallbacks like `"your audience"` instantly.

### Stage 4: Reset & Cache Overrides
- **Step 4.1**: Implement a global `func wipeProfile()` inside the manager for debug and pivot workflows.
- **Step 4.2**: Iterate through active properties and overwrite them strictly with `""`.
- **Step 4.3**: Bind this function securely to a destructive "Clear Dashboard" button located at the absolute bottom apex of the settings structure.

### Stage 5: Observable State Publishing
- **Step 5.1**: Ensure that modifications to the `@AppStorage` variables appropriately ping the `objectWillChange.send()` dispatcher if you are not using the `@Observable` macro to verify sub-views reload instantly.
- **Step 5.2**: Inject explicit `DispatchQueue.main.async` wrappers if background processes ever attempt to write to these profile parameters to prevent thread panics.

---

## Phase 2: Centralized UI & Glassmorphic Form Assembly

**Objective**: Ensure the entire profile layout (Avatar, Profile Switcher, Inputs) is structurally centered to provide a balanced, highly premium aesthetic, avoiding scattered UI elements.

### Stage 1: Reusable Aesthetic Containers
- **Step 1.1**: Create `struct ProfileInputFieldView: View` for massive layout reduction.
- **Step 1.2**: Require parameters `let title: String`, `let placeholder: String`, `let iconName: String`, and `@Binding var text: String`.
- **Step 1.3**: Wrap the resulting `TextField` strictly in a structural background calling `Material.ultraThinMaterial`.
- **Step 1.4**: Apply a subtle native `.shadow(color: .hfAccent.opacity(0.05), radius: 10)` to pull the input slightly off the background plane.

### Stage 2: View Vertical Stack Setup
- **Step 2.1**: In `UserProfileView.swift`, initialize a `ScrollView(.vertical, showsIndicators: false)` bounding the exact screen.
- **Step 2.2**: Encapsulate the scroll feed heavily inside a `VStack(spacing: DesignTokens.Spacing.xl)`.
- **Step 2.3**: Iterate and construct the 5 core `ProfileInputFieldView` instances sequentially downwards inside the stack.

### Stage 3: Structural Spacing Tokens
- **Step 3.1**: Explicitly constrain the ScrollView's internal side padding mathematically (`.padding(.horizontal, DesignTokens.Spacing.md)`) preventing inputs from touching horizontal bezels.
- **Step 3.2**: Inject semantic `Divider()` blocks padded with top and bottom spacing to visually segregate "Identity" params from "Marketing Focus" params.

### Stage 4: Safe-Area & Keyboard Avoidance
- **Step 4.1**: Globally configure `.ignoresSafeArea(.keyboard, edges: .bottom)` only if SwiftUI's internal iOS 17 engine begins conflicting with layout offsets.
- **Step 4.2**: Mandate a trailing `Spacer(minLength: 160)` component to force the bottom-most input field to scroll cleanly high above the floating `HomeHubView` navigation pill.

### Stage 5: iOS 17 Scroll Anchoring
- **Step 5.1**: Attach `.scrollPosition(id: $activeFieldId)` mappings so the interface can jump mathematically explicitly.
- **Step 5.2**: Tie `.onChange(of: focusedField)` to push the active `id` payload, aggressively smooth-scrolling the currently selected input specifically into the center of the viewport automatically.

---

## Phase 3: Focus Modifiers & Auto-Formatting

**Objective**: Ensure data entered into these fields maps perfectly into templates by stripping bad characters and providing strong focus hints.

### Stage 1: Active Field Highlighting
- **Step 1.1**: Introduce an enum `ProfileField` mapping statically to each specific text field property.
- **Step 1.2**: Introduce SwiftUI's `@FocusState private var focusedField: ProfileField?`.
- **Step 1.3**: Map each UI container with `.focused($focusedField, equals: .niche)` respectively.
- **Step 1.4**: Modify the Border overlay: `.stroke(focusedField == .niche ? Color.hfAccent : Color.clear, lineWidth: 2)`.

### Stage 2: UI String Validation Instructions
- **Step 2.1**: Mount `.font(.caption)` instruction strings implicitly above difficult variables (e.g. "Use plural wording -> 'business owners' instead of 'a business owner'").
- **Step 2.2**: Mute the instruction text heavily using `.opacity(0.5)` to ensure the user's typed value retains strict priority in visual hierarchy.

### Stage 3: Trailing Whitespace Scrubbing
- **Step 3.1**: Mount an overarching `.onChange(of: focusedField)` listener on the core UI element.
- **Step 3.2**: The exact moment focus transitions from `.some` to `nil` (editing ends), manually process `.trimmingCharacters(in: .whitespacesAndNewlines)` on the bound internal string state.

### Stage 4: Text Capitalization Engine
- **Step 4.1**: Append `.textInputAutocapitalization(.never)` rigidly onto the `niche`, `painPoint`, and `coreOffer` textfields.
- **Step 4.2**: Provide `.textInputAutocapitalization(.words)` exclusively to `businessName` to preserve natural noun formats natively.

### Stage 5: Parameter Boundary Restrictions
- **Step 5.1**: Impose a hard `maxLength` intercept inside the `onChange` logic for inputs like `niche` (e.g. max 40 chars) to prevent extreme user essays breaking the layout inside the teleprompter bounds.
- **Step 5.2**: If length is violated, truncate the string safely utilizing `.prefix()`.

---

## Phase 4: Multiple Persona Support (Agency Expansion)

**Objective**: Allow super-users to save multiple profile profiles so they can instantly swap contexts between a "Fitness Client" and a "SaaS Client".

### Stage 1: Struct Restructuring
- **Step 1.1**: Create `struct CreatorPersona: Codable, Identifiable, Hashable`.
- **Step 1.2**: Transfer the intelligence properties (`niche`, `painPoint`) to sit natively inside this struct architecture.
- **Step 1.3**: Serialize an entire generic Array of `[CreatorPersona]` inside `UserDefaults` using explicitly encoded JSON Strings instead of flat property keys.

### Stage 2: Centered Persona Switcher Interface
- **Step 2.1**: Fabricate a perfectly centered interactive interface directly under the avatar profile image.
- **Step 2.2**: Utilize a central dropdown or a centered scrolling pill menu to allow users to instantly swap business contexts.
- **Step 2.3**: Establish an `@State var activePersonaID: UUID` binding to dynamically load the selected profile's parameters into the active UI fields.

### Stage 3: Instant State Swap Logic
- **Step 3.1**: Watch the `activePersonaID` for modification events via `.onChange`.
- **Step 3.2**: Find the target `CreatorPersona` mathematically matching the new UUID and overwrite all active TextField `Text` bindings synchronously without redrawing the container.

### Stage 4: Creation & Deletion Operations
- **Step 4.1**: Add a trailing `Image(systemName: "plus")` button fixed next to the persona pills.
- **Step 4.2**: Inject an `.alert("New Client Persona")` capable of inserting a fresh struct mapped directly back into the `AppStorage` logic.
- **Step 4.3**: Provide a localized deletion mechanic that scrubs the `activePersonaID` from the array bounds and drops the user securely back to the first available persona block.

### Stage 5: Animation Flushing
- **Step 5.1**: Wrap the activePersona `.onChange` handler rigorously inside a `withAnimation(.spring)` block.
- **Step 5.2**: Establish a transient layout effect where the previously bound text blurs or slides downwards identically as the new variables animate upwards when hopping personas.

---

## Phase 5: Avatar & Identity Branding

**Objective**: Connect the app locally. Give the user a visual representation at the top of the profile page to make it feel personalized.

### Stage 1: Native Image Import
- **Step 1.1**: Execute an `import PhotosUI` command inside `UserProfileView.swift`.
- **Step 1.2**: Provide `@State private var selectedItem: PhotosPickerItem?` as the controller bridge.
- **Step 1.3**: Layer a generic avatar symbol into the logical `PhotosPicker` block parameter.

### Stage 2: Storage Physics Implementation
- **Step 2.1**: Read natively from the picker using `.loadTransferable(type: Data.self)`.
- **Step 2.2**: Assemble a secure destination URL referencing the iOS specific `.documentDirectory`.
- **Step 2.3**: Pass the resulting exact filesystem string to an `@AppStorage("userAvatarPath")` payload context.

### Stage 3: Image Caching & Optimization
- **Step 3.1**: Before saving the `Data` from PhotosUI, push it securely through a resizing constraint to map an absolute maximum bounding box of `512x512` pixels.
- **Step 3.2**: Re-compress the target image strictly as a `JPEG` at `0.8` quality to protect the local memory footprint across extensive usage periods natively.

### Stage 4: Centered UI Header Rendering
- **Step 4.1**: Utilize the `onAppear` lifecycle hook to locate and read the native `UIImage` from the path.
- **Step 4.2**: Mount the avatar tightly using `.resizable()`, `.scaledToFill()`, and a prominent `.frame(width: 100, height: 100)`.
- **Step 4.3**: Clip it using `.clipShape(Circle())` and enforce a 2pt stroke containing `.hfAccent`. Ensure this is absolutely horizontally centered on the screen.

### Stage 5: Ambient Display Integration
- **Step 5.1**: Place the avatar in a top-level centered `VStack`.
- **Step 5.2**: Supply a centered `Text` block greeting the active `businessName` natively directly below the avatar.
- **Step 5.3**: Anchor the "Add Profile" or specific Profile Switcher centrally beneath this greeting block, creating a unified top-down symmetry.

---

## Phase 6: Sync & Live Preview Interaction

**Objective**: Demonstrate precisely how the Profile Builder's math maps directly to the Left Tab's power, building instant confidence.

### Stage 1: The Dark Code-Block Container
- **Step 1.1**: Build `RoundedRectangle(cornerRadius: 12)` loaded securely with `#1A1A1A` coloration.
- **Step 1.2**: Position it explicitly prior to the bottom spacer in the parent `VStack`.
- **Step 1.3**: Implement a monospace `.font(.system(.body, design: .monospaced))` overlay for precise syntax feel.

### Stage 2: Variable Subscription Logic
- **Step 2.1**: Isolate a hardcoded evaluation template explicitly inside the view: `"Hey fellow [USER_NICHE], if you're struggling with [PAIN_POINT], keep watching."`
- **Step 2.2**: Wire the specific brackets directly to the state parameters.
- **Step 2.3**: Ensure that typing in the `niche` field organically pushes visual changes entirely across the Live Preview.

### Stage 3: Real-Time Highlight Rendering
- **Step 3.1**: Disassemble the sentence structurally via native `Text()` chains: `Text("Hey fellow ") + Text(profile.niche.isEmpty ? "[USER_NICHE]" : profile.niche).foregroundColor(.hfAccent)`.
- **Step 3.2**: Allow `.multilineTextAlignment(.leading)` so strings overflow efficiently.

### Stage 4: Fallback Preview Visualization
- **Step 4.1**: Ensure `profile.niche.isEmpty` inherently defaults back to displaying `[USER_NICHE]` exactly.
- **Step 4.2**: Wrap the specific generic string brackets tightly inside a muted `.foreground(.gray)` tone, and aggressively flip them to bright `.hfAccent` when population is detected successfully.

---

## Phase 7: AI Intelligence Auto-Population Pipeline

**Objective**: Eliminate manual data entry friction entirely by allowing users to paste a website or social link, leveraging an AI backend to parse and auto-fill the enhanced commercial parameters.

### Stage 1: The "Magic Import" UI Trigger
- **Step 1.1**: Above the primary data fields, introduce an `.actionSheet` or `.alert` bound to an `importLink` string.
- **Step 1.2**: Implement a prominent "Auto-Fill with Website / Social Link" button styled with an `hfAccent` gradient and a sparkle icon (`sparkles`).

### Stage 2: Background Scraping & Parsing Handler
- **Step 2.1**: Establish a URL validation gate discarding malformed strings before initiating requests.
- **Step 2.2**: Call the HookFlow backend endpoint capable of reading meta-tags and heading architecture off the provided URL.
- **Step 2.3**: Command the backend AI (e.g., standard text completion endpoint) to parse the scraped payload strictly into a JSON schema matching `CreatorPersona` keys (`coreOffer`, `industryNiche`, `targetAudience`, etc.).

### Stage 3: Animated Field Population
- **Step 3.1**: Intercept the returned JSON object and map it natively to the `activePersonaID` fields.
- **Step 3.2**: Execute the property mutations exclusively within a `withAnimation(.easeInOut(duration: 0.8))` block.
- **Step 3.3**: The UI will physically cascade text into the empty fields, providing massive UX gratification and bypassing the typical "boring form" problem entirely.

---

## Phase 8: Global Execution (Template Builder Hooks)

**Objective**: Mathematically define exactly how the template builder backend intercepts this `CreatorPersona` data to guarantee scripts generated are deeply personalized.

### Stage 1: Prompt Context Injection
- **Step 1.1**: Inside `ScriptEditorView` or the AI Template Prompt logic, append a strict system prefix: 
  `"You are writing a script for [businessName], operating in the [industryNiche] space. Their target audience is [targetAudience] suffering from [customerPainPoint]. Highlight their [coreOffer] and direct users to [primaryCallToAction]. Ensure tone is [brandTone]."`
- **Step 1.2**: If any parameters evaluate as `.isEmpty`, drop them gracefully from the prompt string using generic fallbacks.

### Stage 2: Live Substitution Validation
- **Step 2.1**: Guarantee that any script generation or re-generation respects the current `activePersonaID`.
- **Step 2.2**: If a user switches from "Persona A" to "Persona B", the AI immediately re-evaluates the script context without the user needing to type a single new instruction line.

---

## Phase 9: Onboarding Gateway Injection

**Objective**: Command the state of newly-installed applications, demanding profile data execution *prior* to accessing to the template feed.

### Stage 1: Root Navigation Blocking
- **Step 1.1**: Configure an application status tracking boolean `@AppStorage("isFirstProfileSetupComplete")`.
- **Step 1.2**: Inside `ContentView`, process an `if (!isFirstProfileSetupComplete)` route interception.
- **Step 1.3**: Command the injection of `OnboardingProfileView` natively inside the root `NavigationStack`.

### Stage 2: Form Segregation Design
- **Step 2.1**: Reuse the exact visual configuration of `UserProfileView`, rendering the exact forms and inputs exactly the same way to ensure UI component DRY principles.
- **Step 2.2**: Intentionally omit the `HomeHubView` navigation components from the display.

### Stage 3: Haptic Success Routing
- **Step 3.1**: Pin a prominent "Finalize Profile" button to the layout.
- **Step 3.2**: Validate mathematically if the `niche` parameter contains strings.
- **Step 3.3**: Tie `UINotificationFeedbackGenerator(style: .success)` specifically into the tap action.
- **Step 3.4**: Aggressively switch `isFirstProfileSetupComplete` state to `true`, executing the final animated transition natively into the Home Hub engine.
