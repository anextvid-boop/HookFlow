import SwiftUI

/// App Store Compliance hub. Crucial location for Restore Purchases, EULA, and Subscription Toggling.
public struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    let subscriptionService = SubscriptionService.shared
    
    // UI state to prevent duplicate taps
    @State private var isRestoring = false
    @State private var restoreMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.hfBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                        
                        // Actionable Glassmorphic Group
                        VStack(spacing: 0) {
                            settingsRow(title: "HookFlow Pro", subtitle: "Manage your 4K subscription") {
                                router.dismissSheet()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    router.presentSheet(.paywall)
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            settingsRow(title: "Restore Purchases", subtitle: isRestoring ? "Checking..." : (restoreMessage ?? "If you got a new device")) {
                                restorePurchases()
                            }
                            
                            #if DEBUG
                            Divider().background(Color.white.opacity(0.1))
                            
                            settingsRow(title: "Reset Onboarding", subtitle: "Developer: Trigger initial launch flow") {
                                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                                router.popToRoot()
                            }
                            #endif
                        }
                        .hfGlassmorphic(padding: 0, cornerRadius: DesignTokens.Radius.md)
                        
                        // Legal & Compliance Rules for App Store
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("LEGAL")
                                .font(HFTypography.caption())
                                .foregroundColor(.hfTextTertiary)
                                .padding(.leading, DesignTokens.Spacing.sm)
                            
                            VStack(spacing: 0) {
                                legalRow(title: "Terms of Use (EULA)", url: "https://hookflow.app/terms")
                                Divider().background(Color.white.opacity(0.1))
                                legalRow(title: "Privacy Policy", url: "https://hookflow.app/privacy")
                            }
                            .hfGlassmorphic(padding: 0, cornerRadius: DesignTokens.Radius.md)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { router.dismissSheet() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.hfTextSecondary)
                    }
                }
            }
        }
    }
    
    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true
        
        Task {
            let success = (try? await subscriptionService.restorePurchases()) ?? false
            await MainActor.run {
                self.isRestoring = false
                self.restoreMessage = success ? "Successfully Restored" : "No Purchases Found"
            }
        }
    }
    
    private func settingsRow(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(HFTypography.body()).foregroundColor(.hfTextPrimary)
                    Text(subtitle).font(HFTypography.caption()).foregroundColor(.hfTextTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.hfTextTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .contentShape(Rectangle())
        }
    }
    
    private func legalRow(title: String, url: String) -> some View {
        Button(action: {
            if let link = URL(string: url) { UIApplication.shared.open(link) }
        }) {
            HStack {
                Text(title).font(HFTypography.body()).foregroundColor(.hfTextPrimary)
                Spacer()
                Image(systemName: "link").foregroundColor(.hfTextTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .contentShape(Rectangle())
        }
    }
}
