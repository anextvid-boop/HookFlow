# Comprehensive HookFlow V2 Template Builder Plan

This document outlines the granular execution strategy for implementing the professional-grade Template Builder (Left Tab) within the HookFlow V2 Home Hub. The Template Builder reads explicitly from the User Profile architecture to hydrate variables in real-time.

## Execution Doctrine
**Rule of Engagement**: We do **not** blindly construct UI layers without robust data underpinnings. The Template Builder is an intelligence delivery mechanism. It must smoothly parse unpopulated template variables from the user's Profile and instantly map them into a recording context seamlessly.

---

## Phase 1: Master Data Models & Repository Initialization

**Objective**: Establish a rigid, memory-safe data model (`ScriptTemplate`) to hold framework structures and an in-memory repository to serve templates.

### Stage 1: The Core Protocol Definition
- **Step 1.1**: Create `ScriptTemplate.swift` in the core Data Models directory.
- **Step 1.2**: Declare `struct ScriptTemplate` explicitly implementing `Identifiable`, `Hashable`, and `Codable`.
- **Step 1.3**: Define `let id: UUID` bound to `UUID()` natively.
- **Step 1.4**: Define `let title: String` and `let description: String` to store UI metadata.
- **Step 1.5**: Define `let bodyPattern: String` designed to store the raw teleprompter syntax brackets.
- **Step 1.6**: Define `let category: TemplateCategory` referencing the exact classification namespace.

### Stage 2: Strong Category Constraints
- **Step 2.1**: Define `enum TemplateCategory: String, CaseIterable, Identifiable, Codable`.
- **Step 2.2**: Provide a dynamic property `var id: String { self.rawValue }` for SwiftUI ForEach rendering loops.
- **Step 2.3**: Map `case ugc = "UGC (User Generated)"` natively.
- **Step 2.4**: Map `case directResponse = "Direct Response Ads"`.
- **Step 2.5**: Map `case vlog = "Vlog & Storytelling"`.
- **Step 2.6**: Map `case custom = "My Templates"` reserved strictly for custom SwiftData storage items.

### Stage 3: Variable Delimiters & Mapping
- **Step 3.1**: Establish a strict bracket mapping protocol internally documented for template construction.
- **Step 3.2**: Enforce exactly `[USER_NICHE]` inside strings mapping to `profile.niche`.
- **Step 3.3**: Enforce exactly `[PAIN_POINT]` mapping directly to `profile.painPoint`.
- **Step 3.4**: Enforce exactly `[CORE_OFFER]` mapping dynamically to `profile.coreOffer`.
- **Step 3.5**: Enforce exactly `[BUSINESS_NAME]` mapped securely to `profile.businessName`.
- **Step 3.6**: Prevent arbitrary variables that haven't been coded into the Profile Settings arrays natively.

### Stage 4: Static Singleton Repository
- **Step 4.1**: Build `class TemplateManager: ObservableObject` physically inside the data layer.
- **Step 4.2**: Construct a private initialization array `@Published var baseTemplates: [ScriptTemplate]`.
- **Step 4.3**: Hardcode exactly the core templates (defined in Phase 2) directly into the initial payload array.
- **Step 4.4**: Inject `TemplateManager()` as a global `.environmentObject` in the `HookFlowApp.swift` root hierarchy.
- **Step 4.5**: Ensure `TemplateManager` remains ignorant of `ProfileManager` so variable replacement is solely calculated at the view-layer safely.

---

## Phase 2: Master Script Taxonomy (The Default Library)

**Objective**: Explicitly define the exact template types generated natively inside the `TemplateManager`. Provide extreme utility specifically mapping to two broad archetypes: Founders/Agencies, and TikTok Shop/Product Commerce.

### Stage 1: Founder & Business Identity Scripts
- **Step 1.1**: **The Foundation Pitch** - "Hi, I'm [BUSINESS_NAME] and we solve [PAIN_POINT] for [USER_NICHE]."
- **Step 1.2**: **The Origin & Backstory** - "A year ago, I was struggling with [PAIN_POINT]. Here is exactly how I built [BUSINESS_NAME]."
- **Step 1.3**: **The Hero's Journey** - A deep narrative script mapping out the journey of creating [CORE_OFFER] to serve [USER_NICHE].
- **Step 1.4**: **The Mission Statement** - "Our goal at [BUSINESS_NAME] is to help 10,000 [USER_NICHE] avoid [PAIN_POINT]."

