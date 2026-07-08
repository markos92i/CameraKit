//
//  Camera.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI
import AVFoundation

/// A protocol that represents the model for the camera view.
///
/// The AVFoundation camera APIs require running on a physical device. The app defines the model as a protocol to make it
/// simple to swap out the real camera for a test camera when previewing SwiftUI views.
@MainActor
public protocol Camera: AnyObject, Observable, Sendable {
    
    /// Provides the current status of the camera.
    var status: CameraStatus { get }
    
    /// Metadata of detected features (example: Rectangles using Feature Recognition)
    var featureMetadata: [CaptureMetadata] { get set }
    
    /// Metadata of objects being focused in cinematic mode
    var focusPoints: [FocusIndicator] { get }

    /// The camera's current activity state, which can be photo capture, movie capture, or idle.
    var captureActivity: CaptureActivity { get }
    
    /// The source of video content for a camera preview.
    var preview: AVSampleBufferDisplayLayer { get }
    var alternativePreview: AVSampleBufferDisplayLayer { get }
    
    /// Image filter for the preview
    var previewFilter: (sending CIImage) async -> sending CIImage { get }
    
    /// A value that indicates how to balance the photo capture quality versus speed.
    var imageFilter: ImageFilter { get set }
    
    /// Starts the camera capture pipeline.
    func start() async
    
    /// Stops the camera capture pipeline.
    func stop() async

    /// A Boolean value that indicates whether the app is currently switching anything.
    var isSwitching: Bool { get }
    
    /// The capture mode, which can be photo or video.
    var captureMode: CaptureMode { get set }
    
    /// A Boolean value that indicates whether the camera is currently switching capture modes.
    var isSwitchingModes: Bool { get }
    
    /// Switches between video devices available on the host system.
    func switchVideoDevices() async
    
    /// A Boolean value that indicates whether the camera is currently switching video devices.
    var isSwitchingDevices: Bool { get }
    
    /// An enum value that indicates the direction of the user's swipe gesture
    var swipeDirection: SwipeDirection { get set }
        
    /// A Boolean value that indicates whether the camera is doing some process work.
    var isProcessing: Bool { get set }

    /// Performs a one-time automatic focus and exposure operation.
    func focusAndExpose(at point: CGPoint) async
    
    /// A Boolean value that indicates whether to capture Live Photos when capturing stills.
    var isLivePhotoEnabled: Bool { get set }
    
    /// A value that indicates how to balance the photo capture quality versus speed.
    var qualityPrioritization: QualityPrioritization { get set }
    
    /// Captures a photo and writes it to the user's photo library.
    func capturePhoto() async -> Photo?
    
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    var shouldFlashScreen: Bool { get }
    
    /// A Boolean that indicates whether the camera supports HDR video recording.
    var isHDRVideoSupported: Bool { get }
    
    /// A Boolean value that indicates whether camera enables HDR video recording.
    var isHDRVideoEnabled: Bool { get set }
    
    /// Starts or stops recording a movie, and writes it to the user's photo library when complete.
    func toggleRecording() async -> Movie?
        
    /// An error if the camera encountered a problem.
    var error: Error? { get }
        
    /// UI toolbar buttons
    var isToolbarVisible: Bool { get }
    
    /// UI camera mode switcher
    var isCaptureModeVisible: Bool { get }
    
    /// A thumbnail image for the most recent photo or video capture.
    var thumbnail: CGImage? { get }

    /// The current capture snapshot (photo or video), held until accepted or discarded.
    var captureSnapshot: CaptureSnapshot? { get set }
    
    /// Synchronize the state of the camera with the persisted values.
    func syncState() async
    
    /// Resets capture state: cancels pending detection, clears snapshot and metadata.
    func clearCapture()
}

public extension Camera {
    var isSwitching: Bool { isSwitchingDevices || isSwitchingModes }
}
