import Foundation
import SwiftUI
import CoreImage
import AVFoundation

/// A mock camera model for SwiftUI previews and the Simulator.
/// Does not interact with real capture hardware.
@MainActor
@Observable
public final class PreviewCameraModel: Camera {
    public let preview = AVSampleBufferDisplayLayer()
    public let alternativePreview = AVSampleBufferDisplayLayer()
    public var featureMetadata: [CaptureMetadata] = []
    public var focusPoints: [FocusIndicator] = []

    public private(set) var status = CameraStatus.unknown
    public private(set) var captureActivity = CaptureActivity.idle
    public var captureMode = CaptureMode.photo
    public private(set) var isSwitchingModes = false
    public var error: Error?
    public var previewFilter: (sending CIImage) async -> sending CIImage = { $0 }
    public var imageFilter: ImageFilter = .none
    public var isSwitchingDevices: Bool = false
    public var swipeDirection: SwipeDirection = .left
    public var isProcessing: Bool = false
    public var isLivePhotoEnabled: Bool = false
    public var qualityPrioritization: QualityPrioritization = .quality
    public var shouldFlashScreen: Bool = false
    public var isHDRVideoSupported: Bool = false
    public var isHDRVideoEnabled: Bool = false
    public var isToolbarVisible: Bool = false
    public var isCaptureModeVisible: Bool = false
    public var thumbnail: CGImage? = nil
    public var captureSnapshot: CaptureSnapshot? = nil

    public init(captureMode: CaptureMode = .photo, status: CameraStatus = .unknown) {
        self.captureMode = captureMode
        self.status = status
    }

    public init(configuration: CameraConfiguration) {
        self.captureMode = configuration.captureMode
        self.qualityPrioritization = configuration.qualityPrioritization
        self.isLivePhotoEnabled = configuration.isLivePhotoEnabled
        self.isHDRVideoEnabled = configuration.isHDRVideoEnabled
        self.imageFilter = configuration.imageFilter
        self.isToolbarVisible = configuration.isToolbarVisible
        self.isCaptureModeVisible = configuration.isCaptureModeVisible
    }

    public func start() async {
        if status == .unknown { status = .running }
    }

    public func stop() async {
        status = .unknown
    }

    public func focusAndExpose(at point: CGPoint) async {}

    public var zoomFactor: CGFloat = 1.0

    public func setZoom(_ factor: CGFloat) async {
        zoomFactor = max(1.0, min(factor, 10.0))
    }

    public func capturePhoto() async -> Photo? {
        shouldFlashScreen = true
        withAnimation(.easeInOut(duration: 0.1)) { shouldFlashScreen = false }

        // Generate a simulated capture for preview purposes
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 600))
        let image = renderer.image { context in
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 400, y: 600), options: [])
        }

        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let photo = Photo(data: data, isProxy: false, livePhotoMovieURL: nil)
        captureSnapshot = .photo(preview: image, raw: photo, metadata: featureMetadata)
        return photo
    }

    public func toggleRecording() async -> Movie? {
        if captureActivity.isRecording {
            captureActivity = .idle
            // Simulate a recorded video with a placeholder URL
            let url = URL.temporaryDirectory.appending(component: "preview-video.mov")
            captureSnapshot = .video(url: url)
            return Movie(url: url)
        } else {
            captureActivity = .movieCapture(duration: 0)
            return nil
        }
    }

    public func switchVideoDevices() async {
        isSwitchingModes = true
        captureMode = captureMode.toggle()
        try? await Task.sleep(for: .seconds(0.3))
        isSwitchingModes = false
    }

    public func syncState() async {}

    public func clearCapture() {
        captureSnapshot = nil
        featureMetadata = []
    }
}