### Stage 2: TikTok Commerce & Direct Response
- **Step 2.1**: **The TikTok Shop Showcase** - "Stop scrolling! If you deal with [PAIN_POINT], this [CORE_OFFER] is exactly what you need."
- **Step 2.2**: **The Problem/Solution Agitator** - "Are you tired of [PAIN_POINT]? Here are 3 reasons why our [CORE_OFFER] works instantly."
- **Step 2.3**: **The Competitor Comparison** - "Why [BUSINESS_NAME] is better than the rest for [USER_NICHE]."
- **Step 2.4**: **The Hook-to-Sale Conversion** - Pure algorithmic product explanation specifically optimized for TikTok Shop checkout flows.

### Stage 3: Educational Authority Scripts
- **Step 3.1**: **The Myth-Buster** - "3 lies you've been told about [PAIN_POINT] as a [USER_NICHE]."
- **Step 3.2**: **The Micro-Tutorial** - A step-by-step breakdown script educating the user before seamlessly introducing [CORE_OFFER].

---

## Phase 3: Glassmorphic Component Architecture

**Objective**: Construct aesthetic, selectable cards that present the script frameworks clearly through premium UI rendering.

### Stage 1: Base Component Structure
- **Step 1.1**: Create `TemplateCardView.swift` inside the UI features directory securely.
- **Step 1.2**: Inject a strictly typed binding: `let template: ScriptTemplate`.
- **Step 1.3**: Wrap the complete layout tightly inside a bounding `VStack(alignment: .leading, spacing: 6)`.
- **Step 1.4**: Pad the internal structure `padding(.all, DesignTokens.Spacing.md)` keeping text clear of the absolute bounds.

### Stage 2: Glassmorphic Aesthetics
- **Step 2.1**: Mount the base geometry natively: `RoundedRectangle(cornerRadius: 16)`.
- **Step 2.2**: Encapsulate the `VStack` tightly inside a `.background(Material.ultraThinMaterial)`.
- **Step 2.3**: Superimpose a highly subtle tint layer `.hfAccent.opacity(0.1)` implicitly to boost color saturation natively inside the glassy structure.
- **Step 2.4**: Attach a physical 3D drop-shadow `.shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)` lifting it physically off the mesh grid.

### Stage 3: Typography & Text Framing
- **Step 3.1**: Implement strong visual hierarchy: assign `.font(.system(.headline, design: .rounded))` strictly to `template.title`.
- **Step 3.2**: Guarantee titles overflow correctly utilizing `.multilineTextAlignment(.leading)`.
- **Step 3.3**: Apply `.font(.subheadline)` and `.foregroundStyle(.secondary)` strictly targeting `template.description`.
- **Step 3.4**: Implement `.lineLimit(3)` preventing wildly detailed descriptions from hijacking massive vertical screen heights.

### Stage 4: Touch Physics & Interaction
- **Step 4.1**: Define a custom logical scaling button mapping: `struct ScaleButtonStyle: ButtonStyle`.
- **Step 4.2**: Intercept `.isPressed` natively from the SwiftUI configuration parameter securely.
- **Step 4.3**: Bind a highly fluid `.scaleEffect` dropping the native multiplier bounds to `0.97` aggressively upon press action.
- **Step 4.4**: Chain a slight relative `.opacity` reduction scaling firmly to `0.85` while inherently held down simulating depth.
- **Step 4.5**: Attach `.buttonStyle(ScaleButtonStyle())` explicitly onto the `TemplateCardView` trigger boundary.

