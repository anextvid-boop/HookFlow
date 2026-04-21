import SwiftUI
import RevenueCat

/// High-conversion, physically lightweight Paywall preventing access to exports until Pro is unlocked.
/// Banning heavy videos here ensures it loads instantaneously.
public struct PaywallView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    
    private let subscriptionService = SubscriptionService.shared
    @State private var isPurchasing = false
    
    // Using a String for selection to map unified state between RevenueCat or Mock Strings
    @State private var selectedPackageId: String? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.hfBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Top Header actions
                HStack {
                    Spacer()
                    Button(action: closePaywall) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, 8)
                
                Spacer(minLength: 4)
                
                // Locked Core Offer (No ScrollView)
                VStack(spacing: 0) {
                    
                    // V1 Crown Header
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.hfAccent)
                        .padding(14)
                        .background(Color.hfAccent.opacity(0.15))
                        .clipShape(Circle())
                        .padding(.bottom, 6)
                    
                    Text("HOOKFLOW PRO")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                    
                    Text("Take your content further")
                        .font(.system(size: 14))
                        .foregroundColor(.hfTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 12)
                    
                    // Features List matching V1
                    VStack(alignment: .leading, spacing: 6) {
                        FeatureRow(icon: "doc.plaintext.fill", text: "Unlimited Scripts", isChecked: true)
                        FeatureRow(icon: "folder.fill", text: "Unlimited Projects", isChecked: true)
                        FeatureRow(icon: "4k.tv.fill", text: "4K Video Recording", isChecked: true)
                        FeatureRow(icon: "eye.slash.fill", text: "No Watermark", isChecked: true)
                        FeatureRow(icon: "text.bubble.fill", text: "Auto Captions (AI)", isChecked: false, customBadge: "PRO")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    Spacer(minLength: 4)
                    
                    // Pricing Modules
                    VStack(spacing: 8) {
                        if subscriptionService.availablePackages.isEmpty {
                            // High Fidelity Mock State so UI never hangs in Simulator 
                            PricingCard(
                                title: "Creator — Monthly",
                                priceWithDuration: "£8.99 / month",
                                subtitle: "Flexible monthly billing.",
                                isAccent: selectedPackageId == "mock_creator_monthly",
                                showBestValue: false,
                                saveBadge: nil
                            )
                            .onTapGesture { selectedPackageId = "mock_creator_monthly" }
                            
                            PricingCard(
                                title: "Creator — Yearly",
                                priceWithDuration: "£49.99 / year",
                                subtitle: "Most popular. Billed annually.",
                                isAccent: selectedPackageId == "mock_creator_yearly",
                                showBestValue: true,
                                saveBadge: "SAVE 50%"
                            )
                            .onTapGesture { selectedPackageId = "mock_creator_yearly" }
                            
                            PricingCard(
                                title: "Creator — Lifetime",
                                priceWithDuration: "£149.99 / lifetime",
                                subtitle: "One-time payment. Yours forever.",
                                isAccent: selectedPackageId == "mock_creator_lifetime",
                                showBestValue: false,
                                saveBadge: nil
                            )
                            .onTapGesture { selectedPackageId = "mock_creator_lifetime" }
                        } else {
                            // Real RevenueCat State
                            ForEach(subscriptionService.availablePackages, id: \.identifier) { package in
                                let isAnnual = package.packageType == .annual
                                let isLifetime = package.packageType == .lifetime
                                let durationString = isLifetime ? "lifetime" : (isAnnual ? "year" : "month")
                                let subtitleString = isLifetime ? "One-time payment. Yours forever." : (isAnnual ? "Most popular. Billed annually." : "Flexible billing. Cancel anytime.")
                                
                                PricingCard(
                                    title: package.storeProduct.localizedTitle,
                                    priceWithDuration: "\(package.localizedPriceString) / \(durationString)",
                                    subtitle: subtitleString,
                                    isAccent: selectedPackageId == package.identifier,
                                    showBestValue: isAnnual,
                                    saveBadge: isAnnual ? "BEST VALUE" : nil
                                )
                                .onTapGesture {
                                    selectedPackageId = package.identifier
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
                .onAppear {
                    if let first = subscriptionService.availablePackages.first {
                        selectedPackageId = first.identifier
                    } else if selectedPackageId == nil {
                        selectedPackageId = "mock_creator_yearly"
                    }
                }
                
                Spacer(minLength: 8)
                
                // Real Purchase Trigger - Rigidly pinned at bottom
                VStack(spacing: 6) {
                    let isSelectingLifetime = selectedPackageId == "mock_creator_lifetime" || subscriptionService.availablePackages.first(where: { $0.identifier == selectedPackageId })?.packageType == .lifetime
                    
                    Button(action: executePurchase) {
                        HStack {
                            if isPurchasing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .padding(.trailing, 4)
                            }
                            Text(isPurchasing ? "Processing..." : (isSelectingLifetime ? "Unlock Forever" : "Start 7-Day Free Trial"))
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.hfAccent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                    }
                    .buttonStyle(HFScaleButtonStyle())
                    .disabled(selectedPackageId == nil || isPurchasing)
                    
                    Text(isSelectingLifetime ? "One-time payment unlocks all features permanently." : "7 days free, then auto-renews according to the selected plan.")
                        .font(.system(size: 10))
                        .foregroundColor(.hfTextSecondary)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, 4)
                
                // Footers
                HStack(spacing: DesignTokens.Spacing.xl) {
                    Link("Terms of Use", destination: URL(string: "https://anextvid-boop.github.io/HookFlow-Webpage/terms.html")!)
                        .font(.system(size: 10))
                        .foregroundColor(.hfTextTertiary)
                    
                    Button("Restore Purchases") {
                        guard !isPurchasing else { return }
                        isPurchasing = true
                        Task {
                            do {
                                let success = try await subscriptionService.restorePurchases()
                                await MainActor.run {
                                    self.isPurchasing = false
                                    if success {
                                        dismiss()
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    self.isPurchasing = false
                                    print("Restore failed: \(error)")
                                }
                            }
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.hfTextTertiary)
                    
                    Link("Privacy Policy", destination: URL(string: "https://anextvid-boop.github.io/HookFlow-Webpage/privacy.html")!)
                        .font(.system(size: 10))
                        .foregroundColor(.hfTextTertiary)
                }
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                HFAmbientAura()
            }
        }
    }
    
    private func closePaywall() {
        dismiss()
    }
    
    private func executePurchase() {
        guard let pkgId = selectedPackageId, !isPurchasing else { return }
        isPurchasing = true
        
        let targetPackage = subscriptionService.availablePackages.first(where: { $0.identifier == pkgId })
        
        guard let pkg = targetPackage else {
            // Mock resolution path if RevenueCat array is empty
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isPurchasing = false
                dismiss() // Grant access artificially for UI test flow
            }
            return
        }
        
        Task {
            do {
                let success = try await subscriptionService.purchase(package: pkg)
                await MainActor.run {
                    self.isPurchasing = false
                    if success {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isPurchasing = false
                    print("Purchase failed: \(error)")
                }
            }
        }
    }
}

/// Helper block for bulleted checklists matching V1 aesthetic
private struct FeatureRow: View {
    let icon: String
    let text: String
    let isChecked: Bool
    var customBadge: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.hfAccent)
                .font(.system(size: 14))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            if isChecked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.hfAccent)
                    .font(.system(size: 14, weight: .bold))
            } else if let badge = customBadge {
                Text(badge)
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.hfAccent)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

/// Generic container matching the premium `hfGlassmorphic` style mathematically, enhanced for V1 inverted layout.
private struct PricingCard: View {
    let title: String
    let priceWithDuration: String
    let subtitle: String
    let isAccent: Bool
    let showBestValue: Bool
    let saveBadge: String?
    
    @State private var isPulsing = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // VStack aligned leading with Stacked Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if showBestValue {
                        Text("BEST VALUE")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.hfAccent) // Solid red background
                            .foregroundColor(.white) // Crisp white text
                            .clipShape(Capsule())
                            .scaleEffect(isPulsing ? 1.05 : 0.95)
                            .opacity(isPulsing ? 1.0 : 0.8)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    isPulsing = true
                                }
                            }
                    }
                }
                
                Text(priceWithDuration)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            // By NOT giving this a layout priority, it occupies natural remaining space.
            
            Spacer(minLength: 2)
            
            // Radio Indicator on trailing edge
            Image(systemName: isAccent ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isAccent ? .hfAccent : .white.opacity(0.4))
                .font(.system(size: 24))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isAccent ? Color.hfAccent.opacity(0.1) : Color.hfSurface)
        // Ensure strictly mathematical corner radii overlay to match premium footprint
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(isAccent ? Color.hfAccent : Color.white.opacity(0.1), lineWidth: 2)
        )
    }
}
