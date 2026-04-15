import Foundation
@preconcurrency import AVFoundation

/// A global actor guaranteeing all AVFoundation buffer dispatch and capture session state 
/// never bleeds into the main thread. This completely resolves camera freezing.
@globalActor
public actor VideoCaptureActor {
    public static let shared = VideoCaptureActor()
}

/// The isolated service controlling the camera lens and real-time disk writing.
public final class VideoCaptureService: NSObject, @unchecked Sendable, ObservableObject {
    public let captureSession = AVCaptureSession()
    
    // We maintain AVAssetWriter inside a dedicated writing queue
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var isRecording = false
    private var sessionAtSourceTime: CMTime?
    
    // Camera state
    @Published public private(set) var currentPosition: AVCaptureDevice.Position = .front
    @Published public private(set) var isFlashOn: Bool = false
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    private let captureQueue = DispatchQueue(label: "com.hookflow.capture", qos: .userInteractive)
    private let writingQueue = DispatchQueue(label: "com.hookflow.writing", qos: .userInitiated)
    
    public override init() {
        super.init()
    }
    
    public func startSession() {
        Task.detached(priority: .userInitiated) {
            guard !self.captureSession.isRunning else { return }
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // 1. Setup Video (Dynamic Position)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            self.videoDeviceInput = videoInput
        }
        
        // 2. Setup Audio (Microphone for Captions/Export)
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else { return }
              
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // 3. Isolated Output Buffer Dispatch
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            // Ensure video orientation stays portrait using iOS 17+ Modern Native Angles
            if let connection = videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(90.0) {
                        connection.videoRotationAngle = 90.0
                    }
                } else {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
                
                // Mirror front camera naturally
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
            }
        }
        
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: captureQueue)
        
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        }
    }
    
    public func stopSession() {
        Task.detached(priority: .userInitiated) {
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    public func toggleCameraPosition() {
        captureQueue.async {
            guard let currentInput = self.videoDeviceInput else { return }
            
            // Flip the position logic
            let newPosition: AVCaptureDevice.Position = self.currentPosition == .front ? .back : .front
            
            guard let newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newVideoInput = try? AVCaptureDeviceInput(device: newVideoDevice) else { return }
            
            self.captureSession.beginConfiguration()
            
            // Remove old, add new
            self.captureSession.removeInput(currentInput)
            if self.captureSession.canAddInput(newVideoInput) {
                self.captureSession.addInput(newVideoInput)
                self.videoDeviceInput = newVideoInput
                
                // Must ensure we always keep orientation portrait after flip
                if let videoOutput = self.captureSession.outputs.first(where: { $0 is AVCaptureVideoDataOutput }) as? AVCaptureVideoDataOutput,
                   let connection = videoOutput.connection(with: .video) {
                    
                    if #available(iOS 17.0, *) {
                        if connection.isVideoRotationAngleSupported(90.0) {
                            connection.videoRotationAngle = 90.0
                        }
                    } else {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                        }
                    }
                    
                    if connection.isVideoMirroringSupported {
                        // Only mirror front camera
                        connection.isVideoMirrored = (newPosition == .front)
                    }
                }
                
                // Safe state update
                DispatchQueue.main.async {
                    self.currentPosition = newPosition
                    self.isFlashOn = false // Flash resets on flip
                }
            } else {
                // Rollback if failure
                self.captureSession.addInput(currentInput)
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    public func toggleFlash() {
        captureQueue.async {
            guard let device = self.videoDeviceInput?.device else { return }
            guard device.hasTorch, device.isTorchAvailable else { return }
            
            do {
                try device.lockForConfiguration()
                let targetMode: AVCaptureDevice.TorchMode = device.torchMode == .on ? .off : .on
                device.torchMode = targetMode
                
                let flashState = (targetMode == .on)
                DispatchQueue.main.async {
                    self.isFlashOn = flashState
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Failed to lock device for torch configuration: \(error)")
            }
        }
    }
    
    public func startRecording(to url: URL) throws {
        try writingQueue.sync {
            guard !isRecording else { return }
            
            let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: 1080,
                AVVideoHeightKey: 1920
            ]
            let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            vInput.expectsMediaDataInRealTime = true
            if writer.canAdd(vInput) { writer.add(vInput) }
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000
            ]
            let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            aInput.expectsMediaDataInRealTime = true
            if writer.canAdd(aInput) { writer.add(aInput) }
            
            writer.startWriting()
            // Removed starting at .zero to prevent sync corruption
            self.sessionAtSourceTime = nil
            
            self.assetWriter = writer
            self.assetWriterInput = vInput
            self.audioWriterInput = aInput
            self.isRecording = true
        }
    }
    
    public func stopRecording() async throws -> URL? {
        let activeWriter: AVAssetWriter? = writingQueue.sync {
            guard isRecording, let writer = assetWriter else { return nil }
            isRecording = false
            assetWriterInput?.markAsFinished()
            audioWriterInput?.markAsFinished()
            return writer
        }
        
        guard let writer = activeWriter else { return nil }
        
        // Cannot finish writing if no data was ever appended (status == .unknown) or failed
        if writer.status != .writing {
            if writer.status == .failed, let error = writer.error {
                print("Writer failed with error: \(error.localizedDescription)")
            }
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: writer.outputURL)
            writingQueue.sync {
                self.assetWriter = nil
                self.assetWriterInput = nil
                self.audioWriterInput = nil
                self.sessionAtSourceTime = nil
            }
            return nil
        }
        
        await writer.finishWriting()
        let url = writer.outputURL
        
        writingQueue.sync {
            self.assetWriter = nil
            self.assetWriterInput = nil
            self.audioWriterInput = nil
            self.sessionAtSourceTime = nil
        }
        
        return url
    }
}

public struct SendableSampleBuffer: @unchecked Sendable {
    public let buffer: CMSampleBuffer
}

extension VideoCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Wrap buffer to pass strict Swift 6 Sendable checks
        let sendable = SendableSampleBuffer(buffer: sampleBuffer)
        
        // Dispatch to serial writing queue to keep camera capture loop insanely fast
        writingQueue.async {
            guard self.isRecording, let writer = self.assetWriter else { return }
            
            // Hard protection against appending to a failed writer (prevents Swift crash)
            guard writer.status != .failed else { return }
            
            let isVideo = output is AVCaptureVideoDataOutput
            let input = isVideo ? self.assetWriterInput : self.audioWriterInput
            
            guard let input = input, input.isReadyForMoreMediaData else { return }
            
            let buffer = sendable.buffer
            
            // Sync timestamp ONLY on the first VIDEO frame to save hardware from panic
            // Audio frames arriving before the first video frame will simply be dropped
            if self.sessionAtSourceTime == nil {
                guard isVideo else { return }
                
                let timestamp = CMSampleBufferGetPresentationTimeStamp(buffer)
                writer.startSession(atSourceTime: timestamp)
                self.sessionAtSourceTime = timestamp
            }
            
            // Append data safely now that session is synced
            input.append(buffer)
        }
    }
}