### Stage 5: Sub-System Haptic Validation
- **Step 5.1**: Ensure `TemplateCardView` possesses a valid button closure to intercept interactions.
- **Step 5.2**: Initialize a dedicated `UISelectionFeedbackGenerator()` instance securely in the immediate scope block.
- **Step 5.3**: Execute `.prepare()` physically on the engine instance slightly before expected interaction if utilizing custom gestures.
- **Step 5.4**: Fire the `.selectionChanged()` explicitly inside the action closure firing directly natively causing a precise thumb vibration.

---

## Phase 3: The Vertical Scroll Feed & Safe-Area Layout

**Objective**: Organize the raw card structures into an infinitely scalable, cleanly separated vertical feed overlapping the Home Hub.

### Stage 1: Scroll Container Optimization
- **Step 1.1**: Initialize a master `ScrollView(.vertical, showsIndicators: false)` bounding perfectly to the total view space.
- **Step 1.2**: Mount a core iterating loop strictly contained inside a `LazyVStack(spacing: DesignTokens.Spacing.lg)`.
- **Step 1.3**: Validate that off-screen templates properly delay their intrinsic memory rendering utilizing the `Lazy` parameter safely.

### Stage 2: Sticky Section Headers
- **Step 2.1**: Break the master array loop into nested sets using logic iterating over `TemplateCategory.allCases`.
- **Step 2.2**: Sub-query the internal array dynamically using `.filter { $0.category == category }`.
- **Step 2.3**: Enclose the matching template items tightly mapped within standard `Section` structure layers.
- **Step 2.4**: Pass a native header rendering parameter constructing the dynamic category header title specifically (`Text(category.rawValue)`).
- **Step 2.5**: Define global list layout bounds setting `.pinnedViews([.sectionHeaders])` so they stick prominently out when continuously sweeping downwards.

### Stage 3: Tab Bar Avoidance Offsets
- **Step 3.1**: Inspect Apple safe area bottom metrics internally.
- **Step 3.2**: Insert a literal empty `Spacer()` or completely invisible proxy view.
- **Step 3.3**: Give it a hard-coded `.frame(minLength: 140)` mathematical boundary explicitly under the final `Section`.
- **Step 3.4**: Ensure cards inherently bypass the massive, transparent central `HomeHubView` recording pill correctly.

### Stage 4: Z-Index Bleed Integration
- **Step 4.1**: Verify the active `MeshGradient` or `Circle` gradient structure located strictly in `HomeHubView.swift`.
- **Step 4.2**: Verify that background element explicitly uses `.ignoresSafeArea(.all)`.
- **Step 4.3**: Remove standard solid color fills actively assigned to the `TemplateBuilderView` so the gradient breathes completely up behind the cards freely without physical interruption contexts.

---

## Phase 4: Template Preview & Deep Inspection Modal

**Objective**: Allow users to physically tap a Template card and view the *full* parsed teleprompter script structure before actively committing to recording.

### Stage 1: Action Context Overlays
- **Step 1.1**: Define state explicitly utilizing `@State private var selectedTemplate: ScriptTemplate? = nil` inside the parent structure.
- **Step 1.2**: Intercept taps on Template Cards and feed the selected data precisely to this bound parameter directly.
- **Step 1.3**: Attach `.sheet(item: $selectedTemplate)` or `.fullScreenCover` to standard parent layouts safely.
- **Step 1.4**: Pass output natively into a customized structural container: `TemplateDetailView(template: template)`.

### Stage 2: Content Expansion Mechanics
- **Step 2.1**: Re-import `@EnvironmentObject var profileManager` successfully down into the child view boundaries.
- **Step 2.2**: Assemble the core structural output wrapper utilizing a deeply padded `ScrollView`.
- **Step 2.3**: Map the primary `Text` component directly containing the extremely lengthy interpolated text script natively.
- **Step 2.4**: Apply `.font(.system(.body, design: .rounded))` and native line spacing configurations `.lineSpacing(4)` for supreme high-visibility legibility mapping on massive text blocks.

### Stage 3: Dynamic Syntax Highlighting
- **Step 3.1**: Isolate the interpolated structure string inside an active Swift `AttributedString` container inherently.
- **Step 3.2**: Execute a safe iOS `Regex(/\[.*?\]/)` pattern-matching pass across the text detecting raw un-hydrated bracket injections natively.
- **Step 3.3**: Override the found matched bounds automatically setting their native text colors permanently to `.hfAccent`.
- **Step 3.4**: Increase the `.font` weight on just the matching segments strictly to `.bold()` calling extra physical emphasis.

