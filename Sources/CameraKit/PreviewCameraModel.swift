import Foundation
import SwiftUI
import CoreMedia
import AVFoundation

@Observable
public class PreviewCameraModel: Camera {
    public let preview = AVSampleBufferDisplayLayer()
    public let alternativePreview = AVSampleBufferDisplayLayer()
    public var featureMetadata: [FeatureMetadata] = []
    public let focusPoints: [FocusIndicator] = []

    public private(set) var status = CameraStatus.unknown
    public private(set) var captureActivity = CaptureActivity.idle
    public var captureMode = CaptureMode.photo {
        didSet {
            isSwitchingModes = true
            Task {
                try? await Task.sleep(until: .now + .seconds(0.3), clock: .continuous)
                self.isSwitchingModes = false
            }
        }
    }
    public private(set) var isSwitchingModes = false
    public var error: Error?
    public var previewImage: CIImage? = nil
    public var previewFilter: (sending CIImage) async -> sending CIImage = { $0 }
    public var imageFilter: ImageFilter = .none
    public var isSwitchingDevices: Bool = false
    public var swipeDirection: SwipeDirection = .left
    public var isRecording: Bool = false
    public var isProcessing: Bool = false
    public var isLivePhotoEnabled: Bool = false
    public var qualityPrioritization: QualityPrioritization = .quality
    public var shouldFlashScreen: Bool = false
    public var isHDRVideoSupported: Bool = false
    public var isHDRVideoEnabled: Bool = false
    public var isToolbarVisible: Bool = false
    public var isCaptureModeVisible: Bool = false
    public var recordingTime: TimeInterval { .zero }
    public var thumbnail: CGImage? = nil
    public var lastPhoto: UIImage? = nil
    public var lastVideo: URL? = nil
    public var editableTexts: [EditableTextItem] = []

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

    public func capturePhoto() async -> Photo? {
        shouldFlashScreen = true
        withAnimation(.easeInOut(duration: 0.1)) { shouldFlashScreen = false }
        return nil
    }
    
    public func toggleRecording() async -> Movie? { nil }

    public func switchVideoDevices() {
        captureMode = captureMode.toggle()
    }

    public func syncState() async {}
    
    public func clearCapture() {
        lastPhoto = nil
        lastVideo = nil
        editableTexts = []
        featureMetadata = []
    }
}
