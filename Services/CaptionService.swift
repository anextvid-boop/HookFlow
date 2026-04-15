import Foundation
import Speech

/// Sub-engine decoupled from the script UI handling raw SFSpeech logic asynchronously to avoid stalling scroll frame rates.
public final class CaptionService: Sendable {
    
    public init() {}
    
    /// Executes transcription perfectly off-thread, preventing heavy NLP models from interrupting AV Foundation capture loops.
    public func transcribeAudio(from url: URL) async throws -> [CaptionToken] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
                continuation.resume(throwing: NSError(domain: "CaptionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition unavailable natively"]))
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result, result.isFinal {
                    let tokens = result.bestTranscription.segments.map { segment in
                        CaptionToken(
                            text: segment.substring,
                            startTime: segment.timestamp,
                            endTime: segment.timestamp + segment.duration
                        )
                    }
                    continuation.resume(returning: tokens)
                }
            }
        }
    }
}
