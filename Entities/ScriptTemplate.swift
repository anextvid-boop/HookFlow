import Foundation

/// Core Enum dictating the architectural taxonomies mapped securely for Template filtering.
enum TemplateCategory: String, CaseIterable, Identifiable, Codable {
    case ugc = "UGC & Hook Frameworks"
    case directResponse = "Direct Response & Sales"
    case educational = "Educational & Presentation"
    case growth = "Growth & Networking"
    case vlog = "Vlog & Storytelling"
    case listicle = "Listicles & Quick-Hits"
    case custom = "My Templates"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .ugc: return "iphone"
        case .directResponse: return "megaphone.fill"
        case .educational: return "books.vertical.fill"
        case .growth: return "network"
        case .vlog: return "video.fill"
        case .listicle: return "list.bullet.rectangle.portrait.fill"
        case .custom: return "folder.fill"
        }
    }
}

/// The fundamental, robust intelligence struct mapping templates instantly into the UI engine.
/// Conforms to Codable and Hashable natively preventing mapping mismatches during arrays.
struct ScriptTemplate: Identifiable, Hashable, Codable {
    var id: UUID
    var title: String
    var description: String
    var bodyPattern: String
    var category: TemplateCategory
    
    init(id: UUID = UUID(), title: String, description: String, bodyPattern: String, category: TemplateCategory) {
        self.id = id
        self.title = title
        self.description = description
        self.bodyPattern = bodyPattern
        self.category = category
    }
}
