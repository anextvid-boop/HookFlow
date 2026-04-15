import Foundation
import Photos

public actor StorageManager {
    public static let shared = StorageManager()
    
    private init() {}
    
    /// Generate the foundation document bucket
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// DRAFT SANDBOXING: Locates or generates the distinct URL bucket for a single project.
    /// This prevents multiple drafts from overlapping files.
    public func getDraftDirectory(for draftDirectoryName: String) throws -> URL {
        let docs = getDocumentsDirectory()
        let draftURL = docs.appendingPathComponent(draftDirectoryName, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: draftURL.path) {
            try FileManager.default.createDirectory(at: draftURL, withIntermediateDirectories: true, attributes: nil)
        }
        return draftURL
    }
    
    /// Stitch the string path back into a physical URL for AVFoundation to consume
    public func resolveURL(for relativePath: String, in draftDirectoryName: String) throws -> URL {
        let draftURL = try getDraftDirectory(for: draftDirectoryName)
        return draftURL.appendingPathComponent(relativePath)
    }
    
    /// Memory hygiene: Run this before recording or after exporting to guarantee the volatile 
    /// local tmp folder doesn't destroy the user's hard drive space.
    public func purgeTemporaryFiles() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        
        for file in contents {
            try? FileManager.default.removeItem(at: file)
        }
    }
    
    
    /// Destroys a local drafted bucket and all of its underlying segmented chunks completely.
    public func deleteDraft(draftDirectoryName: String) throws {
        let draftURL = try getDraftDirectory(for: draftDirectoryName)
        if FileManager.default.fileExists(atPath: draftURL.path) {
            try FileManager.default.removeItem(at: draftURL)
        }
    }
    
    /// By running this fully inside the Actor context, the Main thread allows the UI Editor
    /// to remain fluid at 120FPS while the heavy disk I/O hits the camera roll asynchronously.
    public func saveToCameraRoll(videoURL: URL) async throws {
        _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .video, fileURL: videoURL, options: nil)
        }
    }
}
