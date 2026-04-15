import Foundation

/// Defines the native Extension parsing mechanics to decouple string manipulation off the View threads naturally.
extension String {
    
    /// Interpolates HookFlow profile syntax natively replacing matched bracket instances precisely with User configurations.
    func hydrate(with profile: ProfileManager) -> String {
        var baseString = self
        
        // Explicitly map properties directly natively avoiding Regex bloat where possible.
        baseString = baseString.replacingOccurrences(of: "[INDUSTRY_NICHE]", with: profile.industryNicheOrDefault)
        baseString = baseString.replacingOccurrences(of: "[TARGET_AUDIENCE]", with: profile.targetAudienceOrDefault)
        baseString = baseString.replacingOccurrences(of: "[PAIN_POINT]", with: profile.customerPainPointOrDefault)
        baseString = baseString.replacingOccurrences(of: "[CORE_OFFER]", with: profile.coreOfferOrDefault)
        baseString = baseString.replacingOccurrences(of: "[BUSINESS_NAME]", with: profile.businessNameOrDefault)
        baseString = baseString.replacingOccurrences(of: "[BRAND_TONE]", with: profile.brandToneOrDefault)
        baseString = baseString.replacingOccurrences(of: "[PRIMARY_CTA]", with: profile.primaryCallToActionOrDefault)
        
        return baseString
    }
}
