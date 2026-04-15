import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                appRoot
                    .transition(.opacity)
            }
        }
        .animation(.default, value: hasCompletedOnboarding)
        .preferredColorScheme(.dark) // Total spatial immersion
    }
    
    @ViewBuilder
    private var appRoot: some View {
        // Enforce Bindable for the deeply watched navigationPath
        @Bindable var bindableRouter = router
        
        ZStack {
            // Instant load zero-hitch Dashboard Hub
            HomeHubView()
                .zIndex(0)
            
            if let activeRoute = router.navigationPath.last {
                Group {
                    switch activeRoute {
                    case .dashboard:
                        HomeHubView()
                    case .studio(let projectId):
                        StudioView(projectId: projectId)
                    case .editor(let projectId):
                        EditorView(projectId: projectId)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: router.navigationPath)
        // Deeply bind the Settings sheet physically
        .sheet(item: Binding<AppRouter.Sheet?>(
            get: { bindableRouter.activeSheet == .settings ? .settings : nil },
            set: { newValue in if newValue == nil { bindableRouter.activeSheet = nil } }
        )) { _ in
            SettingsView()
        }
        // Push the Paywall immediately as a full-screen high conversion takeover
        .fullScreenCover(item: Binding<AppRouter.Sheet?>(
            get: { bindableRouter.activeSheet == .paywall ? .paywall : nil },
            set: { newValue in if newValue == nil { bindableRouter.activeSheet = nil } }
        )) { _ in
            PaywallView()
        }
    }
}
