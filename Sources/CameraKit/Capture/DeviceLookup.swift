//
//  DeviceLookup.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import AVFoundation

/// An object that retrieves camera and microphone devices and monitors hot-plug events.
final class DeviceLookup {

    // Discovery sessions to find the front and back cameras, and external cameras.
    private let frontCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let backCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let externalCameraDiscoverySession: AVCaptureDevice.DiscoverySession

    /// An async stream that emits device IDs whenever an external camera is connected or disconnected.
    let devicesChanged: AsyncStream<[String]>
    private let devicesChangedContinuation: AsyncStream<[String]>.Continuation

    private var observation: NSKeyValueObservation?

    init() {
        backCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        frontCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )
        externalCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external],
            mediaType: .video,
            position: .unspecified
        )

        let (stream, continuation) = AsyncStream.makeStream(of: [String].self)
        devicesChanged = stream
        devicesChangedContinuation = continuation

        // Observe external camera connection/disconnection via KVO on the discovery session.
        observation = externalCameraDiscoverySession.observe(\.devices, options: .new) { _, change in
            let ids = (change.newValue ?? []).map(\.uniqueID)
            continuation.yield(ids)
        }

        // If the host doesn't currently define a system-preferred camera, default to the back camera.
        if AVCaptureDevice.systemPreferredCamera == nil {
            AVCaptureDevice.userPreferredCamera = backCameraDiscoverySession.devices.first
        }
    }

    deinit {
        devicesChangedContinuation.finish()
    }

    /// Returns the system-preferred camera for the host system.
    var defaultCamera: AVCaptureDevice {
        get throws {
            guard let videoDevice = AVCaptureDevice.systemPreferredCamera else {
                throw CameraError.videoDeviceUnavailable
            }
            return videoDevice
        }
    }

    /// Returns the default microphone for the device on which the app runs.
    var defaultMic: AVCaptureDevice {
        get throws {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                throw CameraError.audioDeviceUnavailable
            }
            return audioDevice
        }
    }

    /// All currently available cameras (back, front, external).
    var cameras: [AVCaptureDevice] {
        var cameras: [AVCaptureDevice] = []
        if let backCamera = backCameraDiscoverySession.devices.first {
            cameras.append(backCamera)
        }
        if let frontCamera = frontCameraDiscoverySession.devices.first {
            cameras.append(frontCamera)
        }
        cameras.append(contentsOf: externalCameraDiscoverySession.devices)

        #if !targetEnvironment(simulator)
        if cameras.isEmpty {
            fatalError("No camera devices are found on this system.")
        }
        #endif
        return cameras
    }
}
