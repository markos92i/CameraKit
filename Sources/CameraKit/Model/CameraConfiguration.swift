import Foundation

/// Immutable configuration passed to CameraModel at init time.
/// Defines the initial state of the camera — UI visibility, capture mode, quality, etc.
public struct CameraConfiguration: Sendable {
    public let captureMode: CaptureMode
    public let qualityPrioritization: QualityPrioritization
    public let isLivePhotoEnabled: Bool
    public let isHDRVideoEnabled: Bool
    public let imageFilter: ImageFilter
    public let isToolbarVisible: Bool
    public let isCaptureModeVisible: Bool
    public let savesToGallery: Bool

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
