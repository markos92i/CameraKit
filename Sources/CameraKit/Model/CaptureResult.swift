import Foundation

/// The result of a camera capture, delivered to the consumer via the handler closure.
public enum CaptureResult: Sendable {
    /// Photo capture — metadata contains recognized features (empty for plain photos).
    case photo(url: URL, metadata: [CaptureMetadata])
    /// Video recording.
    case video(url: URL)
}
