import SwiftUI
import Observation

@Observable
public final class AppRouter {
    public enum Route: Hashable {
        case dashboard
        case studio(projectId: String)
        case editor(projectId: String)
    }
    
    public enum Sheet: Identifiable {
        case paywall
        case settings
        public var id: String { String(describing: self) }
    }
    
    public var navigationPath: [Route] = []
    public var activeSheet: Sheet?
    
    public init() {}
    
    public func navigate(to route: Route) {
        navigationPath.append(route)
    }
    
    public func popToRoot() {
        navigationPath.removeAll()
    }
    
    public func presentSheet(_ sheet: Sheet) {
        self.activeSheet = sheet
    }
    
    public func dismissSheet() {
        self.activeSheet = nil
    }
}