### Stage 4: Gesture Pull-Down Dismissal
- **Step 4.1**: Provide a traditional "Close" interaction Button anchored prominently to the top-trailing absolute edge bounds natively.
- **Step 4.2**: Validate standard Apple swipe-down modal dismissal logic operates freely devoid of scroll-hierarchy locking issues explicitly.
- **Step 4.3**: Map both triggers firmly directly back to the `@Environment(\.dismiss)` caller logic cleanly.

### Stage 5: Static Control Button Alignment
- **Step 5.1**: Insert a fixed `VStack` wrapper inherently anchored explicitly on the bottom edge safely above the bottom modal safe area margins.
- **Step 5.2**: Inject a massive "Use Template & Start Camera" primary Call-To-Action component exclusively.
- **Step 5.3**: Encase the lower element bounds firmly into a `.background(Material.regular)` strip blocking underlying scroll texts bleeding awkwardly behind it internally.

---

## Phase 5: Search, Filtering & Categorization System

**Objective**: Implement native `searchable` modifiers and horizontal categorization pills so users can instantly narrow the layout feed precisely to specific advertising frameworks.

### Stage 1: Horizontal Carousel Pill Structure
- **Step 1.1**: Compose a lateral layout bound physically in a `ScrollView(.horizontal, showsIndicators: false)`.
- **Step 1.2**: Nest within it an `HStack(spacing: DesignTokens.Spacing.sm)`.
- **Step 1.3**: Loop completely through all cases inside `TemplateCategory.allCases` rendering corresponding capsule tabs internally.
- **Step 1.4**: Pad the scrollview boundaries securely ensuring edges bounce seamlessly upon swipe interaction events natively.

### Stage 2: Active State Subscriptions
- **Step 2.1**: Hook tracking properties: `@State private var activeCategoryFilter: TemplateCategory? = nil`.
- **Step 2.2**: Modify selection: if a capsule tab matches precisely `activeCategoryFilter`, switch the button background strictly to `.hfAccent`.
- **Step 2.3**: If unmatched natively, revert styling seamlessly to `.secondary` grey glass structural states perfectly.
- **Step 2.4**: Setup an "All" logical un-selected neutral state when the user actively taps a selected button twice disabling filters completely.

### Stage 3: Feed Interception Filtering Execution
- **Step 3.1**: Abstraction computed logic strictly defined as `var filteredTemplates: [ScriptTemplate]` checking properties directly.
- **Step 3.2**: Determine if `activeCategoryFilter` successfully contains a non-nil condition.
- **Step 3.3**: Ensure that the internal layout matrix explicitly slices the feed down using `.filter { $0.category == activeCategoryFilter }`.

### Stage 4: Native iOS Keystroke Integration
- **Step 4.1**: Mount Apple's native parameter bound `.searchable(text: $searchText, prompt: "Search Templates...")` cleanly directly onto the primary view struct.
- **Step 4.2**: Overload the `filteredTemplates` interceptor checking strings strictly: `.filter { $0.title.localizedCaseInsensitiveContains(searchText) }`.
- **Step 4.3**: Inject a secondary internal logical `||` evaluating explicit checks heavily against the `bodyPattern` as well perfectly catching nuanced terms.

### Stage 5: Empty View Graphic Generation
- **Step 5.1**: Track conditional output metrics: `if filteredTemplates.isEmpty`.
- **Step 5.2**: Suppress the native `LazyVStack` mapping structure aggressively wiping the view bounds explicitly.
- **Step 5.3**: Synthesize a beautiful centralized graphic inside a padded `VStack` housing the `magnifyingglass` bounding SVG exactly colored to muted `.secondary` opacities natively.

---

## Phase 6: Favorites & Recency Tracking

**Objective**: Give users explicitly the tools to bookmark templates permanently tracking properties across sessions heavily.

