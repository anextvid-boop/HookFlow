import Foundation

// Assuming RevenueCat is added via Swift Package Manager to the target
import RevenueCat

/// Isolated Actor preventing network-heavy receipt validation and catalog fetching from locking the UI 
/// or, critically, interfering with background video export streams.
@globalActor
public actor SubscriptionActor {
    public static let shared = SubscriptionActor()
}

@Observable
public final class SubscriptionService: @unchecked Sendable {
    public static let shared = SubscriptionService()
    
    public var isProActive: Bool = false
    public var availablePackages: [Package] = []
    
    public init() {}
    
    /// Called passively at app launch out-of-band.
    @SubscriptionActor
    public func initializeRevenueCat(apiKey: String) async {
        Purchases.configure(withAPIKey: apiKey)
        await refreshEntitlements()
        await fetchOfferings()
    }
    
    @SubscriptionActor
    public func refreshEntitlements() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            // Assumes standard "pro" entitlement identifier
            let isActive = customerInfo.entitlements.all["pro"]?.isActive == true
            await MainActor.run {
                self.isProActive = isActive
            }
        } catch {
            print("RevenueCat Entitlement Refresh Error: \(error)")
        }
    }
    
    @SubscriptionActor
    public func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                await MainActor.run {
                    self.availablePackages = current.availablePackages
                }
            }
        } catch {
            print("RevenueCat Fetch Offerings Error: \(error)")
        }
    }
    
    @SubscriptionActor
    public func purchase(package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        let isActive = result.customerInfo.entitlements.all["pro"]?.isActive == true
        await MainActor.run {
            self.isProActive = isActive
        }
        return isActive
    }
    
    @SubscriptionActor
    public func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        let isActive = customerInfo.entitlements.all["pro"]?.isActive == true
        await MainActor.run {
            self.isProActive = isActive
        }
        return isActive
    }
}
