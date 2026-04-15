import SwiftUI
import SwiftData

@main
struct HookFlowApp: App {
    // Decoupled Router injection
    @State private var router = AppRouter()
    
    // Core Intelligence Engine
    @StateObject private var profileManager = ProfileManager()
    
    // Core Template Data Source
    @StateObject private var templateManager = TemplateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .environmentObject(profileManager)
                .environmentObject(templateManager)
                // Safely inject the SwiftData ModelContainer ensuring absolute disk persistence for drafts
                .modelContainer(DependencyRegistry.shared.modelContainer)
                // Phase 13.3 Root Theme Restriction: Lock cinematography aesthetics universally
                .preferredColorScheme(.dark)
                .task {
                    // SECURE STORE KIT INITIALIZATION: Ensure you place your active RC Public Key here before archiving!
                    await SubscriptionService.shared.initializeRevenueCat(apiKey: "appl_YOUR_RC_KEY_HERE")
                }
        }
    }
}