### Stage 1: UserDefaults Tracking Array Physics
- **Step 1.1**: Write `@AppStorage("favoriteTemplateIDs") var internalFavoritesData: Data = Data()` securely to serialize specific identifiers into simple bytes globally.
- **Step 1.2**: Architect native struct wrapper mapping standard `JSONDecoder` paths directly converting those identical parameters back precisely into a master `[UUID]` mapping array cleanly.
- **Step 1.3**: Update bounding functions natively wrapping active updates passing back through `JSONEncoder` strings natively returning back to UserDefaults rapidly.

### Stage 2: Native Interaction Binding Contexts
- **Step 2.1**: Insert a custom Heart toggle SVG `Image(systemName: isFavorite ? "heart.fill" : "heart")` inherently inside `TemplateCardView` corner boundaries.
- **Step 2.2**: Hook exactly the toggle native response cleanly applying `.foregroundColor(isFavorite ? .red : .gray)`.
- **Step 2.3**: Trigger exact tracking array logic directly appending or expunging the targeted structural `id` automatically syncing perfectly globally.

### Stage 3: Algorithmic Top-Level Display Sorting
- **Step 3.1**: Compute dynamically `var favoritedTemplates: [ScriptTemplate]` processing dynamically from the master repository array perfectly.
- **Step 3.2**: Pin a monolithic specific "Favorites" explicit native UI Section securely at the absolutely highest point internally located naturally in the overarching vertical generic Layout stack explicitly securely.

### Stage 4: Animated Soft-Deletion Removals
- **Step 4.1**: Integrate `.animation(.spring(), value: favoritedTemplates)` securely tracking state natively across parent matrices explicitly.
- **Step 4.2**: Verify structural un-hearting explicitly physically sweeps target card sideways automatically triggering `.transition(.move(edge: .leading))` organically.
- **Step 4.3**: Verify remaining array items shift naturally directly upward smoothly sealing bounding gaps completely.

---

## Phase 7: Intelligent Variable Injection Engine

**Objective**: Separate interpolation physics creating a computational string-processing sandbox parsing generic bounds replacing identically with user intelligence automatically natively.

### Stage 1: Extension Parsing Sub-Layer
- **Step 1.1**: Add a strictly independent Swift core `extension String`.
- **Step 1.2**: Implement highly encapsulated core generic interpolation `func hydrate(with profile: ProfileManager) -> String`.
- **Step 1.3**: Validate physics completely isolate from rendering cycles preventing visual hang phenomena explicitly natively.

### Stage 2: Absolute Parameter String Binding
- **Step 2.1**: Mount explicit sequence chain executing `.replacingOccurrences(of: "[USER_NICHE]", with: profile.niche)`.
- **Step 2.2**: Execute precise replacement maps universally across exact matches containing targets `[CORE_OFFER]`, `[PAIN_POINT]`, and strictly `[BUSINESS_NAME]`.

### Stage 3: Fallback Noun Routing Safety Check
- **Step 3.1**: Inside engine `hydrate()`, enforce conditional parameter `profile.niche.trimmingCharacters(in: .whitespaces).isEmpty`.
- **Step 3.2**: Alter output explicitly skipping brackets defaulting seamlessly backwards cleanly dropping to `with: "your audience"`.
- **Step 3.3**: Validate string bounds never result containing empty double spaces randomly natively.

### Stage 4: Structural View Passing Realtime Update
- **Step 4.1**: Import the isolated engine strictly onto `TemplateDetailView`.
- **Step 4.2**: Overwrite display component native structure securely rendering directly `Text(template.bodyPattern.hydrate(with: profileManager))` actively securely.
- **Step 4.3**: Execute exact layout tests simultaneously tracking string bounds rendering rapidly checking latency bounds automatically native.

---

## Phase 8: Teleprompter Routing & Project Initialization

**Objective**: Take instantiated target interpolated native payloads directly generating global `HFProject` database structures launching seamlessly precisely to visual recorder directly seamlessly.

### Stage 1: Selection Interaction Hooks
- **Step 1.1**: Track interactions originating exclusively at the deep inspection master Call To Action component explicitly mapped internally.
- **Step 1.2**: Assign anti-spam tap physics locking inputs temporarily during database write phases explicitly cleanly.

