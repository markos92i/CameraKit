//
//  PreviewCapture.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import UIKit
import AVFoundation
import CoreImage

/// An object that manages a movie capture output to record videos.
final class PreviewCapture: OutputService {
    
    let captureActivity: CaptureActivity = .idle
    
    /// The capture output type for this service.
    let output = AVCaptureVideoDataOutput()
    // An internal alias for the output.
    private var previewOutput: AVCaptureVideoDataOutput { output }
    
    // A delegate object to respond to movie capture events.
    private var delegate: PreviewCaptureDelegate?
        
    // Preview stream control
    private var sendPreviewStream: ((sending CIImage) -> Void)?
    private var stopPreviewStream: (() -> Void)?
    
    // Preview stream
    var previewStream: AsyncStream<CIImage> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            sendPreviewStream = { image in continuation.yield(image) }
            stopPreviewStream = { continuation.finish() }
        }
    }

    // A Boolean value that indicates whether the currently selected camera's
    // active format supports HDR.
    private var isHDRSupported = false
    
    var connection: AVCaptureConnection? { previewOutput.connection(with: .video) }

    // MARK: - Preview a camera
    
    /// Starts movie recording.
    func startPreviewing(previewLayers: [AVSampleBufferDisplayLayer], queue: DispatchQueue) {
        delegate = PreviewCaptureDelegate(sendPreviewStream: sendPreviewStream, previewLayers: previewLayers)
        
        previewOutput.setSampleBufferDelegate(delegate, queue: queue)
        previewOutput.alwaysDiscardsLateVideoFrames = true
    }
    
    /// Stops preview stream
    func stopPreviewing() {
        stopPreviewStream?()
    }
    
    // MARK: - Preview capture delegate
    /// A delegate object that responds to the capture output sampleBuffer.
    private class PreviewCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var sendPreviewStream: ((sending CIImage) -> Void)?
        var previewLayers: [AVSampleBufferDisplayLayer]
        
        init(sendPreviewStream: ((sending CIImage) -> Void)? = nil, previewLayers: [AVSampleBufferDisplayLayer]) {
            self.sendPreviewStream = sendPreviewStream
            self.previewLayers = previewLayers
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            previewLayers.forEach { $0.sampleBufferRenderer.enqueue(sampleBuffer) }

            guard let pixelBuffer = sampleBuffer.imageBuffer else { return }

            sendPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
    
    func setVideoRotationAngle(_ angle: CGFloat) {
        // Managed in capture service
    }
        
    func updateConfiguration(for device: AVCaptureDevice) {
        // The app supports HDR video capture if the active format supports it.
        isHDRSupported = device.activeFormat10BitVariant != nil
    }

    // MARK: - Configuration
    /// Returns the capabilities for this capture service.
    var capabilities: CaptureCapabilities {
        CaptureCapabilities(isHDRVideoSupported: isHDRSupported)
    }
}
