import Foundation
import SwiftData

@Model
public final class CustomTemplate {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var bodyPattern: String
    public var creationDate: Date
    
    public init(id: UUID = UUID(), title: String, bodyPattern: String, creationDate: Date = Date()) {
        self.id = id
        self.title = title
        self.bodyPattern = bodyPattern
        self.creationDate = creationDate
    }
    
    // Extrapolate this back to the baseline structural model instantly for Universal DOM binding.
    var asScriptTemplate: ScriptTemplate {
        ScriptTemplate(
            id: self.id,
            title: self.title,
            description: "Custom Template created on \(self.creationDate.formatted(date: .abbreviated, time: .omitted))",
            bodyPattern: self.bodyPattern,
            category: .custom
        )
    }
}
