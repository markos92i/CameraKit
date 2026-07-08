//
//  DataTypes.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import AVFoundation

// MARK: - Supporting types

/// An enumeration that describes the current status of the camera.
public enum CameraStatus {
    /// The initial status upon creation.
    case unknown
    /// A status that indicates a person disallows access to the camera or microphone.
    case unauthorized
    /// A status that indicates the camera failed to start.
    case failed
    /// A status that indicates the camera is successfully running.
    case running
    /// A status that indicates higher-priority media processing is interrupting the camera.
    case interrupted
    
    public var disabled: Bool { [.unauthorized, .failed, .interrupted].contains { $0 == self } }
}

/// An enumeration that defines the activity states the capture service supports.
///
/// This type provides feedback to the UI regarding the active status of the `CaptureService` actor.
public enum CaptureActivity: Sendable, Identifiable, Equatable {
    case idle
    /// A status that indicates the capture service is performing photo capture.
    case photoCapture(willCapture: Bool = false, isLivePhoto: Bool = false)
    /// A status that indicates the capture service is performing movie capture.
    case movieCapture(duration: TimeInterval = 0.0)
    
    public var id: Int {
        switch self {
        case .idle: 0
        case .photoCapture(let willCapture, _): willCapture ? 2 : 1
        case .movieCapture(_): 3
        }
    }

    public var isLivePhoto: Bool { if case .photoCapture(_, let isLivePhoto) = self { isLivePhoto } else { false } }
    
    public var willCapture: Bool { if case .photoCapture(let willCapture, _) = self { willCapture } else { false } }
    
    public var currentTime: TimeInterval { if case .movieCapture(let duration) = self { duration } else { .zero } }
    
    public var isRecording: Bool { if case .movieCapture(_) = self { true } else { false } }
}

/// An enumeration of the capture modes that the camera supports.
public enum CaptureMode: String, Identifiable, CaseIterable, CustomStringConvertible, Codable, Sendable {
    public var id: Self { self }
    case photo
    case video
    
    public var description: String {
        switch self {
        case .photo: String(localized: "foto")
        case .video: String(localized: "video")
        }
    }

    public var systemName: String {
        switch self {
        case .photo: "camera.fill"
        case .video: "video.fill"
        }
    }
    
    public func toggle() -> CaptureMode { if self == .photo { .video } else { .photo } }
}

/// A structure that represents a captured photo.
public struct Photo: Sendable {
    public let data: Data
    public let isProxy: Bool
    public let livePhotoMovieURL: URL?

    /// Writes the raw capture data directly to a file and returns its URL.
    ///
    /// This avoids recompression — the bytes from `AVCapturePhoto.fileDataRepresentation()`
    /// are persisted as-is (HEIC or JPEG depending on device settings).
    public func fileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy'_'HH'-'mm'-'ss"
        let url = dir.appendingPathComponent("\(formatter.string(from: .now)).jpg")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

/// A structure that contains the uniform type identifier and movie URL.
public struct Movie: Sendable {
    /// The temporary location of the file on disk.
    public let url: URL
}

public struct PhotoFeatures: Sendable {
    public let isLivePhotoEnabled: Bool
    public let qualityPrioritization: QualityPrioritization
}

/// A structure that represents the capture capabilities of `CaptureService` in
/// its current configuration.
struct CaptureCapabilities {
    let isLivePhotoCaptureSupported: Bool
    let isHDRSupported: Bool
    
    init(isLivePhotoCaptureSupported: Bool = false, isHDRSupported: Bool = false) {
        self.isLivePhotoCaptureSupported = isLivePhotoCaptureSupported
        self.isHDRSupported = isHDRSupported
    }
    
    static let unknown = CaptureCapabilities()
}

public enum QualityPrioritization: Int, Identifiable, CaseIterable, CustomStringConvertible, Codable, Sendable {
    public var id: Self { self }
    case speed = 1
    case balanced
    case quality
    
    public var description: String {
        switch self {
        case .speed: String(localized: "Velocidad")
        case .balanced: String(localized: "Equilibrado")
        case .quality: String(localized: "Calidad")
        }
    }
    
    public var systemName: String {
        switch self {
        case .speed: "dial.low.fill"
        case .balanced: "dial.medium.fill"
        case .quality: "dial.high.fill"
        }
    }
}

public enum CameraError: Error {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var capabilities: CaptureCapabilities { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    func updateConfiguration(for device: AVCaptureDevice) {}
}

public enum SwipeDirection {
    case left
    case right
    case up
    case down
    
    var isHorizontal: Bool { self == .left || self == .right }
    var isVertical: Bool { self == .up || self == .down }
    
    init(size: CGSize) {
        if size.height.magnitude > size.width.magnitude {
            self = size.height < 0 ? .up : .down
        } else {
            self = size.width < 0 ? .left : .right
        }
    }
}
