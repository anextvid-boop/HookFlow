import Foundation
import SwiftData

@Model
public final class Script {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var bodyText: String
    public var scrollSpeed: Double
    public var fontSize: Double
    
    // Inverse relationship mapping back to the owning project
    public var project: HFProject?
    
    public init(id: UUID = UUID(), title: String, bodyText: String, scrollSpeed: Double = 1.0, fontSize: Double = 32.0) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.scrollSpeed = scrollSpeed
        self.fontSize = fontSize
    }
}
