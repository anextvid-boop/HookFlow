import SwiftUI
import SwiftData
import AVFoundation

public struct DashboardView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    
    // Fetch projects sorted by creation date, entirely decoupled from Main Thread locking
    @Query(sort: \HFProject.lastModifiedDate, order: .reverse) 
    private var projects: [HFProject]
    
    @State private var hasAppeared: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    
                    // Header
                    HStack {
                        Text("Drafts")
                            .font(HFTypography.display(size: 40))
                            .foregroundColor(.hfTextPrimary)
                        Spacer()
                        
                        Button(action: { router.presentSheet(.settings) }) {
                            Image(systemName: "gearshape.fill")
                                .font(HFTypography.title(size: 24))
                                .foregroundColor(.hfTextSecondary)
                                .padding(.trailing, DesignTokens.Spacing.sm)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.xl)
                    
                    // Glassmorphic Draft Grid
                    if projects.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), 
                            GridItem(.flexible(), spacing: DesignTokens.Spacing.sm)
                        ], spacing: DesignTokens.Spacing.md) {
                            ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                                ProjectCard(project: project)
                                    .opacity(hasAppeared ? 1 : 0)
                                    .offset(y: hasAppeared ? 0 : 15)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(min(index, 10)) * 0.05), value: hasAppeared)
                                    .onTapGesture {
                                        router.navigate(to: .studio(projectId: project.id.uuidString))
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            let draftName = project.draftDirectoryName
                                            modelContext.delete(project)
                                            Task.detached {
                                                try? await StorageManager.shared.deleteDraft(draftDirectoryName: draftName)
                                            }
                                        } label: {
                                            Label("Delete Draft", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .onAppear {
                            hasAppeared = true
                        }
                    }
                }
                .padding(.bottom, 150)
        }
        .background {
            HFAmbientAura()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "film.fill")
                .font(.system(size: 48))
                .foregroundColor(.hfTextTertiary)
            
            Text("No projects yet.")
                .font(HFTypography.body())
                .foregroundColor(.hfTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// Sub-component implicitly preventing macro-view state invalidation
fileprivate struct ProjectCard: View {
    let project: HFProject
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // Phase 6.1 Card Dimensions & Layout
            Group {
                if let thumb = thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .aspectRatio(9/16, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .aspectRatio(9/16, contentMode: .fit)
                        .overlay {
                            Image(systemName: "video.fill")
                                .foregroundColor(.hfTextTertiary)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
            
            Text(project.title)
                .font(HFTypography.callout())
                .foregroundColor(.hfTextPrimary)
                .lineLimit(1)
            
            Text(project.lastModifiedDate.formatted(date: .abbreviated, time: .shortened))
                .font(HFTypography.caption())
                .foregroundColor(.hfTextTertiary)
        }
        // Invoking the universal spatial blurring macro
        .hfGlassmorphic(padding: DesignTokens.Spacing.xs, cornerRadius: DesignTokens.Radius.md)
        .task {
            // Phase 6.2 Thumbnail Extraction Engine
            if let videoSegment = project.videoSegments.first {
                guard let videoURL = try? await StorageManager.shared.resolveURL(for: videoSegment.relativeVideoPath, in: project.draftDirectoryName) else { return }
                
                do {
                    let asset = AVAsset(url: videoURL)
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.maximumSize = CGSize(width: 300, height: 300) 
                    
                    let cgImage = try await generator.image(at: .zero).image
                    await MainActor.run {
                        self.thumbnail = UIImage(cgImage: cgImage)
                    }
                } catch {
                    print("Thumbnail generation failed: \(error)")
                }
            }
        }
    }
}

public enum HomeTab: Int, CaseIterable {
    case drafts = 0
    case templates = 1
    case profile = 2
    
    var iconName: String {
        switch self {
        case .drafts: return "film.fill"
        case .templates: return "doc.plaintext.fill"
        case .profile: return "person.fill"
        }
    }
}


public struct HomeHubView: View {
    @State private var selectedTab: HomeTab = .drafts
    @State private var previousTab: HomeTab = .drafts
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Namespace private var tabAnimationNamespace
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Main Content Area
            ZStack {

                let isMovingRight = selectedTab.rawValue > previousTab.rawValue
                let direction: AnyTransition = .asymmetric(
                    insertion: .move(edge: isMovingRight ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: isMovingRight ? .leading : .trailing).combined(with: .opacity)
                )

                switch selectedTab {
                case .drafts:
                    DashboardView() // Transformed from root to a tab view
                        .transition(direction)
                case .templates:
                    TemplateBuilderView()
                        .transition(direction)
                case .profile:
                    UserProfileView()
                        .transition(direction)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            .padding(.bottom, 80) // Pad above the custom tab bar
            
            // Custom Floating Tab Bar
            VStack {
                Spacer()
                customTabBar
                    .padding(.bottom, DesignTokens.Spacing.md)
            }
        }
        .background {
            HFAmbientAura()
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(for: .templates)
            
            Spacer()
            
            tabButton(for: .drafts)
            
            Spacer()
            
            // Middle Focus - The Creation Hub
            Button(action: createNewDraft) {
                ZStack {
                    Circle()
                        .fill(Color.hfAccent)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.hfAccent.opacity(0.4), radius: 10, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(HFScaleButtonStyle())
            // Floating safely above
            .offset(y: -15) 
            
            Spacer()
            
            tabButton(for: .profile)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        // Frosted glassmorphism background
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .background(Material.ultraThinMaterial)
                .clipShape(Capsule())
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
    }
    
    private func tabButton(for tab: HomeTab) -> some View {
        Button(action: {
            if selectedTab != tab {
                previousTab = selectedTab
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == tab ? .hfAccent : .gray.opacity(0.7))
                
                if selectedTab == tab {
                    Circle()
                        .fill(Color.hfAccent)
                        .frame(width: 4, height: 4)
                        .matchedGeometryEffect(id: "activeTab", in: tabAnimationNamespace)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func createNewDraft() {
        let newProject = HFProject(title: "New Draft")
        // Immediate background context commit via SwiftData
        modelContext.insert(newProject)
        // Automatically route to Studio when created
        router.navigate(to: .studio(projectId: newProject.id.uuidString))
    }
}
