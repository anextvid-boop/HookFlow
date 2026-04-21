import Foundation
import SwiftData

@Model
public final class UserScriptGroup {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var creationDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \UserScript.group)
    public var scripts: [UserScript]
    
    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.creationDate = Date()
        self.scripts = []
    }
}

@Model
public final class UserScript {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var content: String
    public var lastEdited: Date
    public var orderIndex: Int
    public var isEditable: Bool
    
    public var group: UserScriptGroup?
    
    public init(id: UUID = UUID(), title: String, content: String, orderIndex: Int = 0, isEditable: Bool = true) {
        self.id = id
        self.title = title
        self.content = content
        self.lastEdited = Date()
        self.orderIndex = orderIndex
        self.isEditable = isEditable
    }
}
