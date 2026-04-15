import Foundation
import SwiftData

/// The absolute source of truth for ModelContainer injection. 
/// Abstracting this away from `HookFlowApp` guarantees our dependency layer is safe, 
/// testable, and completely decoupled from SwiftUI structural limits.
@MainActor
public final class DependencyRegistry {
    public static let shared = DependencyRegistry()
    
    public let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([
            HFProject.self,
            Script.self,
            UserScriptGroup.self,
            UserScript.self,
            CustomTemplate.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false // We must persist everything to disk for Draft generation
        )
        
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("Successfully initialized SwiftData ModelContainer.")
        } catch {
            print("CRITICAL: Failed to initialize SwiftData ModelContainer: \(error). Attempting to wipe local data store to recover...")
            
            // CoreData/SwiftData uses 'default.store' by default in the Application Support directory.
            // On a migration from V1 (CoreData) to V2 (SwiftData) with the same bundle ID, this crashes instantly.
            let appSupportDir = URL.applicationSupportDirectory
            let storeURL = appSupportDir.appendingPathComponent("default.store")
            let shmURL = appSupportDir.appendingPathComponent("default.store-shm")
            let walURL = appSupportDir.appendingPathComponent("default.store-wal")
            
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: shmURL)
            try? FileManager.default.removeItem(at: walURL)
            
            do {
                self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("Successfully recovered and rebuilt SwiftData ModelContainer.")
            } catch {
                fatalError("CRITICAL EXCEPTION: Failed to initialize SwiftData ModelContainer even after factory reset: \(error)")
            }
        }
    }
}
