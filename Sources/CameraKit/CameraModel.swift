//
//  CameraModel.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI
@preconcurrency import AVFoundation

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
    /// A preview layer that presents the captured video frames.
    public let preview: AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
    public let alternativePreview: AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()

    /// Metadata to highlight features or focus points over the preview.
    public var featureMetadata: [FeatureMetadata] = []
    public private(set) var focusPoints: [FocusIndicator] = []

    /// An error that indicates the details of an error during photo or movie capture.
    public private(set) var error: Error?

    /// The current status of the camera, such as unauthorized, running, or failed.
    public private(set) var status: CameraStatus = .unknown
    
    /// The current state of photo or movie capture.
    public private(set) var captureActivity: CaptureActivity = .idle
    
    /// A Boolean value that indicates whether the app is currently switching video devices.
    public private(set) var isSwitchingDevices = false
        
    /// A Boolean value that indicates whether the app is currently switching capture modes.
    public private(set) var isSwitchingModes = false
        
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    public private(set) var shouldFlashScreen = false
    
    /// Persistent state shared between the app and capture extension.
    private var cameraState = CameraState()

    /// An enum value that indicates the direction of the user's swipe gesture
    public var swipeDirection: SwipeDirection = .left
        
    /// A Boolean value that indicates whether the camera is doing some process work.
    public var isProcessing = false
            
    /// A value that indicates which filter is being applied to the camera photograms..
    public var imageFilter: ImageFilter = .none {
        didSet { cameraState.imageFilter = imageFilter }
    }

    /// An function to manipulate the image from the preview stream
    public var previewFilter: (sending CIImage) async -> sending CIImage {
        switch self.imageFilter {
        case .none: { $0 }
        case .cards: { self.detect(in: $0) { await self.detectRectangle(in: $0) }; return $0 }
        case .text: { self.detect(in: $0) { await self.detectText(in: $0) }; return $0 }
        }
    }

    private func detect(in image: CIImage, work: @escaping (CIImage) async -> [FeatureMetadata]) {
        guard detectionTask == nil, lastPhoto == nil, lastVideo == nil else { return }
        detectionTask = Task {
            let result = await work(image)
            guard !Task.isCancelled else { return }
            self.featureMetadata = result
            self.detectionTask = nil
        }
    }

    private func detectRectangle(in image: CIImage) async -> [FeatureMetadata] {
        guard let points = await FeatureDetection.rectangle(in: image) else { return [] }
        let id = featureMetadata.first?.id ?? UUID()
        return [FeatureMetadata(id: id, type: .rectangle, image: image, coordinates: points)]
    }

    private func detectText(in image: CIImage) async -> [FeatureMetadata] {
        let observations = await FeatureDetection.text(in: image)
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first,
                  let box = candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex) else { return nil }
            let points = [box.topLeft, box.topRight, box.bottomRight, box.bottomLeft].map { CGPoint(x: $0.x, y: $0.y) }
            return FeatureMetadata(stableID: candidate.string, type: .text, image: image, coordinates: points)
        }
    }

    /// Async stream of photograms from the camera preview
    var previewStream: AsyncStream<CIImage> { captureService.previewStream }

    /// A Boolean that indicates whether the camera supports HDR video recording.
    public private(set) var isHDRVideoSupported = false
                    
    /// UI camera mode switcher
    public var isToolbarVisible: Bool = false {
        didSet { cameraState.isToolbarVisible = isToolbarVisible }
    }

    public var isCaptureModeVisible: Bool = false {
        didSet { cameraState.isCaptureModeVisible = isCaptureModeVisible }
    }

    /// An object that saves captured media to a person's Photos library.
    private let mediaLibrary = MediaLibrary()
    
    /// Task for vision detection — acts as natural throttle (skips frames while busy).
    private var detectionTask: Task<Void, Never>?

    /// An object that manages the app's capture functionality.
    private let captureService: CaptureService
    
    /// A thumbnail image for the most recent photo or video capture.
    public var thumbnail: CGImage? = nil

    /// The source of video content for a camera preview.
    public var lastPhoto: UIImage? = nil

    /// The source of video content for a camera preview.
    public var lastVideo: URL? = nil

    /// The initial configuration for this camera instance.
    private let configuration: CameraConfiguration

    public init(configuration: CameraConfiguration = CameraConfiguration()) {
        self.configuration = configuration
        let sendableLayers: [SendableDisplayLayer] = [.init(layer: preview), .init(layer: alternativePreview)]
        captureService = CaptureService(previewLayers: sendableLayers)
        
        // Apply initial config
        self.captureMode = configuration.captureMode
        self.qualityPrioritization = configuration.qualityPrioritization
        self.isLivePhotoEnabled = configuration.isLivePhotoEnabled
        self.isHDRVideoEnabled = configuration.isHDRVideoEnabled
        self.imageFilter = configuration.imageFilter
        self.isToolbarVisible = configuration.isToolbarVisible
        self.isCaptureModeVisible = configuration.isCaptureModeVisible
    }
    
    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    public func start() async {
        // Verify that the person authorizes the app to use device cameras and microphones.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service with the current state.
            try await captureService.start(with: cameraState)
            await captureService.startPreviewing()
            observeState()
            status = .running
        } catch {
            print("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    // MARK: - Stopping the camera
    /// Stop the camera session and data stream.
    public func stop() async {
        await captureService.stop()
    }
        
    /// Synchronizes the persistent camera state.
    public func syncState() async {
        cameraState.isToolbarVisible = isToolbarVisible
        cameraState.isCaptureModeVisible = isCaptureModeVisible
        cameraState.captureMode = captureMode
        cameraState.qualityPrioritization = qualityPrioritization
        cameraState.isLivePhotoEnabled = isLivePhotoEnabled
        cameraState.isVideoHDREnabled = isHDRVideoEnabled
        cameraState.imageFilter = imageFilter
    }
    
    public func clearCapture() {
        detectionTask?.cancel()
        detectionTask = nil
        lastPhoto = nil
        lastVideo = nil
        featureMetadata = []
    }
    
    // MARK: - Changing modes and devices
    
    /// A value that indicates the mode of capture for the camera.
    public var captureMode = CaptureMode.photo {
        didSet {
            guard status == .running else { return }
            Task {
                isSwitchingModes = true
                defer { isSwitchingModes = false }
                // Update the configuration of the capture service for the new mode.
                try? await captureService.setCaptureMode(captureMode)
                // Update the persistent state value.
                cameraState.captureMode = captureMode
                
                // Disable filters in video mode
                if captureMode != .photo { imageFilter = .none }
            }
        }
    }
    
    /// Selects the next available video device for capture.
    public func switchVideoDevices() async {
        isSwitchingDevices = true
        defer { isSwitchingDevices = false }
        await captureService.selectNextVideoDevice()
    }
    
    // MARK: - Photo capture
    /// Captures a photo and writes it to the user's Photos library.
    public func capturePhoto() async -> Photo? {
        isProcessing = true
        defer { isProcessing = false }
        
        let lastFeature: FeatureMetadata? = featureMetadata.first
        
        do {
            let photoFeatures = PhotoFeatures(isLivePhotoEnabled: isLivePhotoEnabled, qualityPrioritization: qualityPrioritization)
            let photo = try await captureService.capturePhoto(with: photoFeatures)
            if configuration.savesToGallery { try await mediaLibrary.save(photo: photo) }
                        
            switch imageFilter {
            case .cards: lastPhoto = lastFeature?.crop.uiImage
            default: lastPhoto = UIImage(data: photo.data)
            }
            
            return photo
        } catch {
            self.error = error
            return nil
        }
    }
    
    /// A Boolean value that indicates whether to capture Live Photos when capturing stills.
    public var isLivePhotoEnabled = true {
        didSet { cameraState.isLivePhotoEnabled = isLivePhotoEnabled }
    }
    
    /// A value that indicates how to balance the photo capture quality versus speed.
    public var qualityPrioritization = QualityPrioritization.quality {
        didSet { cameraState.qualityPrioritization = qualityPrioritization }
    }
    
    /// Performs a focus and expose operation at the specified screen point.
    public func focusAndExpose(at point: CGPoint) async {
        await captureService.focusAndExpose(at: point)
    }
    
    /// Sets the `showCaptureFeedback` state to indicate that capture is underway.
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.easeInOut(duration: 0.1)) {
            shouldFlashScreen = false
        }
    }
    
    // MARK: - Video capture
    /// A Boolean value that indicates whether the camera captures video in HDR format.
    public var isHDRVideoEnabled = false {
        didSet {
            guard status == .running, captureMode == .video else { return }
            Task {
                await captureService.setHDRVideoEnabled(isHDRVideoEnabled)
                // Update the persistent state value.
                cameraState.isVideoHDREnabled = isHDRVideoEnabled
            }
        }
    }
    
    /// Toggles the state of recording.
    public func toggleRecording() async -> Movie? {
        isProcessing = true
        defer { isProcessing = false }

        switch await captureService.captureActivity {
        case .movieCapture:
            do {
                let movie = try await captureService.stopRecording()
                if configuration.savesToGallery { try await mediaLibrary.save(movie: movie) }
                lastVideo = movie.url
                return movie
            } catch {
                self.error = error
                return nil
            }
        default:
            await captureService.startRecording()
            return nil
        }
    }
    
    // MARK: - Internal state observations
    // Set up camera's state observations.
    private func observeState() {
        Task {
            // Await new thumbnails that the media library generates when saving a file.
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
                isHDRVideoSupported = capabilities.isHDRSupported
                cameraState.isVideoHDRSupported = capabilities.isHDRSupported
            }
        }
        
        Task {
            for await filter in captureService.filterStream {
                imageFilter = filter
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
                guard imageFilter != .none else { continue }
                _ = await previewFilter(image)
            }
        }
    }
}

