import Foundation

public enum RecordingQuality: String, Codable, Sendable {
    case hd720p
    case hd1080p
    case uhd4k
}

public enum ExportSettings: String, Codable, Sendable {
    case standard
    case cinematic
}

/// A sendable, value-typed representation of a single spoken word and its temporal bounds.
public struct CaptionToken: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var startTime: TimeInterval
    public var endTime: TimeInterval
    
    public init(id: UUID = UUID(), text: String, startTime: TimeInterval, endTime: TimeInterval) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
}

public enum VideoTransitionType: String, Codable, Sendable, CaseIterable {
    case none = "None"
    case crossDissolve = "Cross Dissolve"
    case fadeToBlack = "Fade to Black"
    case dipToWhite = "Dip to White"
}

/// A strictly value-typed, sendable struct ensuring thread-safety across concurrent contexts.
/// We do NOT store media blobs here. Only relative file paths managed by StorageManager.
public struct VideoSegment: Codable, Sendable, Identifiable {
    public let id: UUID
    public let relativeVideoPath: String
    public let relativeThumbnailPath: String?
    public let duration: TimeInterval
    public let creationDate: Date
    public var startTrim: TimeInterval
    public var endTrim: TimeInterval?
    public var captionTokens: [CaptionToken]?
    public var playbackSpeed: Double
    public var bRollRelativePath: String?
    public var outTransition: VideoTransitionType // Phase 9
    public var outTransitionDuration: TimeInterval // Phase 9
    
    // Phase 11: Color Grading
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double
    
    // Phase 6.2: Audio Deck
    public var volume: Double
    
    // Phase 15: Canvas Transform
    public var scale: Double
    public var offsetX: Double
    public var offsetY: Double
    public var rotation: Double
    
    public var assetURL: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // In this architecture, actual URL is derived dynamically via StorageManager logic.
        return docs.appendingPathComponent("Drafts/\(relativeVideoPath)")
    }
    
    public init(id: UUID = UUID(), relativeVideoPath: String, relativeThumbnailPath: String? = nil, duration: TimeInterval, creationDate: Date = Date(), startTrim: TimeInterval = 0.0, endTrim: TimeInterval? = nil, captionTokens: [CaptionToken]? = nil, playbackSpeed: Double = 1.0, bRollRelativePath: String? = nil, outTransition: VideoTransitionType = .none, outTransitionDuration: TimeInterval = 0.5, brightness: Double = 0.0, contrast: Double = 1.0, saturation: Double = 1.0, volume: Double = 1.0, scale: Double = 1.0, offsetX: Double = 0.0, offsetY: Double = 0.0, rotation: Double = 0.0) {
        self.id = id
        self.relativeVideoPath = relativeVideoPath
        self.relativeThumbnailPath = relativeThumbnailPath
        self.duration = duration
        self.creationDate = creationDate
        self.startTrim = startTrim
        self.endTrim = endTrim
        self.captionTokens = captionTokens
        self.playbackSpeed = playbackSpeed
        self.bRollRelativePath = bRollRelativePath
        self.outTransition = outTransition
        self.outTransitionDuration = outTransitionDuration
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.volume = volume
        self.scale = scale
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.rotation = rotation
    }
}

// Added to handle PhotoPicker imports internally
import CoreTransferable

struct MovieTransfer: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}