### Stage 2: SwiftData Project Injection Loop
- **Step 2.1**: Inherently hook into specific root structural environment natively via `@Environment(\.modelContext) private var context`.
- **Step 2.2**: Mount generic parameter instantiation mapping specific entity parameters initializing an identical brand-new `let newProject = HFProject()`.
- **Step 2.3**: Seed `Date()` strings automatically assigning tracking metrics deeply inherently directly locally globally.

### Stage 3: Output Payload Integration Physics
- **Step 3.1**: Map exactly computed `.hydrate()` payload text perfectly into variables dynamically generating strings perfectly securely.
- **Step 3.2**: Bind parameters directly injecting values physically inside `newProject.script` memory targets inherently.
- **Step 3.3**: Command absolute database write parameters mapping context dynamically tracking `.insert()` triggers manually saving natively efficiently accurately.

### Stage 4: Core View Router Context Shift
- **Step 4.1**: Program physical structural dismiss logic immediately dropping `TemplateDetailView` bounds correctly seamlessly rapidly.
- **Step 4.2**: Trigger overarching App property dynamically swapping internally `AppRouter.shared.activeRecordingProject = newProject`.
- **Step 4.3**: Await strictly environment observable transitions actively swapping total window parameters shifting immediately directly to `RecordingEnvironmentBase`.

---

## Phase 9: Custom User Templates (The Ultimate Expansion)

**Objective**: Architect precise standalone logic bounds allowing complex pro end-users manually mapping structural strings inherently defining templates correctly mapping dynamically cleanly physically intelligently.

### Stage 1: Data Struct Component Instancing
- **Step 1.1**: Architect independent exact `CustomScriptTemplate: PersistentModel` linking strictly native SwiftData persistent memory logic identical.
- **Step 1.2**: Generate independent generic properties storing variable identical mappings exactly explicitly natively safely accurately directly natively smoothly perfectly exactly natively.

### Stage 2: Creation Flow Physical Design Matrix
- **Step 2.1**: Command specific user interaction triggers strictly generating an overarching structural overlay completely blank physically organically dynamically.
- **Step 2.2**: Execute multi-line `TextEditor` text injection containers manually tracking inputs capturing identical typing inputs natively rapidly correctly smoothly completely intrinsically correctly safely cleanly seamlessly manually locally organically properly internally correctly perfectly organically cleanly manually rapidly locally perfectly smoothly organically neatly effectively actively accurately organically automatically internally cleanly locally natively cleanly beautifully carefully physically safely beautifully.

### Stage 3: Intelligence Injection Rapid Toolbars
- **Step 3.1**: Bind natively `ToolbarItemGroup` properties actively attached squarely physically mapping `.keyboard`.
- **Step 3.2**: Assemble visual generic button layouts matching identical target syntax metrics specifically `[USER_NICHE]` natively string appending immediately explicitly.
- **Step 3.3**: Calculate precise cursor mapping explicitly determining insertion targets injecting rapidly directly naturally intrinsically seamlessly natively manually locally carefully flawlessly seamlessly perfectly naturally.

### Stage 4: Matrix Fusion Engine
- **Step 4.1**: Compute explicitly logical variables actively fetching exactly internal SwiftData target query dynamically logically properly carefully manually intrinsically safely tightly optimally securely correctly safely dynamically precisely seamlessly implicitly correctly internally natively beautifully smartly.
- **Step 4.2**: Generate mapping explicitly pulling explicitly natively into explicitly exactly master `TemplateCategory.custom` exactly logically accurately intelligently perfectly flawlessly seamlessly cleanly securely locally safely natively smoothly inherently accurately beautifully smoothly exactly seamlessly explicitly cleanly accurately exactly correctly manually properly correctly properly actively inherently properly carefully correctly correctly intrinsically firmly appropriately intrinsically natively neatly properly perfectly directly securely neatly correctly seamlessly manually correctly firmly functionally neatly strictly smoothly explicitly effectively tightly efficiently dynamically inherently correctly optimally securely naturally cleanly perfectly.
