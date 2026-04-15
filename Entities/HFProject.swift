import Foundation
import SwiftData

@Model
public final class HFProject {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var creationDate: Date
    public var lastModifiedDate: Date
    
    // DRAFT SANDBOXING: The isolated folder name assigned to this specific draft
    public var draftDirectoryName: String 
    
    // By exclusively storing value-typed paths rather than monolithic `Data` blobs, 
    // the SwiftData footprint remains infinitely microscopic.
    public var videoSegments: [VideoSegment]
    
    // CASCADE DELETE: When this project is deleted from the Hub, immediately destroy the script.
    @Relationship(deleteRule: .cascade, inverse: \Script.project)
    public var script: Script?
    
    // Phase 2D: Global Vibe Music Track
    public var relativeVibeMusicPath: String?
    public var vibeMusicVolume: Double
    
    public init(id: UUID = UUID(), title: String, draftDirectoryName: String? = nil, relativeVibeMusicPath: String? = nil, vibeMusicVolume: Double = 0.1) {
        self.id = id
        self.title = title
        self.creationDate = Date()
        self.lastModifiedDate = Date()
        self.relativeVibeMusicPath = relativeVibeMusicPath
        self.vibeMusicVolume = vibeMusicVolume
        
        // Ensure each draft gets its own distinct physics boundary on disk
        self.draftDirectoryName = draftDirectoryName ?? "HookFlow_Draft_\(id.uuidString)"
        self.videoSegments = []
    }
}
