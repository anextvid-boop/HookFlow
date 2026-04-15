import SwiftUI
import SwiftData

/// The Master Left Tab Engine serving all Scripts dynamically and resolving searches flawlessly natively.
struct TemplateBuilderView: View {
    @EnvironmentObject private var templateManager: TemplateManager
    @EnvironmentObject private var profileManager: ProfileManager
    
    @State private var searchText: String = ""
    @State private var activeCategoryFilter: TemplateCategory? = nil
    
    // Tracking Arrays natively across Sessions
    @AppStorage("favoriteTemplateIDsData") private var favoriteTemplateData: Data = Data()
    @State private var favoriteIDs: Set<UUID> = []
    
    // Track which categories are dynamically expanded in the UI (Now locked completely closed on boot)
    @State private var expandedCategories: Set<TemplateCategory> = []
    @State private var isFavoritesExpanded: Bool = false
    
    // Deep SwiftData hook explicitly isolating UI states from manual loops
    @Query(sort: \CustomTemplate.creationDate, order: .reverse) private var storedCustomTemplates: [CustomTemplate]
    
    // Modal Interaction Overlay Binding
    @State private var selectedTemplate: ScriptTemplate? = nil
    @State private var isPresentingComposer: Bool = false
    
    var body: some View {
        ZStack {
            // Implicit background respects HomeHubView's underlying MeshGradient natively
            
            VStack(spacing: .zero) {
                // MARK: - Search & Title Header
                buildTopHeader()
                
                // MARK: - Horizontal Filter Pills
                buildCategoryScrubber()
                
                // MARK: - Feed Pipeline
                ScrollView(.vertical, showsIndicators: false) {
                    // Tightly compacted spacing layout eradicating the massive unutilized dead-zones
                    LazyVStack(spacing: DesignTokens.Spacing.sm, pinnedViews: [.sectionHeaders]) {
                        
                        let filtered = searchFilteredTemplates()
                        
                        // 0. The Composer Button explicitly at the absolute top of the Custom list
                        if activeCategoryFilter == .custom || (activeCategoryFilter == nil && searchText.isEmpty && storedCustomTemplates.isEmpty) {
                            buildCustomTemplateTrigger()
                                .padding(.top, 10)
                        }
                        
                        if filtered.isEmpty && storedCustomTemplates.isEmpty {
                            buildEmptyGraphic()
                        } else {
                            
                            // 1. Monolithic Favorites Injection Array (Only if un-filtered)
                            if activeCategoryFilter == nil && searchText.isEmpty && !favoriteIDs.isEmpty {
                                let favs = searchFilteredTemplates().filter { favoriteIDs.contains($0.id) }
                                
                                buildCollapsibleSection(
                                    title: "★ Favorites",
                                    isExpanded: $isFavoritesExpanded,
                                    items: favs,
                                    isCustomRoot: false
                                )
                            }
                            
                            // 2. Iterating Taxonomy Arrays cleanly mapping the bounds
                            ForEach(TemplateCategory.allCases) { category in
                                let categoryItems = filtered.filter { $0.category == category }
                                
                                if !categoryItems.isEmpty || (category == .custom && activeCategoryFilter == .custom) {
                                    buildCollapsibleCategory(category: category, items: categoryItems)
                                }
                            }
                        }
                        
                        // Safety buffer avoiding the floating central record interface
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            }
        }
        .onAppear {
            loadFavorites()
            // State defaults to entirely closed arrays to preserve layout footprint natively.
        }
        // Hooking the Deep Modal structurally explicitly pushing down the exact array element chosen
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
                // Enforce the environment object inheritance down the modal hierarchy natively
                .environmentObject(profileManager)
        }
        .sheet(isPresented: $isPresentingComposer) {
            TemplateComposerView()
        }
        .animation(.spring(), value: favoriteIDs)
        .animation(.spring(), value: searchText)
        .animation(.spring(), value: activeCategoryFilter)
        .animation(.spring(), value: expandedCategories)
    }
    
    // MARK: - Sub-component Logic
    
    @ViewBuilder
    private func buildCollapsibleCategory(category: TemplateCategory, items: [ScriptTemplate]) -> some View {
        let isExpanded = Binding<Bool>(
            get: { self.expandedCategories.contains(category) },
            set: { isExpanding in
                if isExpanding {
                    self.expandedCategories.insert(category)
                } else {
                    self.expandedCategories.remove(category)
                }
            }
        )
        
        buildCollapsibleSection(
            title: category.rawValue,
            isExpanded: isExpanded,
            items: items,
            isCustomRoot: category == .custom
        )
    }
    
    @ViewBuilder
    private func buildCollapsibleSection(title: String, isExpanded: Binding<Bool>, items: [ScriptTemplate], isCustomRoot: Bool) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Buffer to allow the child cards to breathe inside the massive buttons natively
                Spacer().frame(height: 8)
                
                ForEach(items) { template in
                    buildCard(template: template)
                }
            }
        } label: {
            HStack {
                Text(title.uppercased())
                    .font(.system(.headline, design: .rounded, weight: .bold)) // Expanded greatly from tiny .caption
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.vertical, 16) // Substantial native tap-target, eliminating thin pills natively
            .padding(.horizontal, 16)
            .background(Color.hfAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)) // Structurally massive over .Capsule
        }
        .accentColor(.white) // Tints the dropdown chevron white perfectly
    }
    
    @ViewBuilder
    private func buildCustomTemplateTrigger() -> some View {
        Button(action: {
            isPresentingComposer = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Create Custom Template")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Spacer()
            }
            .foregroundStyle(Color.hfAccent)
            .padding()
            .background(Color.hfAccent.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.hfAccent.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(HFScaleButtonStyle())
    }
    
    @ViewBuilder
    private func buildTopHeader() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Script Templates")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.5))
                TextField("Search scripts, hooks, topics...", text: $searchText)
                    .foregroundStyle(.white)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(12)
            .background(Material.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.sm)
    }
    
    @ViewBuilder
    private func buildCategoryScrubber() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(TemplateCategory.allCases) { category in
                    let isSelected = (activeCategoryFilter == category)
                    
                    Button(action: {
                        withAnimation(.spring) {
                            if isSelected { activeCategoryFilter = nil } // Toggle off
                            else { activeCategoryFilter = category }
                        }
                    }) {
                        Text(category.rawValue)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.hfAccent : Color.white.opacity(0.1))
                            .foregroundStyle(isSelected ? .black : .white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
    
    @ViewBuilder
    private func buildCard(template: ScriptTemplate) -> some View {
        TemplateCardView(
            template: template,
            isFavorite: favoriteIDs.contains(template.id),
            toggleFavorite: {
                toggleFavoriteState(for: template.id)
            },
            action: {
                self.selectedTemplate = template
            }
        )
    }
    
    @ViewBuilder
    private func buildEmptyGraphic() -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            Text("No templates found matching your search.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 80)
    }
    
    // MARK: - Search Mathematics
    
    private func searchFilteredTemplates() -> [ScriptTemplate] {
        var base = templateManager.baseTemplates + storedCustomTemplates.map { $0.asScriptTemplate }
        
        if let filter = activeCategoryFilter {
            base = base.filter { $0.category == filter }
        }
        
        if !searchText.isEmpty {
            base = base.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.bodyPattern.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return base
    }
    
    // MARK: - Storage Management
    
    private func loadFavorites() {
        if let decoded = try? JSONDecoder().decode([UUID].self, from: favoriteTemplateData) {
            self.favoriteIDs = Set(decoded)
        }
    }
    
    private func toggleFavoriteState(for id: UUID) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        
        if let encoded = try? JSONEncoder().encode(Array(favoriteIDs)) {
            self.favoriteTemplateData = encoded
        }
    }
}
