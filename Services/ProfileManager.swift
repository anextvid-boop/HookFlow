import Foundation
import SwiftUI

/// ProfileManager is the intelligence engine of HookFlow V2.
/// It observes and persists the active CreatorPersona parameters natively, making them available everywhere 
/// in the app for instantaneous string interpolation formatting.
class ProfileManager: ObservableObject {
    
    // Persistent Storage Bounds
    @AppStorage("encodedPersonasData") private var encodedPersonasData: Data = Data()
    @AppStorage("activePersonaUUIDString") private var activePersonaUUIDString: String = ""
    
    // In-Memory Observable Arrays & UI Binding Targets
    @Published var personas: [CreatorPersona] = []
    @Published var activePersonaID: UUID?
    
    // Extracted bindings for explicit text-field attachment. Changes sink immediately into memory.
    @Published var creatorName: String = "" { didSet { syncActivePersonaState() } }
    @Published var businessName: String = "" { didSet { syncActivePersonaState() } }
    @Published var industryNiche: String = "" { didSet { syncActivePersonaState() } }
    @Published var targetAudience: String = "" { didSet { syncActivePersonaState() } }
    @Published var customerPainPoint: String = "" { didSet { syncActivePersonaState() } }
    @Published var coreOffer: String = "" { didSet { syncActivePersonaState() } }
    @Published var brandTone: String = "" { didSet { syncActivePersonaState() } }
    @Published var primaryCallToAction: String = "" { didSet { syncActivePersonaState() } }
    
    // Initialization block triggered upon environment injection natively
    init() {
        loadData()
        
        // If absolutely no profiles exist, instantiate a core default seamlessly.
        if personas.isEmpty {
            let initialPersona = CreatorPersona()
            personas.append(initialPersona)
            setActivePersona(id: initialPersona.id)
        } else if let activeID = activePersonaID {
            // Load the parameters from the active UUID securely
            if let target = personas.first(where: { $0.id == activeID }) {
                loadParameters(from: target)
            }
        }
    }
    
    // MARK: - Core Execution Methods
    
    /// Switches the overarching intelligence engine context to a specific persona.
    func setActivePersona(id: UUID) {
        guard let matchingPersona = personas.first(where: { $0.id == id }) else { return }
        self.activePersonaID = id
        self.activePersonaUUIDString = id.uuidString
        loadParameters(from: matchingPersona)
    }
    
    /// Pulls struct parameters down onto the flat @Published layers making them bindable by TextFields natively.
    private func loadParameters(from persona: CreatorPersona) {
        // Temporarily avoid firing observer sink-saves while pushing down updates
        self.creatorName = persona.creatorName
        self.businessName = persona.businessName
        self.industryNiche = persona.industryNiche
        self.targetAudience = persona.targetAudience
        self.customerPainPoint = persona.customerPainPoint
        self.coreOffer = persona.coreOffer
        self.brandTone = persona.brandTone
        self.primaryCallToAction = persona.primaryCallToAction
    }
    
    /// Re-evaluates target inputs aggressively pushing any textual mutations securely backwards up into the struct.
    private func syncActivePersonaState() {
        guard let activeID = activePersonaID,
              let index = personas.firstIndex(where: { $0.id == activeID }) else { return }
        
        personas[index].creatorName = creatorName
        personas[index].businessName = businessName
        personas[index].industryNiche = industryNiche
        personas[index].targetAudience = targetAudience
        personas[index].customerPainPoint = customerPainPoint
        personas[index].coreOffer = coreOffer
        personas[index].brandTone = brandTone
        personas[index].primaryCallToAction = primaryCallToAction
        
        saveData() // Push explicit mutation out to disk natively.
    }
    
    // MARK: - Serialization Pipeline
    
    private func loadData() {
        // 1. Fetch JSON Array Data
        if let decoded = try? JSONDecoder().decode([CreatorPersona].self, from: encodedPersonasData) {
            self.personas = decoded
        }
        // 2. Fetch Active Session Key
        if let uuid = UUID(uuidString: activePersonaUUIDString) {
            self.activePersonaID = uuid
        } else if !personas.isEmpty {
            self.activePersonaID = personas[0].id
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(personas) {
            self.encodedPersonasData = encoded
        }
    }
    
    // MARK: - Debug Vectors
    
    /// Wipes all memory caches, resetting the intelligence payload to baseline zeros accurately.
    func wipeProfile() {
        self.personas.removeAll()
        self.activePersonaID = nil
        self.activePersonaUUIDString = ""
        self.encodedPersonasData = Data()
        
        // Re-inject a clean sheet native state gracefully
        let clean = CreatorPersona()
        personas.append(clean)
        setActivePersona(id: clean.id)
    }
    
    // MARK: - Intelligent Extrapolation Fallbacks
    
    var industryNicheOrDefault: String {
        let trimmed = industryNiche.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your industry" : trimmed
    }
    
    var targetAudienceOrDefault: String {
        let trimmed = targetAudience.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your audience" : trimmed
    }
    
    var customerPainPointOrDefault: String {
        let trimmed = customerPainPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "a specific problem" : trimmed
    }
    
    var businessNameOrDefault: String {
        let trimmed = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "my business" : trimmed
    }
    
    var creatorNameOrDefault: String {
        let trimmed = creatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "my name" : trimmed
    }
    
    var coreOfferOrDefault: String {
        let trimmed = coreOffer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "my product" : trimmed
    }
    
    var brandToneOrDefault: String {
        let trimmed = brandTone.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "professional" : trimmed
    }
    
    var primaryCallToActionOrDefault: String {
        let trimmed = primaryCallToAction.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "link in bio" : trimmed
    }
    
    // MARK: - Template System Context Injection
    
    /// Generates a strict system prompt prefix injecting all current commercial parameters.
    /// This acts as the intelligence foundation for the AI Template Builder engine (Phase 8).
    func generateSystemPromptContext() -> String {
        return """
        You are writing a script for \(creatorNameOrDefault) at \(businessNameOrDefault), operating in the \(industryNicheOrDefault) space. Their target audience is \(targetAudienceOrDefault) suffering from \(customerPainPointOrDefault). Highlight their \(coreOfferOrDefault) and direct users to \(primaryCallToActionOrDefault). Ensure tone is \(brandToneOrDefault).
        """
    }
}
