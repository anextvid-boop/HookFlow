import Foundation
import SwiftData

/// Represents a distinct user profile specifically tailored to a single niche or target audience.
/// This allows agency users or multi-brand creators to save entirely different content parameters
/// and swap between them instantly inside the Home Hub without deleting their app storage.
struct CreatorPersona: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    
    // Core Extrapolation Data Points
    var creatorName: String
    var businessName: String
    var industryNiche: String
    var targetAudience: String
    var customerPainPoint: String
    var coreOffer: String
    var brandTone: String
    var primaryCallToAction: String
    
    init(id: UUID = UUID(), creatorName: String = "", businessName: String = "", industryNiche: String = "", targetAudience: String = "", customerPainPoint: String = "", coreOffer: String = "", brandTone: String = "", primaryCallToAction: String = "") {
        self.id = id
        self.creatorName = creatorName
        self.businessName = businessName
        self.industryNiche = industryNiche
        self.targetAudience = targetAudience
        self.customerPainPoint = customerPainPoint
        self.coreOffer = coreOffer
        self.brandTone = brandTone
        self.primaryCallToAction = primaryCallToAction
    }
}
