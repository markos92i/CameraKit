//
//  MovieCapture.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import AVFoundation

/// Errors that can occur during movie capture.
enum MovieCaptureError: Error, LocalizedError {
    /// The movie output has no active video connection (output not added to session).
    case noVideoConnection
    /// Recording is already in progress.
    case alreadyRecording
    
    var errorDescription: String? {
        switch self {
        case .noVideoConnection: "No se ha podido iniciar la grabación. La cámara no está lista."
        case .alreadyRecording: "Ya hay una grabación en curso."
        }
    }
}

/// An object that manages a movie capture output to record videos.
final class MovieCapture: OutputService, @unchecked Sendable {
    
    /// A closure called when capture activity changes.
    var onActivityChange: ((CaptureActivity) -> Void)?
    
    /// A value that indicates the current state of movie capture.
    private(set) var captureActivity: CaptureActivity = .idle {
        didSet { onActivityChange?(captureActivity) }
    }

    /// The capture output type for this service.
    let output = AVCaptureMovieFileOutput()
    // An internal alias for the output.
    private var movieOutput: AVCaptureMovieFileOutput { output }
    
    /// Returns the capabilities for this capture service.
    var capabilities: CaptureCapabilities {
        CaptureCapabilities(isHDRVideoSupported: isHDRSupported)
    }

    // A delegate object to respond to movie capture events.
    private var delegate: MovieCaptureDelegate?
    
    // The interval at which to update the recording time.
    private let refreshInterval = TimeInterval(0.25)
    private var timerTask: Task<Void, Never>?
    
    // A Boolean value that indicates whether the currently selected camera's
    // active format supports HDR.
    private var isHDRSupported = false
    
    // MARK: - Capturing a movie
    
    /// Starts movie recording.
    /// - Throws: `MovieCaptureError` if the output isn't ready to record.
    func startRecording() throws {
        guard !movieOutput.isRecording else {
            throw MovieCaptureError.alreadyRecording
        }
        
        guard let connection = movieOutput.connection(with: .video) else {
            throw MovieCaptureError.noVideoConnection
        }

        // Configure connection for HEVC capture.
        if movieOutput.availableVideoCodecTypes.contains(.hevc) {
            movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
        }

        // Enable video stabilization if the connection supports it.
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        // Start a timer to update the recording time.
        startMonitoringDuration()
        
        delegate = MovieCaptureDelegate()
        movieOutput.startRecording(to: URL.movieFileURL, recordingDelegate: delegate!)
    }
    
    /// Stops movie recording.
    /// - Returns: A `Movie` object that represents the captured movie.
    func stopRecording() async throws -> Movie {
        // Use a continuation to adapt the delegate-based capture API to an async interface.
        return try await withCheckedThrowingContinuation { continuation in
            // Set the continuation on the delegate to handle the capture result.
            delegate?.continuation = continuation
            
            /// Stops recording, which causes the output to call the `MovieCaptureDelegate` object.
            movieOutput.stopRecording()
            stopMonitoringDuration()
        }
    }
    
    // MARK: - Movie capture delegate
    /// A delegate object that responds to the capture output finalizing movie recording.
    private class MovieCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
        var continuation: CheckedContinuation<Movie, Error>?
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error {
                // If an error occurs, throw it to the caller.
                continuation?.resume(throwing: error)
            } else {
                // Return a new movie object.
                continuation?.resume(returning: Movie(url: outputFileURL))
            }
        }
    }
    
    // MARK: - Monitoring recorded duration
    
    // Starts a task to update the recording time.
    private func startMonitoringDuration() {
        captureActivity = .movieCapture()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.refreshInterval ?? 0.25))
                guard let self, !Task.isCancelled else { return }
                let duration = movieOutput.recordedDuration.seconds
                captureActivity = .movieCapture(duration: duration)
            }
        }
    }
    
    /// Stops the timer and resets the time.
    private func stopMonitoringDuration() {
        timerTask?.cancel()
        timerTask = nil
        captureActivity = .idle
    }
    
    // MARK: - Configuration
    func updateConfiguration(for device: AVCaptureDevice) {
        // The app supports HDR video capture if the active format supports it.
        isHDRSupported = device.activeFormat10BitVariant != nil
    }
}
