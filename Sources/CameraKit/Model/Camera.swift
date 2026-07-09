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
    
    // MARK: - Configuration
    
    /// The camera's live configuration. Mutate this to change capture mode, filters, HDR, etc.
    var config: CameraConfiguration { get set }
    
    // MARK: - Runtime state (read-only)
    
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
    
    /// Starts the camera capture pipeline.
    func start() async
    
    /// Stops the camera capture pipeline.
    func stop() async

    /// A Boolean value that indicates whether the app is currently switching anything.
    var isSwitching: Bool { get }
    
    /// Switches between video devices available on the host system.
    func switchVideoDevices() async
    
    /// An enum value that indicates the direction of the user's swipe gesture
    var swipeDirection: SwipeDirection { get set }

    /// The current zoom factor applied to the camera.
    var zoomFactor: CGFloat { get }

    /// Sets the zoom factor, clamped to the device's supported range.
    func setZoom(_ factor: CGFloat) async
        
    /// A Boolean value that indicates whether the camera is doing some process work.
    var isProcessing: Bool { get set }

    /// Performs a one-time automatic focus and exposure operation.
    func focusAndExpose(at point: CGPoint) async
    
    /// Captures a photo and writes it to the user's photo library.
    func capturePhoto() async -> Photo?
    
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    var shouldFlashScreen: Bool { get }
    
    /// Hardware capabilities of the current device and configuration.
    var capabilities: CaptureCapabilities { get }
    
    /// Starts or stops recording a movie, and writes it to the user's photo library when complete.
    func toggleRecording() async -> Movie?
        
    /// An error if the camera encountered a problem.
    var error: Error? { get }
    
    /// A thumbnail image for the most recent photo or video capture.
    var thumbnail: CGImage? { get }

    /// The current capture snapshot (photo or video), held until accepted or discarded.
    var captureSnapshot: CaptureSnapshot? { get set }
    
    /// Resets capture state: cancels pending detection, clears snapshot and metadata.
    func clearCapture()
}

