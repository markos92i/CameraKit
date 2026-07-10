//
//  CameraModel.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI
import AVFoundation

struct SendableDisplayLayer: @unchecked Sendable {
    let layer: AVSampleBufferDisplayLayer
}

/// An object that provides the interface to the features of the camera.
///
/// This object provides the default implementation of the `Camera` protocol, which defines the interface
/// to configure the camera hardware and capture media. `CameraModel` doesn't perform capture itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `CaptureService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewCameraModel` instead.
///

@MainActor
@Observable
public final class CameraModel: Camera {
    
    // MARK: - Preview layers
    
    /// A preview layer that presents the captured video frames.
    public let preview: AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
    public let alternativePreview: AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()

    // MARK: - Configuration
    
    /// The camera's live configuration. Changes are applied to the capture pipeline automatically.
    public var config: CameraConfiguration {
        didSet { applyConfigChanges(from: oldValue, to: config) }
    }

    // MARK: - Runtime state
    
    /// Metadata to highlight features or focus points over the preview.
    public var featureMetadata: [CaptureMetadata] = []
    public private(set) var focusPoints: [FocusIndicator] = []

    /// An error that indicates the details of an error during photo or movie capture.
    public var error: Error?

    /// The current status of the camera, such as unauthorized, running, or failed.
    public private(set) var status: CameraStatus = .unknown
    
    /// The current state of photo or movie capture.
    public private(set) var captureActivity: CaptureActivity = .idle
    
    /// A Boolean value that indicates whether the app is currently switching devices or modes.
    public private(set) var isSwitching = false
        
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    public private(set) var shouldFlashScreen = false

    /// An enum value that indicates the direction of the user's swipe gesture
    public var swipeDirection: SwipeDirection = .left
        
    /// A Boolean value that indicates whether the camera is doing some process work.
    public var isProcessing = false

    /// Hardware capabilities of the current device and configuration.
    public private(set) var capabilities = CaptureCapabilities()

    /// The current zoom factor applied to the camera.
    public private(set) var zoomFactor: CGFloat = 1.0

    /// A thumbnail image for the most recent photo or video capture.
    public var thumbnail: CGImage? = nil

    /// The current capture snapshot (photo or video), held until accepted or discarded.
    public var captureSnapshot: CaptureSnapshot? = nil

    // MARK: - Preview filter
    
    /// An function to manipulate the image from the preview stream
    public var previewFilter: (sending CIImage) async -> sending CIImage {
        switch config.imageFilter {
        case .none: { $0 }
        case .cards: { self.detect(in: $0) { await self.detectRectangle(in: $0) }; return $0 }
        case .text: { self.detect(in: $0) { await self.detectText(in: $0) }; return $0 }
        }
    }

    // MARK: - Private
    
    /// An object that saves captured media to a person's Photos library.
    private let mediaLibrary = MediaLibrary()
    
    /// Task for vision detection — acts as natural throttle (skips frames while busy).
    private var detectionTask: Task<Void, Never>?

    /// An object that manages the app's capture functionality.
    private let captureService: CaptureService

    // MARK: - Init

    public init(configuration: CameraConfiguration = CameraConfiguration()) {
        self.config = configuration
        let sendableLayers: [SendableDisplayLayer] = [.init(layer: preview), .init(layer: alternativePreview)]
        captureService = CaptureService(previewLayers: sendableLayers)
    }
    
    // MARK: - Starting the camera
    
