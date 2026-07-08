//
//  SystemPreferredCameraObserver.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import AVFoundation

/// An object that provides an asynchronous stream of device IDs representing the system-preferred camera.
///
/// Emits the `uniqueID` of the preferred device (a `String`, which is `Sendable`) to avoid
/// passing non-Sendable `AVCaptureDevice` across isolation boundaries.
final class SystemPreferredCameraObserver: NSObject {

    private let systemPreferredKeyPath = "systemPreferredCamera"

    let changes: AsyncStream<String>
    private let continuation: AsyncStream<String>.Continuation

    override init() {
        let (changes, continuation) = AsyncStream.makeStream(of: String.self)
        self.changes = changes
        self.continuation = continuation

        super.init()

        AVCaptureDevice.self.addObserver(self, forKeyPath: systemPreferredKeyPath, options: [.new], context: nil)
    }

    deinit {
        AVCaptureDevice.self.removeObserver(self, forKeyPath: systemPreferredKeyPath)
        continuation.finish()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case systemPreferredKeyPath:
            guard let device = change?[.newKey] as? AVCaptureDevice else { return }
            continuation.yield(device.uniqueID)
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
