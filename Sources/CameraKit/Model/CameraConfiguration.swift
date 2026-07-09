import Foundation

/// Configurable state for the camera.
///
/// Passed at init time to define defaults, and exposed as `camera.config` for live mutation.
/// Changes to `config` are automatically applied to the capture pipeline.
public struct CameraConfiguration: Sendable, Equatable {
    
    // MARK: - General
    
    public var captureMode: CaptureMode
    public var savesToGallery: Bool
    
    // MARK: - Photo
    
    public var qualityPrioritization: QualityPrioritization
    public var isLivePhotoEnabled: Bool
    public var imageFilter: ImageFilter
    
    // MARK: - Video
    
    public var isHDRVideoEnabled: Bool
    
    // MARK: - UI
    
    public var isToolbarVisible: Bool
    public var isCaptureModeVisible: Bool

    public init(
        captureMode: CaptureMode = .photo,
        savesToGallery: Bool = false,
        qualityPrioritization: QualityPrioritization = .quality,
        isLivePhotoEnabled: Bool = true,
        imageFilter: ImageFilter = .none,
        isHDRVideoEnabled: Bool = false,
        isToolbarVisible: Bool = true,
        isCaptureModeVisible: Bool = true
    ) {
        self.captureMode = captureMode
        self.savesToGallery = savesToGallery
        self.qualityPrioritization = qualityPrioritization
        self.isLivePhotoEnabled = isLivePhotoEnabled
        self.imageFilter = imageFilter
        self.isHDRVideoEnabled = isHDRVideoEnabled
        self.isToolbarVisible = isToolbarVisible
        self.isCaptureModeVisible = isCaptureModeVisible
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