    /// Start the camera and begin the stream of data.
    /// Can be called again to retry after a failure.
    public func start() async {
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            try await captureService.start(with: config)
            await captureService.startPreviewing()
            // Only set up state observers once.
            if status != .running { observeState() }
            status = .running
        } catch {
            self.error = error
            status = .failed
        }
    }
    
    // MARK: - Stopping the camera
    
    /// Stop the camera session and data stream.
    public func stop() async {
        await captureService.stop()
    }
        
    /// Resets capture state: cancels pending detection, clears snapshot and metadata.
    public func clearCapture() {
        detectionTask?.cancel()
        detectionTask = nil
        captureSnapshot = nil
        featureMetadata = []
    }
    
    // MARK: - Device switching
    
    /// Selects the next available video device for capture.
    public func switchVideoDevices() async {
        guard status == .running else { return }
        isSwitching = true
        defer { isSwitching = false }
        await captureService.selectNextVideoDevice()
    }
    
    // MARK: - Photo capture
    
    /// Captures a photo and writes it to the user's Photos library.
    public func capturePhoto() async -> Photo? {
        guard status == .running else { return nil }
        isProcessing = true
        defer { isProcessing = false }
        
        let snapshotMetadata = featureMetadata
        
        // Stop detection during capture and animation
        detectionTask?.cancel()
        detectionTask = nil
        
        do {
            let photo = try await captureService.capturePhoto(with: config)
            if config.savesToGallery { try await mediaLibrary.save(photo: photo) }
            
            let preview: UIImage? = switch config.imageFilter {
            case .cards: await cropCard(from: photo.data)
            default: UIImage(data: photo.data)
            }
            
            if let preview {
                captureSnapshot = .photo(preview: preview, raw: photo, metadata: snapshotMetadata)
            }
            
            return photo
        } catch {
            self.error = error
            return nil
        }
    }

    /// Performs a focus and expose operation at the specified screen point.
    public func focusAndExpose(at point: CGPoint) async {
        guard status == .running else { return }
        await captureService.focusAndExpose(at: point)
    }

    /// Sets the zoom factor, clamped to the device's supported range.
    public func setZoom(_ factor: CGFloat) async {
        guard status == .running else { return }
        await captureService.setZoom(factor)
        zoomFactor = await captureService.zoomFactor
    }
    
    // MARK: - Video capture
    
    /// Toggles the state of recording.
    public func toggleRecording() async -> Movie? {
        guard status == .running else { return nil }
        isProcessing = true
        defer { isProcessing = false }

        switch await captureService.captureActivity {
        case .movieCapture:
            do {
                let movie = try await captureService.stopRecording()
                if config.savesToGallery { try await mediaLibrary.save(movie: movie) }
                captureSnapshot = .video(url: movie.url)
                return movie
            } catch {
                self.error = error
                return nil
            }
        default:
            do {
                try await captureService.startRecording()
            } catch {
                self.error = error
            }
            return nil
        }
    }
    
    // MARK: - Config change handling
    
    /// Applies configuration changes to the capture pipeline when `config` is mutated.
    private func applyConfigChanges(from oldValue: CameraConfiguration, to newValue: CameraConfiguration) {
        guard status == .running else { return }
        
        if oldValue.captureMode != newValue.captureMode {
            Task {
                isSwitching = true
                defer { isSwitching = false }
                try? await captureService.setCaptureMode(newValue.captureMode)
                if newValue.captureMode != .photo { config.imageFilter = .none }
            }
        }
        
        if oldValue.isHDRVideoEnabled != newValue.isHDRVideoEnabled, newValue.captureMode == .video {
            Task { await captureService.setHDRVideoEnabled(newValue.isHDRVideoEnabled) }
        }
    }
    
    // MARK: - Internal state observations
    
    private func observeState() {
        Task {
            for await thumbnail in mediaLibrary.thumbnails.compactMap({ $0 }) {
                self.thumbnail = thumbnail
            }
        }
        
        Task {
            for await activity in captureService.activityStream {
                if activity.willCapture { flashScreen() }
                else { captureActivity = activity }
            }
        }
        
        Task {
            for await capabilities in captureService.capabilitiesStream {
                self.capabilities = capabilities
            }
        }
        
        Task {
            for await filter in captureService.filterStream {
                config.imageFilter = filter
            }
        }
        
        Task {
            for await status in captureService.statusStream {
                self.status = status
            }
        }
        
        Task {
            var dismissTask: Task<Void, Never>?
            for await point in captureService.focusPointStream {
                dismissTask?.cancel()
                focusPoints = [.init(position: point)]
                dismissTask = Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    guard !Task.isCancelled else { return }
                    focusPoints.removeAll()
                }
            }
        }
        
        Task {
            for await image in captureService.previewStream {
                guard config.imageFilter != .none else { continue }
                _ = await previewFilter(image)
            }
        }
    }
    
    // MARK: - Private helpers
    
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.easeInOut(duration: 0.1)) {
            shouldFlashScreen = false
        }
    }

    private func detect(in image: CIImage, work: @escaping (CIImage) async -> [CaptureMetadata]) {
        guard detectionTask == nil, captureSnapshot == nil else { return }
        detectionTask = Task {
            let result = await work(image)
            guard !Task.isCancelled else { return }
            self.featureMetadata = result
            self.detectionTask = nil
        }
    }

    private func detectRectangle(in image: CIImage) async -> [CaptureMetadata] {
        guard let points = await FeatureDetection.rectangle(in: image) else { return [] }
        let id = featureMetadata.first?.id ?? UUID()
        return [CaptureMetadata(id: id, type: .rectangle, image: image, coordinates: points)]
    }

    private func detectText(in image: CIImage) async -> [CaptureMetadata] {
        let observations = await FeatureDetection.text(in: image)
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first,
                  let box = candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex) else { return nil }
            let points = [box.topLeft, box.topRight, box.bottomRight, box.bottomLeft].map { CGPoint(x: $0.x, y: $0.y) }
            return CaptureMetadata(stableID: candidate.string, type: .text, image: image, coordinates: points)
        }
    }

    /// Crops the detected rectangle from the full-resolution captured photo.
    private func cropCard(from data: Data) async -> UIImage? {
        guard let ciImage = CIImage(data: data) else { return nil }
        guard let points = await FeatureDetection.rectangle(in: ciImage) else { return nil }
        let scaledPoints = CGPointUtils.scale(points, to: ciImage.extent.size)
        let cropped = ciImage.perspective(points: scaledPoints)

        let orientation = ciImage.properties[kCGImagePropertyOrientation as String] as? UInt32
        let oriented: CIImage
        if let orientation, let exif = CGImagePropertyOrientation(rawValue: orientation) {
            oriented = cropped.oriented(exif)
        } else {
            oriented = cropped
        }

        return oriented.uiImage
    }
}
