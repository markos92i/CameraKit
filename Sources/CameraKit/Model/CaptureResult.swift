import Foundation

/// The result of a camera capture, adapted to the active mode.
public enum CaptureResult: Sendable {
    /// Standard photo — full frame JPEG.
    case photo(url: URL)
    /// Video recording.
    case video(url: URL)
    /// Detected document/card — perspective-corrected crop + OCR text regions.
    case document(url: URL, regions: [TextRegion])
}

/// A recognized text region within a captured image.
public struct TextRegion: Sendable {
    /// The recognized text string.
    public let text: String
    /// Normalized bounding box (0-1) within the captured image.
    public let bounds: CGRect

    public init(text: String, bounds: CGRect) {
        self.text = text
        self.bounds = bounds
    }
}
