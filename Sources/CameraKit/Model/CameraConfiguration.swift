import Foundation

/// Configurable state for the camera.
///
/// Passed at init time to define defaults, and exposed as `camera.config` for live mutation.
/// Changes to `config` are automatically applied to the capture pipeline.
public struct CameraConfiguration: Sendable, Equatable {
    public var captureMode: CaptureMode
    public var qualityPrioritization: QualityPrioritization
    public var isLivePhotoEnabled: Bool
    public var isHDRVideoEnabled: Bool
    public var imageFilter: ImageFilter
    public var isToolbarVisible: Bool
    public var isCaptureModeVisible: Bool
    public var savesToGallery: Bool

    public init(
        captureMode: CaptureMode = .photo,
        qualityPrioritization: QualityPrioritization = .quality,
        isLivePhotoEnabled: Bool = true,
        isHDRVideoEnabled: Bool = false,
        imageFilter: ImageFilter = .none,
        isToolbarVisible: Bool = true,
        isCaptureModeVisible: Bool = true,
        savesToGallery: Bool = false
    ) {
        self.captureMode = captureMode
        self.qualityPrioritization = qualityPrioritization
        self.isLivePhotoEnabled = isLivePhotoEnabled
        self.isHDRVideoEnabled = isHDRVideoEnabled
        self.imageFilter = imageFilter
        self.isToolbarVisible = isToolbarVisible
        self.isCaptureModeVisible = isCaptureModeVisible
        self.savesToGallery = savesToGallery
    }
}

// MARK: - Presets
public extension CameraConfiguration {
    /// Standard photo capture (toolbar visible, no live photo, fast quality).
    static let photo = CameraConfiguration(
        qualityPrioritization: .speed,
        isLivePhotoEnabled: false,
        isCaptureModeVisible: false
    )

    /// Document/card scanning (no toolbar, card filter, fast quality).
    static let document = CameraConfiguration(
        qualityPrioritization: .speed,
        isLivePhotoEnabled: false,
        imageFilter: .cards,
        isToolbarVisible: false,
        isCaptureModeVisible: false
    )

    /// Video recording (video mode, no toolbar).
    static let video = CameraConfiguration(
        captureMode: .video,
        qualityPrioritization: .speed,
        isLivePhotoEnabled: false,
        isToolbarVisible: false,
        isCaptureModeVisible: false
    )
}
